import AppKit
import Foundation

@MainActor
final class ProcessMonitor: ObservableObject {
    @Published var port: String = "3000" {
        didSet {
            loadSavedFields()
        }
    }
    @Published var command: String = ""
    @Published var workingDirectory: String = ""
    @Published var processes: [PortProcess] = []
    @Published var runningProcesses: [PortProcess] = []
    @Published var selectedProcessID: Int32?
    @Published var status: StatusMessage = .ready
    @Published var isBusy = false
    @Published var projects: [ProjectItem] = []
    @Published var selectedProjectID: UUID?
    @Published var selectedCommandID: UUID?
    @Published var activeTemplateCommandID: UUID?
    @Published var templateValues: [String: String] = [:]
    @Published var manualCommandName: String = ""
    @Published var manualCommandTemplate: String = ""
    @Published var stopConfirmPending = false
    @Published var newGroupName: String = ""
    @Published var projectGroups: [String] = []
    @Published var collapsedGroups: Set<String> = []
    @Published var sidebarWidth: CGFloat = 360
    @Published var commandLogs: [CommandLogEntry] = []
    @Published var activeLaunchPIDs: Set<Int32> = []

    private let defaults = UserDefaults.standard
    private let projectsKey = "projects.library"
    private let projectGroupsKey = "projects.groups"
    private var stopConfirmTask: Task<Void, Never>?
    private var lastCommandByProjectID: [UUID: UUID] = [:]
    private var launchedProcesses: [Int32: LaunchedProcess] = [:]

    init() {
        loadProjects()
        loadProjectGroups()
        loadSavedFields()
    }

    var selectedProcess: PortProcess? {
        processes.first { $0.pid == selectedProcessID }
    }

    var selectedProject: ProjectItem? {
        projects.first { $0.id == selectedProjectID }
    }

    var selectedCommand: ProjectCommand? {
        selectedProject?.commands.first { $0.id == selectedCommandID }
    }

    var activeTemplateCommand: ProjectCommand? {
        selectedProject?.commands.first { $0.id == activeTemplateCommandID }
    }

    var isSelectedPortRunning: Bool {
        !processes.isEmpty
    }

