import Foundation

struct PortProcess: Identifiable, Equatable {
    var id: Int32 { pid }

    let command: String
    let pid: Int32
    let user: String
    let name: String
    let parentPID: Int32?
    let processGroupID: Int32?
    let state: String
    let tty: String
    let executable: String
    let arguments: String
    let workingDirectory: String
    let port: Int?

    var attachedToTerminal: Bool {
        !tty.isEmpty && tty != "??"
    }
}

struct LaunchedProcess {
    let pid: Int32
    let process: Process
    let stdout: Pipe
    let stderr: Pipe
}

enum CommandOutputKind: String {
    case standardOutput
    case standardError
}

enum ProcessServiceError: LocalizedError {
    case invalidWorkingDirectory
    case commandFailed(String)
    case invalidPID

    var errorDescription: String? {
        switch self {
        case .invalidWorkingDirectory:
            return "Working directory does not exist."
        case .commandFailed(let message):
            return message
        case .invalidPID:
            return "Invalid process id."
        }
    }
}

enum ProcessService {
    static func findProcesses(onPort port: Int) async throws -> [PortProcess] {
        do {
            let output = try await run("/usr/sbin/lsof", arguments: ["-nP", "-iTCP:\(port)", "-sTCP:LISTEN"])
            let rows = output
                .split(separator: "\n")
                .dropFirst()
                .map(String.init)

            var processes: [PortProcess] = []
            for row in rows {
                guard let item = parseLsofRow(row) else { continue }
                processes.append(try await enrich(item))
            }
            return processes
        } catch ProcessServiceError.commandFailed {
            return []
        }
    }

    static func findListeningProcesses() async throws -> [PortProcess] {
        do {
            let output = try await run("/usr/sbin/lsof", arguments: ["-nP", "-iTCP", "-sTCP:LISTEN"])
            let rows = output
                .split(separator: "\n")
                .dropFirst()
                .map(String.init)

            var processes: [PortProcess] = []
            var seenPIDs = Set<Int32>()
            for row in rows {
                guard let item = parseLsofRow(row), !seenPIDs.contains(item.pid) else { continue }
                seenPIDs.insert(item.pid)
                processes.append(try await enrich(item))
            }
            return processes.sorted { ($0.port ?? 0) < ($1.port ?? 0) }
        } catch ProcessServiceError.commandFailed {
            return []
        }
    }

    static func nextAvailablePort(startingAt port: Int) async -> Int {
        var candidate = max(1, port)
        while candidate <= 65535 {
            if let processes = try? await findProcesses(onPort: candidate), processes.isEmpty {
                return candidate
            }
            candidate += 1
        }

        return port
    }

    static func stop(pid: Int32) async throws -> String {
        guard pid > 0 else {
            throw ProcessServiceError.invalidPID
        }

        Darwin.kill(pid, SIGTERM)
        try? await Task.sleep(for: .milliseconds(700))

        if Darwin.kill(pid, 0) == 0 {
            Darwin.kill(pid, SIGKILL)
            for _ in 0..<10 {
                try? await Task.sleep(for: .milliseconds(100))
                if Darwin.kill(pid, 0) != 0 {
                    break
                }
            }
            return "SIGKILL"
        }

        return "SIGTERM"
    }

    static func start(command: String, workingDirectory: String) throws -> Int32 {
        let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
        let cwd = try normalizedWorkingDirectory(workingDirectory)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", trimmedCommand]
        process.currentDirectoryURL = URL(fileURLWithPath: cwd, isDirectory: true)
        process.standardInput = nil
        process.standardOutput = nil
        process.standardError = nil

        try process.run()
        return process.processIdentifier
    }

