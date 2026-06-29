import Foundation

struct ProjectItem: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var path: String
    var kind: ProjectKind
    var commands: [ProjectCommand]
    var preferredPort: String?
    var groupName: String?

    init(id: UUID = UUID(), name: String, path: String, kind: ProjectKind, commands: [ProjectCommand], preferredPort: String? = nil, groupName: String? = nil) {
        self.id = id
        self.name = name
        self.path = path
        self.kind = kind
        self.commands = commands
        self.preferredPort = preferredPort
        self.groupName = groupName
    }
}

enum ProjectKind: String, Codable {
    case node = "Node"
    case vue = "Vue"
    case flutter = "Flutter"
    case dotnet = ".NET"
    case generic = "Generic"
}

struct ProjectCommand: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var command: String
    var source: String

    init(id: UUID = UUID(), name: String, command: String, source: String) {
        self.id = id
        self.name = name
        self.command = command
        self.source = source
    }

    var isManual: Bool {
        source == "manual"
    }

    var placeholders: [String] {
        let pattern = #"\{\{\s*([A-Za-z0-9_-]+)\s*\}\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let range = NSRange(command.startIndex..<command.endIndex, in: command)
        var values: [String] = []
        for match in regex.matches(in: command, range: range) {
            guard match.numberOfRanges > 1,
                  let placeholderRange = Range(match.range(at: 1), in: command) else {
                continue
            }

            let value = String(command[placeholderRange])
            if !values.contains(value) {
                values.append(value)
            }
        }
        return values
    }

    func resolvedCommand(values: [String: String]) -> String {
        let pattern = #"\{\{\s*([A-Za-z0-9_-]+)\s*\}\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return command
        }

        var resolved = command
        let matches = regex.matches(in: command, range: NSRange(command.startIndex..<command.endIndex, in: command)).reversed()
        for match in matches {
            guard match.numberOfRanges > 1,
                  let fullRange = Range(match.range(at: 0), in: resolved),
                  let nameRange = Range(match.range(at: 1), in: command) else {
                continue
            }

            let name = String(command[nameRange])
            resolved.replaceSubrange(fullRange, with: values[name, default: ""])
        }

        return resolved
    }
}

enum ProjectLibraryError: LocalizedError {
    case unsupportedFolder

    var errorDescription: String? {
        switch self {
        case .unsupportedFolder:
            return "No supported project files found. Add a folder with package.json, pubspec.yaml, .sln, .csproj, or .fsproj."
        }
    }
}

enum ProjectLibrary {
    static func detectProject(at folderURL: URL) throws -> ProjectItem {
        let packageURL = folderURL.appending(path: "package.json")
        if FileManager.default.fileExists(atPath: packageURL.path) {
            return try detectNodeProject(folderURL: folderURL, packageURL: packageURL)
        }

        let pubspecURL = folderURL.appending(path: "pubspec.yaml")
        if FileManager.default.fileExists(atPath: pubspecURL.path) {
            return detectFlutterProject(folderURL: folderURL, pubspecURL: pubspecURL)
        }

        if let dotnetURL = findDotnetEntry(in: folderURL) {
            return detectDotnetProject(folderURL: folderURL, entryURL: dotnetURL)
        }

        throw ProjectLibraryError.unsupportedFolder
    }

    private static func detectNodeProject(folderURL: URL, packageURL: URL) throws -> ProjectItem {
        let data = try Data(contentsOf: packageURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let packageName = json?["name"] as? String
        let scripts = json?["scripts"] as? [String: String] ?? [:]
        let dependencies = json?["dependencies"] as? [String: Any] ?? [:]
        let devDependencies = json?["devDependencies"] as? [String: Any] ?? [:]
        let isVue = dependencies.keys.contains("vue") || devDependencies.keys.contains("vue") || devDependencies.keys.contains("@vitejs/plugin-vue")
        let sortedScripts = scripts.keys.sorted()

        var commands = sortedScripts.map { scriptName in
            ProjectCommand(name: scriptName, command: "npm run \(scriptName)", source: "package.json")
        }

        if !scripts.keys.contains("install") {
            commands.insert(ProjectCommand(name: "install", command: "npm install", source: "npm"), at: 0)
        }

        return ProjectItem(
            name: packageName?.isEmpty == false ? packageName! : folderURL.lastPathComponent,
            path: folderURL.path,
            kind: isVue ? .vue : .node,
            commands: commands,
            preferredPort: isVue ? detectedVuePort(scripts: scripts) : "3000"
        )
    }

    private static func detectFlutterProject(folderURL: URL, pubspecURL: URL) -> ProjectItem {
        let pubspecName = readPubspecName(pubspecURL: pubspecURL)
        let commands = [
            ProjectCommand(name: "pub get", command: "flutter pub get", source: "flutter"),
            ProjectCommand(name: "run", command: "flutter run", source: "flutter"),
            ProjectCommand(name: "test", command: "flutter test", source: "flutter"),
            ProjectCommand(name: "build macOS", command: "flutter build macos", source: "flutter"),
            ProjectCommand(name: "clean", command: "flutter clean", source: "flutter")
        ]

        return ProjectItem(
            name: pubspecName ?? folderURL.lastPathComponent,
            path: folderURL.path,
            kind: .flutter,
            commands: commands,
            preferredPort: "5173"
        )
    }

    private static func readPubspecName(pubspecURL: URL) -> String? {
        guard let contents = try? String(contentsOf: pubspecURL) else {
            return nil
        }

        return contents
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { $0.hasPrefix("name:") }
            .map { String($0.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines) }
            .flatMap { $0.isEmpty ? nil : $0 }
    }

    private static func findDotnetEntry(in folderURL: URL) -> URL? {
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []

        return contents.first { $0.pathExtension == "sln" }
            ?? contents.first { $0.pathExtension == "csproj" }
            ?? contents.first { $0.pathExtension == "fsproj" }
    }

    private static func detectDotnetProject(folderURL: URL, entryURL: URL) -> ProjectItem {
        let entryName = entryURL.deletingPathExtension().lastPathComponent
        let entryArgument = entryURL.lastPathComponent
        let commands = [
            ProjectCommand(name: "restore", command: "dotnet restore \(entryArgument)", source: entryURL.lastPathComponent),
            ProjectCommand(name: "build", command: "dotnet build \(entryArgument)", source: entryURL.lastPathComponent),
            ProjectCommand(name: "run", command: dotnetRunCommand(entryURL: entryURL), source: entryURL.lastPathComponent),
            ProjectCommand(name: "watch", command: dotnetWatchCommand(entryURL: entryURL), source: entryURL.lastPathComponent),
            ProjectCommand(name: "test", command: "dotnet test \(entryArgument)", source: entryURL.lastPathComponent)
        ]

        return ProjectItem(
            name: entryName,
            path: folderURL.path,
            kind: .dotnet,
            commands: commands,
            preferredPort: "5000"
        )
    }

    private static func detectedVuePort(scripts: [String: String]) -> String {
        let joined = scripts.values.joined(separator: " ")
        if joined.contains("vue-cli-service") {
            return "8080"
        }
        return "5173"
    }

    private static func dotnetRunCommand(entryURL: URL) -> String {
        if entryURL.pathExtension == "sln" {
            return "dotnet run"
        }

        return "dotnet run --project \(entryURL.lastPathComponent)"
    }

    private static func dotnetWatchCommand(entryURL: URL) -> String {
        if entryURL.pathExtension == "sln" {
            return "dotnet watch run"
        }

        return "dotnet watch --project \(entryURL.lastPathComponent)"
    }
}