    var groupNames: [String] {
        let names = projectGroups + projects.compactMap { normalizedGroupName($0.groupName) }
        return Array(Set(names)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var groupedProjects: [(name: String, projects: [ProjectItem])] {
        let grouped = Dictionary(grouping: projects) { project in
            normalizedGroupName(project.groupName) ?? "Ungrouped"
        }
        let allGroupNames = Set(groupNames + grouped.keys)
        return allGroupNames
            .map { groupName in
                (
                    name: groupName,
                    projects: (grouped[groupName] ?? []).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                )
            }
            .sorted { lhs, rhs in
                if lhs.name == "Ungrouped" { return false }
                if rhs.name == "Ungrouped" { return true }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    var parsedPort: Int? {
        guard let value = Int(port), (1...65535).contains(value) else {
            return nil
        }

        return value
    }

    func scan() async {
        guard let port = parsedPort else {
            status = .error("Enter a port between 1 and 65535.")
            return
        }

        isBusy = true
        status = .working("Scanning port \(port)...")

        do {
            let found = try await ProcessService.findProcesses(onPort: port)
            processes = found
            selectedProcessID = found.first?.pid
            if workingDirectory.isEmpty, let cwd = found.first?.workingDirectory, !cwd.isEmpty {
                workingDirectory = cwd
            }
            if found.isEmpty {
                status = .ready("Port \(port) is free.")
            } else if portProcessMatchesSelectedProject(found) {
                status = .ok("\(listeningCommandName(from: found) ?? selectedCommand?.name ?? "Command") is listening.")
            } else {
                let suggestion = await ProcessService.nextAvailablePort(startingAt: port + 1)
                status = .error("Port \(port) is busy. Try \(suggestion).")
            }
        } catch {
            status = .error(error.localizedDescription)
        }

        await scanRunningProcesses()
        isBusy = false
    }

    func scanRunningProcesses() async {
        do {
            let allProcesses = try await ProcessService.findListeningProcesses()
            runningProcesses = allProcesses.filter { process in
                projects.contains { project in
                    process.workingDirectory == project.path || process.workingDirectory.hasPrefix(project.path + "/")
                }
            }
        } catch {
            runningProcesses = []
        }
    }

    func select(_ process: PortProcess) {
        selectedProcessID = process.pid
        if workingDirectory.isEmpty, !process.workingDirectory.isEmpty {
            workingDirectory = process.workingDirectory
        }
    }

    func selectRunningProcess(_ process: PortProcess) {
        if let port = process.port {
            self.port = String(port)
        }
        processes = [process]
        selectedProcessID = process.pid
        if !process.workingDirectory.isEmpty {
            workingDirectory = process.workingDirectory
        }
    }

    func addProjectFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        panel.prompt = "Add Project"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let project = try ProjectLibrary.detectProject(at: url)
            if let existingIndex = projects.firstIndex(where: { $0.path == project.path }) {
                let existingID = projects[existingIndex].id
                let manualCommands = projects[existingIndex].commands.filter(\.isManual)
                projects[existingIndex] = ProjectItem(
                    id: existingID,
                    name: project.name,
                    path: project.path,
                    kind: project.kind,
                    commands: project.commands + manualCommands,
                    preferredPort: projects[existingIndex].preferredPort ?? project.preferredPort,
                    groupName: projects[existingIndex].groupName
                )
                selectedProjectID = existingID
            } else {
                projects.append(project)
                selectedProjectID = project.id
            }
            projects.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            if let selectedProject {
                applyProject(selectedProject)
            }
            saveProjects()
            status = .ok("Added \(project.name).")
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    func removeSelectedProject() {
        guard let selectedProjectID else { return }
        removeProject(id: selectedProjectID)
    }

    func removeProject(id: UUID) {
        projects.removeAll { $0.id == id }
        lastCommandByProjectID[id] = nil
        if selectedProjectID == id {
            selectedProjectID = projects.first?.id
            selectedCommandID = nil
            activeTemplateCommandID = nil
            templateValues = [:]
        }
        if let project = selectedProject {
            applyProject(project)
        }
        saveProjects()
    }

    func refreshSelectedProject() {
        guard let selectedProject else { return }

        do {
            let refreshed = try ProjectLibrary.detectProject(at: URL(fileURLWithPath: selectedProject.path, isDirectory: true))
            if let index = projects.firstIndex(where: { $0.id == selectedProject.id }) {
                let manualCommands = projects[index].commands.filter(\.isManual)
                projects[index] = ProjectItem(
                    id: selectedProject.id,
                    name: refreshed.name,
                    path: refreshed.path,
                    kind: refreshed.kind,
                    commands: refreshed.commands + manualCommands,
                    preferredPort: projects[index].preferredPort ?? refreshed.preferredPort,
                    groupName: projects[index].groupName
                )
            }
            saveProjects()
            status = .ok("Refreshed \(refreshed.name).")
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    func selectProject(id: UUID) {
        if let selectedProjectID, let selectedCommandID {
            lastCommandByProjectID[selectedProjectID] = selectedCommandID
        }
        selectedProjectID = id
        activeTemplateCommandID = nil
        templateValues = [:]
        guard let selectedProject else { return }
        applyProject(selectedProject)
    }

    func useCommand(_ projectCommand: ProjectCommand) {
        selectedCommandID = projectCommand.id
        if let selectedProjectID {
            lastCommandByProjectID[selectedProjectID] = projectCommand.id
        }
        if projectCommand.placeholders.isEmpty {
            activeTemplateCommandID = nil
            templateValues = [:]
            command = projectCommand.command
        } else {
            activeTemplateCommandID = projectCommand.id
            templateValues = Dictionary(uniqueKeysWithValues: projectCommand.placeholders.map { ($0, templateValues[$0, default: ""]) })
            command = projectCommand.resolvedCommand(values: templateValues)
        }
        if let selectedProject {
            workingDirectory = selectedProject.path
        }
        saveFields()
    }

    func setTemplateValue(_ value: String, for placeholder: String) {
        templateValues[placeholder] = value
        guard let activeTemplateCommand else { return }
        command = activeTemplateCommand.resolvedCommand(values: templateValues)
        saveFields()
    }

    func addManualCommand() {
        guard let selectedProjectID,
              let index = projects.firstIndex(where: { $0.id == selectedProjectID }) else {
            status = .error("Select a project first.")
            return
        }

        let name = manualCommandName.trimmingCharacters(in: .whitespacesAndNewlines)
        let template = manualCommandTemplate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !template.isEmpty else {
            status = .error("Add a command name and template.")
            return
        }

        let projectCommand = ProjectCommand(name: name, command: template, source: "manual")
        projects[index].commands.append(projectCommand)
        manualCommandName = ""
        manualCommandTemplate = ""
        saveProjects()
        useCommand(projectCommand)
        status = .ok("Added \(name).")
    }

    func removeManualCommand(_ projectCommand: ProjectCommand) {
        guard projectCommand.isManual,
              let selectedProjectID,
              let index = projects.firstIndex(where: { $0.id == selectedProjectID }) else {
            return
        }

        projects[index].commands.removeAll { $0.id == projectCommand.id }
        if selectedCommandID == projectCommand.id {
            selectedCommandID = projects[index].commands.first?.id
            lastCommandByProjectID[selectedProjectID] = selectedCommandID
        }
        if activeTemplateCommandID == projectCommand.id {
            activeTemplateCommandID = nil
            templateValues = [:]
        }
        saveProjects()
    }

    func start() async {
        guard !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            status = .error("Add a start command first.")
            return
        }

        saveFields()
        isBusy = true
        status = .working("Starting command...")

        do {
            let pid = try launchCurrentCommand(workingDirectory: workingDirectory, action: "start")
            status = .ok("Started PID \(pid).")
            try? await Task.sleep(for: .milliseconds(900))
            await scan()
        } catch {
            appendLog(error.localizedDescription, kind: .error)
            status = .error(error.localizedDescription)
            isBusy = false
        }
    }

    func stop() async {
        if !stopConfirmPending {
            requestStopConfirmation()
            return
        }

        stopConfirmTask?.cancel()
        stopConfirmTask = nil
        stopConfirmPending = false

        guard let selectedProcess else { return }

        isBusy = true
        status = .working("Stopping PID \(selectedProcess.pid)...")

        do {
            let signal = try await ProcessService.stop(pid: selectedProcess.pid)
            launchedProcesses[selectedProcess.pid] = nil
            activeLaunchPIDs.remove(selectedProcess.pid)
            status = .ok("Stopped PID \(selectedProcess.pid) with \(signal).")
            try? await Task.sleep(for: .milliseconds(650))
            await scan()
            await scanRunningProcesses()
        } catch {
            status = .error(error.localizedDescription)
            isBusy = false
        }
    }

    func stopRunningProcess(_ process: PortProcess) async {
        isBusy = true
        status = .working("Stopping PID \(process.pid)...")

        do {
            let signal = try await ProcessService.stop(pid: process.pid)
            launchedProcesses[process.pid] = nil
            activeLaunchPIDs.remove(process.pid)
            status = .ok("Stopped PID \(process.pid) with \(signal).")
            try? await Task.sleep(for: .milliseconds(650))
            await scan()
            await scanRunningProcesses()
        } catch {
            status = .error(error.localizedDescription)
            isBusy = false
        }
    }

    func restart() async {
        guard let selectedProcess else { return }
        guard !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            status = .error("Add a start command first.")
            return
        }

        saveFields()
        isBusy = true
        status = .working("Restarting PID \(selectedProcess.pid)...")

        do {
            _ = try await ProcessService.stop(pid: selectedProcess.pid)
            launchedProcesses[selectedProcess.pid] = nil
            activeLaunchPIDs.remove(selectedProcess.pid)
            try? await Task.sleep(for: .milliseconds(500))
            let pid = try launchCurrentCommand(
                workingDirectory: workingDirectory.isEmpty ? selectedProcess.workingDirectory : workingDirectory,
                action: "restart"
            )
            status = .ok("Restarted as PID \(pid).")
            try? await Task.sleep(for: .milliseconds(1_100))
            await scan()
            await scanRunningProcesses()
        } catch {
            appendLog(error.localizedDescription, kind: .error)
            status = .error(error.localizedDescription)
            isBusy = false
        }
    }

    func clearLogs() {
        commandLogs.removeAll()
    }

    func openLocalhost() {
        guard let port = parsedPort, let url = URL(string: "http://localhost:\(port)") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    func setPort(_ value: String) {
        port = value
        guard let selectedProjectID,
              let index = projects.firstIndex(where: { $0.id == selectedProjectID }) else {
            return
        }
        projects[index].preferredPort = value
        saveProjects()
    }

    func setGroup(_ groupName: String?, for projectID: UUID) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else { return }
        let normalized = normalizedGroupName(groupName)
        if let normalized, !projectGroups.contains(normalized) {
            projectGroups.append(normalized)
            projectGroups.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            saveProjectGroups()
        }
        projects[index].groupName = normalized
        saveProjects()
    }

    func addGroupFromInput(for projectID: UUID? = nil) {
        let normalized = normalizedGroupName(newGroupName)
        guard let normalized else {
            status = .error("Add a group name first.")
            return
        }

        if !projectGroups.contains(normalized) {
            projectGroups.append(normalized)
            projectGroups.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            saveProjectGroups()
        }

        if let projectID {
            setGroup(normalized, for: projectID)
        }
        collapsedGroups.remove(normalized)
        newGroupName = ""
        status = .ok("Added group \(normalized).")
    }

    func createGroup() {
        addGroupFromInput()
    }

    func adjustSidebarWidth(by delta: CGFloat) {
        setSidebarWidth(sidebarWidth + delta)
    }

    func setSidebarWidth(_ width: CGFloat) {
        sidebarWidth = min(560, max(260, width))
    }

    func toggleGroup(_ groupName: String) {
        if collapsedGroups.contains(groupName) {
            collapsedGroups.remove(groupName)
        } else {
            collapsedGroups.insert(groupName)
        }
    }

    private func loadSavedFields() {
        guard let port = parsedPort else { return }
        command = defaults.string(forKey: "command.\(port)") ?? ""
        workingDirectory = defaults.string(forKey: "cwd.\(port)") ?? ""
    }

    private func saveFields() {
        guard let port = parsedPort else { return }
        defaults.set(command, forKey: "command.\(port)")
        defaults.set(workingDirectory, forKey: "cwd.\(port)")
    }

    private func applyProject(_ project: ProjectItem) {
        workingDirectory = project.path
        if let preferredPort = project.preferredPort, !preferredPort.isEmpty {
            port = preferredPort
        }
        if let lastCommandID = lastCommandByProjectID[project.id],
           let command = project.commands.first(where: { $0.id == lastCommandID }) {
            useCommand(command)
        } else if let firstCommand = project.commands.first {
            useCommand(firstCommand)
        }
    }

    private func normalizedGroupName(_ groupName: String?) -> String? {
        let trimmed = (groupName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func requestStopConfirmation() {
        guard selectedProcess != nil else { return }
        stopConfirmPending = true
        stopConfirmTask?.cancel()
        stopConfirmTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            await MainActor.run {
                self?.stopConfirmPending = false
                self?.stopConfirmTask = nil
            }
        }
    }

    private func launchCurrentCommand(workingDirectory launchDirectory: String, action: String) throws -> Int32 {
        let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDirectory = launchDirectory.trimmingCharacters(in: .whitespacesAndNewlines)
        appendLog("$ \(trimmedCommand)", kind: .command)
        appendLog("cwd: \(trimmedDirectory.isEmpty ? "~" : trimmedDirectory)", kind: .info)

        let launched = try ProcessService.launch(
            command: trimmedCommand,
            workingDirectory: launchDirectory,
            onOutput: { [weak self] text, outputKind in
                Task { @MainActor in
                    self?.appendLog(text, kind: outputKind == .standardError ? .error : .output)
                }
            }
        )

        let pid = launched.pid
        launched.process.terminationHandler = { [weak self] process in
            launched.stdout.fileHandleForReading.readabilityHandler = nil
            launched.stderr.fileHandleForReading.readabilityHandler = nil
            Task { @MainActor in
                self?.handleLaunchExit(pid: pid, exitCode: process.terminationStatus, action: action)
            }
        }
        launchedProcesses[pid] = launched
        activeLaunchPIDs.insert(pid)
        return pid
    }

    private func handleLaunchExit(pid: Int32, exitCode: Int32, action: String) {
        launchedProcesses[pid] = nil
        activeLaunchPIDs.remove(pid)

        if exitCode == 0 {
            appendLog("Process \(pid) exited normally.", kind: .exit)
        } else {
            appendLog("Process \(pid) exited with status \(exitCode).", kind: .error)
        }

        Task {
            await scan()
            await scanRunningProcesses()
            if exitCode != 0 {
                status = .error("Command \(action) failed with exit \(exitCode). See console.")
            }
        }
    }

    private func appendLog(_ text: String, kind: CommandLogEntry.Kind) {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        for line in normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            let entryText = line.trimmingCharacters(in: .newlines)
            guard !entryText.isEmpty else { continue }
            commandLogs.append(CommandLogEntry(kind: kind, text: entryText))
        }

        if commandLogs.count > 400 {
            commandLogs.removeFirst(commandLogs.count - 400)
        }
    }

    private func portProcessMatchesSelectedProject(_ found: [PortProcess]) -> Bool {
        guard !workingDirectory.isEmpty else {
            return false
        }

        return found.contains { process in
            process.workingDirectory == workingDirectory || process.workingDirectory.hasPrefix(workingDirectory + "/")
        }
    }

    private func listeningCommandName(from found: [PortProcess]) -> String? {
        guard let selectedProject else { return nil }
        let matchingProcess = found.first { process in
            process.workingDirectory == workingDirectory || process.workingDirectory.hasPrefix(workingDirectory + "/")
        } ?? found.first

        guard let args = matchingProcess?.arguments.lowercased(), !args.isEmpty else {
            return nil
        }

        let candidates = selectedProject.commands
            .filter { !$0.command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted { $0.command.count > $1.command.count }

        return candidates.first { command in
            processArguments(args, match: command)
        }?.name
    }

    private func processArguments(_ args: String, match command: ProjectCommand) -> Bool {
        let commandText = command.command.lowercased()
        if args.contains(commandText) || commandText.contains(args) {
            return true
        }

        if commandText.hasPrefix("npm run ") {
            let scriptName = commandText
                .replacingOccurrences(of: "npm run ", with: "")
                .split(separator: " ")
                .first
                .map(String.init) ?? ""
            return !scriptName.isEmpty && (args.contains("npm run \(scriptName)") || args.contains("run-script \(scriptName)"))
        }

        return false
    }

    private func loadProjects() {
        guard let data = defaults.data(forKey: projectsKey),
              let decoded = try? JSONDecoder().decode([ProjectItem].self, from: data) else {
            return
        }

        projects = decoded
        selectedProjectID = decoded.first?.id
    }

    private func loadProjectGroups() {
        projectGroups = defaults.stringArray(forKey: projectGroupsKey) ?? []
    }

    private func saveProjectGroups() {
        defaults.set(projectGroups, forKey: projectGroupsKey)
    }

    private func saveProjects() {
        guard let data = try? JSONEncoder().encode(projects) else {
            return
        }

        defaults.set(data, forKey: projectsKey)
    }
}

struct CommandLogEntry: Identifiable, Equatable {
    enum Kind {
        case command
        case info
        case output
        case error
        case exit
    }

    let id = UUID()
    let date = Date()
    let kind: Kind
    let text: String
}

struct StatusMessage {
    enum Tone {
        case ready
        case ok
        case working
        case error
    }

    var text: String
    var tone: Tone

    static let ready = StatusMessage(text: "Ready", tone: .ready)

    static func ready(_ text: String) -> StatusMessage {
        StatusMessage(text: text, tone: .ready)
    }

    static func ok(_ text: String) -> StatusMessage {
        StatusMessage(text: text, tone: .ok)
    }

    static func working(_ text: String) -> StatusMessage {
        StatusMessage(text: text, tone: .working)
    }

    static func error(_ text: String) -> StatusMessage {
        StatusMessage(text: text, tone: .error)
    }
}