    static func launch(
        command: String,
        workingDirectory: String,
        onOutput: (@Sendable (String, CommandOutputKind) -> Void)? = nil,
        onExit: (@Sendable (Int32) -> Void)? = nil
    ) throws -> LaunchedProcess {
        let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
        let cwd = try normalizedWorkingDirectory(workingDirectory)

        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", trimmedCommand]
        process.currentDirectoryURL = URL(fileURLWithPath: cwd, isDirectory: true)
        process.standardInput = nil
        process.standardOutput = stdout
        process.standardError = stderr

        stdout.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8), !text.isEmpty else { return }
            onOutput?(text, .standardOutput)
        }

        stderr.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8), !text.isEmpty else { return }
            onOutput?(text, .standardError)
        }

        process.terminationHandler = { process in
            stdout.fileHandleForReading.readabilityHandler = nil
            stderr.fileHandleForReading.readabilityHandler = nil
            onExit?(process.terminationStatus)
        }

        try process.run()
        return LaunchedProcess(pid: process.processIdentifier, process: process, stdout: stdout, stderr: stderr)
    }

    private static func parseLsofRow(_ row: String) -> LsofProcess? {
        let parts = row.split(whereSeparator: \.isWhitespace).map(String.init)
        guard parts.count >= 9, let pid = Int32(parts[1]) else {
            return nil
        }

        return LsofProcess(
            command: parts[0],
            pid: pid,
            user: parts[2],
            name: parts.dropFirst(8).joined(separator: " ")
        )
    }

    private static func enrich(_ item: LsofProcess) async throws -> PortProcess {
        let psOutput = (try? await Self.run("/bin/ps", arguments: ["-o", "pid=,ppid=,pgid=,stat=,tty=,comm=,args=", "-p", String(item.pid)])) ?? ""
        let cwdOutput = (try? await Self.run("/usr/sbin/lsof", arguments: ["-a", "-p", String(item.pid), "-d", "cwd", "-Fn"])) ?? ""
        let details = parsePsOutput(psOutput)
        let cwd = parseCwdOutput(cwdOutput)

        return PortProcess(
            command: item.command,
            pid: item.pid,
            user: item.user,
            name: item.name,
            parentPID: details.parentPID,
            processGroupID: details.processGroupID,
            state: details.state,
            tty: details.tty,
            executable: details.executable,
            arguments: details.arguments,
            workingDirectory: cwd,
            port: parsePort(from: item.name)
        )
    }

    private static func parsePort(from name: String) -> Int? {
        let endpoint = name.split(separator: " ").first.map(String.init) ?? name
        guard let rawPort = endpoint.split(separator: ":").last else {
            return nil
        }
        return Int(rawPort)
    }

    private static func parsePsOutput(_ output: String) -> PsDetails {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return PsDetails()
        }

        let parts = trimmed.split(maxSplits: 6, whereSeparator: \.isWhitespace).map(String.init)
        guard parts.count >= 6 else {
            return PsDetails()
        }

        return PsDetails(
            parentPID: Int32(parts[1]),
            processGroupID: Int32(parts[2]),
            state: parts[3],
            tty: parts[4],
            executable: parts[5],
            arguments: parts.count > 6 ? parts[6] : ""
        )
    }

    private static func parseCwdOutput(_ output: String) -> String {
        output
            .split(separator: "\n")
            .map(String.init)
            .first { $0.hasPrefix("n") }
            .map { String($0.dropFirst()) } ?? ""
    }

    private static func normalizedWorkingDirectory(_ workingDirectory: String) throws -> String {
        let trimmed = workingDirectory.trimmingCharacters(in: .whitespacesAndNewlines)
        let path = trimmed.isEmpty ? FileManager.default.homeDirectoryForCurrentUser.path : NSString(string: trimmed).expandingTildeInPath
        var isDirectory = ObjCBool(false)

        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw ProcessServiceError.invalidWorkingDirectory
        }

        return path
    }

    private static func run(_ executable: String, arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdout = Pipe()
            let stderr = Pipe()

            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.standardOutput = stdout
            process.standardError = stderr

            process.terminationHandler = { process in
                let output = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let error = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(throwing: ProcessServiceError.commandFailed(error.isEmpty ? output : error))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

private struct LsofProcess {
    let command: String
    let pid: Int32
    let user: String
    let name: String
}

private struct PsDetails {
    var parentPID: Int32?
    var processGroupID: Int32?
    var state = ""
    var tty = ""
    var executable = ""
    var arguments = ""
}
