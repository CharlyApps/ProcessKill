import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var model: ProcessMonitor
    @State private var sidebarDragStartWidth: CGFloat?
    @State private var isCreatingGroup = false

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            HStack(spacing: 0) {
                sidebar
                sidebarResizeHandle
                Divider().overlay(PK.divider)
                mainColumns
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PK.bgDeep2)
        .task {
            await model.scan()
        }
    }

    private var titleBar: some View {
        HStack(spacing: 12) {
            Text("ProcessKill")
                .pkFont(size: 13, weight: .bold)
                .tracking(-0.2)
                .foregroundStyle(PK.textPrimary)

            Spacer()

            HStack(spacing: 7) {
                Text("⌕")
                    .pkFont(size: 13)
                    .foregroundStyle(PK.textMuted)
                Text("Search projects, commands...")
                    .pkFont(size: 11)
                    .foregroundStyle(PK.textMuted)
                Spacer()
            }
            .frame(maxWidth: 360)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(PK.bgSection, in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(PK.borderNormal.opacity(0.9)))

            Spacer()

        }
        .frame(height: 44)
        .padding(.horizontal, 16)
        .background(PK.bgDeepest)
        .overlay(Rectangle().fill(PK.divider).frame(height: 1), alignment: .bottom)
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    Text("Projects")
                        .pkSectionLabel()
                    Spacer()
                    Button("+ Group") {
                        isCreatingGroup.toggle()
                        if !isCreatingGroup {
                            model.newGroupName = ""
                        }
                    }
                    .buttonStyle(.plain)
                    .pkFont(size: 10, weight: .semibold)
                    .foregroundStyle(PK.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(red: 91 / 255, green: 60 / 255, blue: 196 / 255).opacity(0.10), in: RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(PK.borderNormal.opacity(0.9)))

                    Button("+ Add") {
                        model.addProjectFolder()
                    }
                    .buttonStyle(.plain)
                    .pkFont(size: 10, weight: .semibold)
                    .foregroundStyle(PK.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(red: 91 / 255, green: 60 / 255, blue: 196 / 255).opacity(0.10), in: RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(PK.borderNormal.opacity(0.9)))
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

                if isCreatingGroup {
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            TextField("Group name", text: $model.newGroupName)
                                .textFieldStyle(.plain)
                                .pkFont(size: 11)
                                .foregroundStyle(PK.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(PK.bgSection, in: RoundedRectangle(cornerRadius: 5))
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(PK.borderNormal.opacity(0.75)))
                                .onSubmit {
                                    model.createGroup()
                                    isCreatingGroup = false
                                }

                            Button("Create") {
                                model.createGroup()
                                isCreatingGroup = false
                            }
                            .buttonStyle(.plain)
                            .pkFont(size: 10, weight: .semibold)
                            .foregroundStyle(PK.teal)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(PK.teal.opacity(0.10), in: RoundedRectangle(cornerRadius: 5))
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(PK.teal.opacity(0.22)))
                        }
                        if let project = model.selectedProject {
                            Text("Will be assigned to \(project.name)")
                                .pkFont(size: 9)
                                .foregroundStyle(PK.textMuted)
                                .padding(.horizontal, 12)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(model.groupedProjects, id: \.name) { group in
                            VStack(spacing: 3) {
                                Button {
                                    model.toggleGroup(group.name)
                                } label: {
                                    HStack {
                                        Text(model.collapsedGroups.contains(group.name) ? "▸" : "▾")
                                            .pkFont(size: 10, weight: .semibold)
                                            .foregroundStyle(PK.textMuted)
                                        Text(group.name)
                                            .pkSectionLabel(size: 9)
                                        Spacer()
                                        Text("\(group.projects.count)")
                                            .pkFont(size: 9, weight: .semibold, design: .monospaced)
                                            .foregroundStyle(PK.textMuted)
                                    }
                                    .padding(.horizontal, 4)
                                    .padding(.top, 3)
                                }
                                .buttonStyle(.plain)

                                if !model.collapsedGroups.contains(group.name) {
                                    if group.projects.isEmpty {
                                        Text("Empty")
                                            .pkFont(size: 10)
                                            .foregroundStyle(PK.textMuted)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 6)
                                    } else {
                                        ForEach(group.projects) { project in
                                            SidebarProjectRow(
                                                project: project,
                                                isSelected: model.selectedProjectID == project.id,
                                                isRunning: isProjectRunning(project)
                                            ) {
                                                model.selectProject(id: project.id)
                                                Task { await model.scan() }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            }
            .frame(maxHeight: .infinity)
            .overlay(Rectangle().fill(PK.divider).frame(height: 1), alignment: .bottom)

            runningSection
        }
        .frame(width: model.sidebarWidth)
        .background(PK.bgSidebar)
    }

    private var sidebarResizeHandle: some View {
        Rectangle()
            .fill(PK.divider.opacity(0.001))
            .frame(width: 8)
            .overlay(Rectangle().fill(PK.divider).frame(width: 1))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if sidebarDragStartWidth == nil {
                            sidebarDragStartWidth = model.sidebarWidth
                        }
                        model.setSidebarWidth((sidebarDragStartWidth ?? model.sidebarWidth) + value.translation.width)
                    }
                    .onEnded { _ in
                        sidebarDragStartWidth = nil
                    }
            )
    }

    private var runningSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Running")
                .pkSectionLabel()

            if model.runningProcesses.isEmpty {
                Text("No listening ports")
                    .pkFont(size: 11)
                    .foregroundStyle(PK.textMuted)
                    .padding(.vertical, 8)
            } else {
                ForEach(model.runningProcesses.prefix(8)) { process in
                    RunningProcessRow(process: process, projectName: projectName(for: process), commandName: commandName(for: process)) {
                        model.selectRunningProcess(process)
                    } stop: {
                        Task { await model.stopRunningProcess(process) }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mainColumns: some View {
        HStack(spacing: 0) {
            commandColumn
            Divider().overlay(PK.divider)
            detailColumn
        }
    }

    private var commandColumn: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text(model.selectedProject?.name ?? "No project selected")
                        .pkFont(size: 16, weight: .bold)
                        .tracking(-0.3)
                        .foregroundStyle(PK.textPrimary)
                    if let project = model.selectedProject {
                        PKTypeBadge(kind: project.kind)
                    }
                }
                Text(model.selectedProject?.path ?? "Add a project to begin.")
                    .pkFont(size: 10, design: .monospaced)
                    .foregroundStyle(PK.textMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .overlay(Rectangle().fill(PK.divider.opacity(0.85)).frame(height: 1), alignment: .bottom)

            HStack {
                Text("Name")
                    .pkSectionLabel(size: 9)
                    .frame(width: 80, alignment: .leading)
                Text("Command")
                    .pkSectionLabel(size: 9)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(PK.bgDeep2)
            .overlay(Rectangle().fill(PK.divider.opacity(0.85)).frame(height: 1), alignment: .bottom)

            ScrollView {
                LazyVStack(spacing: 0) {
                    if let project = model.selectedProject {
                        ForEach(project.commands) { command in
                            DashboardCommandRow(
                                command: command,
                                isSelected: model.selectedCommandID == command.id
                            ) {
                                model.useCommand(command)
                            } remove: {
                                model.removeManualCommand(command)
                            }
                        }
                        AddCustomCommandRow()
                    } else {
                        Text("Select a project from the sidebar.")
                            .pkFont(size: 12)
                            .foregroundStyle(PK.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                    }
                }
            }
        }
        .frame(width: 350)
    }

    private var detailColumn: some View {
        ScrollView {
            VStack(spacing: 12) {
                runnerCard
                processDetailsCard
                consoleCard
            }
            .padding(14)
        }
    }

    private var runnerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Runner")
                .pkSectionLabel()

            VStack(alignment: .leading, spacing: 5) {
                Text("Command")
                    .pkSectionLabel(size: 9)
                TextField("Command", text: $model.command, axis: .vertical)
                    .textFieldStyle(.plain)
                    .pkFont(size: 12, design: .monospaced)
                    .foregroundStyle(PK.textPrimary)
                    .lineLimit(2...3)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(PK.bgInput, in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(PK.borderActive.opacity(0.9)))
            }

            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Port")
                        .pkSectionLabel(size: 9)
                    TextField("3000", text: Binding(
                        get: { model.port },
                        set: { model.setPort($0) }
                    ))
                    .textFieldStyle(.plain)
                    .pkFont(size: 12, weight: .medium, design: .monospaced)
                    .foregroundStyle(PK.cyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(PK.bgInput, in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(PK.borderNormal))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Status")
                        .pkSectionLabel(size: 9)
                    HStack(spacing: 6) {
                        PKRunningDot(isRunning: model.isSelectedPortRunning)
                        Text(model.isSelectedPortRunning ? "Running" : "Idle")
                            .pkFont(size: 11, weight: .medium)
                            .foregroundStyle(model.isSelectedPortRunning ? PK.green : PK.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(PK.bgInput, in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(model.isSelectedPortRunning ? PK.green.opacity(0.25) : PK.borderNormal))
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Working Directory")
                    .pkSectionLabel(size: 9)
                TextField("Working directory", text: $model.workingDirectory)
                    .textFieldStyle(.plain)
                    .pkFont(size: 11, design: .monospaced)
                    .foregroundStyle(PK.textSecondary)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(PK.bgInput, in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(PK.borderNormal))
            }

            TemplateParameterFields()

            HStack(spacing: 6) {
                Button("Start") {
                    Task { await model.start() }
                }
                .buttonStyle(PKPrimaryButtonStyle(color: PK.teal, foreground: PK.bgDeepest))

                Button("Restart") {
                    Task { await model.restart() }
                }
                .buttonStyle(PKPrimaryButtonStyle(color: PK.orange, foreground: .white))
                .disabled(!model.canControlSelectedProcess || model.isBusy)

                Button(model.stopConfirmPending ? "Confirm?" : "Stop") {
                    Task { await model.stop() }
                }
                .buttonStyle(PKPrimaryButtonStyle(color: PK.red, foreground: .white))
                .disabled(!model.canControlSelectedProcess || model.isBusy)
            }
        }
        .padding(12)
        .background(PK.bgSection, in: RoundedRectangle(cornerRadius: 8))
    }

    private var consoleCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Console")
                    .pkSectionLabel()
                if !model.activeLaunchPIDs.isEmpty {
                    HStack(spacing: 6) {
                        PKRunningDot(isRunning: true)
                        Text("Live")
                            .pkFont(size: 10, weight: .semibold)
                            .foregroundStyle(PK.green)
                    }
                }
                Spacer()
                Button("Clear") {
                    model.clearLogs()
                }
                .buttonStyle(.plain)
                .pkFont(size: 10, weight: .semibold)
                .foregroundStyle(PK.textMuted)
                .disabled(model.commandLogs.isEmpty)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        if model.commandLogs.isEmpty {
                            Text("No command output yet.")
                                .pkFont(size: 11)
                                .foregroundStyle(PK.textMuted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                        } else {
                            ForEach(model.commandLogs) { entry in
                                ConsoleLine(entry: entry)
                                    .id(entry.id)
                            }
                        }
                    }
                    .padding(10)
                }
                .frame(minHeight: 150, maxHeight: 260)
                .background(PK.bgInput, in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(PK.borderNormal.opacity(0.75)))
                .onChange(of: model.commandLogs.last?.id) { _, id in
                    guard let id else { return }
                    proxy.scrollTo(id, anchor: .bottom)
                }
            }
        }
        .padding(12)
        .background(PK.bgSection, in: RoundedRectangle(cornerRadius: 8))
    }

    private var processDetailsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Process Details")
                    .pkSectionLabel()
                Spacer()
                if model.isSelectedPortRunning {
                    HStack(spacing: 6) {
                        PKRunningDot(isRunning: true)
                        Text("Running")
                            .pkFont(size: 11, weight: .medium)
                            .foregroundStyle(PK.green)
                    }
                }
            }

            if let process = model.selectedProcess {
                HStack(spacing: 10) {
                    metric("PID", "\(process.pid)", color: PK.textPrimary)
                    metric("PPID", process.parentPID.map(String.init) ?? "?", color: PK.textSecondary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Command Args")
                        .pkSectionLabel(size: 9)
                    Text(process.arguments.isEmpty ? process.name : process.arguments)
                        .pkFont(size: 10, design: .monospaced)
                        .foregroundStyle(PK.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 7)
                        .background(PK.bgInput, in: RoundedRectangle(cornerRadius: 5))
                }

                Button("↗ Open localhost:\(model.port)") {
                    model.openLocalhost()
                }
                .buttonStyle(.plain)
                .pkFont(size: 11, weight: .medium)
                .foregroundStyle(PK.cyan)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 6)
                .overlay(Rectangle().fill(PK.divider.opacity(0.75)).frame(height: 1), alignment: .top)
            } else {
                Text("No process is listening on :\(model.port).")
                    .pkFont(size: 12)
                    .foregroundStyle(PK.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(PK.bgSection, in: RoundedRectangle(cornerRadius: 8))
    }

    private func metric(_ label: String, _ value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .pkSectionLabel(size: 9)
            Text(value)
                .pkFont(size: 14, weight: .medium, design: .monospaced)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func isProjectRunning(_ project: ProjectItem) -> Bool {
        model.runningProcesses.contains { process in
            process.workingDirectory == project.path || process.workingDirectory.hasPrefix(project.path + "/")
        }
    }

    private func projectName(for process: PortProcess) -> String {
        projectsMatching(process).first?.name ?? process.workingDirectory.split(separator: "/").last.map(String.init) ?? "process"
    }

    private func commandName(for process: PortProcess) -> String {
        let args = process.arguments.lowercased()
        guard let project = projectsMatching(process).first else {
            return process.command
        }

        return project.commands.first { command in
            let commandText = command.command.lowercased()
            if args.contains(commandText) {
                return true
            }
            if commandText.hasPrefix("npm run ") {
                let scriptName = commandText
                    .replacingOccurrences(of: "npm run ", with: "")
                    .split(separator: " ")
                    .first
                    .map(String.init) ?? ""
                return !scriptName.isEmpty && args.contains("npm run \(scriptName)")
            }
            return false
        }?.name ?? process.command
    }

    private func projectsMatching(_ process: PortProcess) -> [ProjectItem] {
        model.projects.filter { project in
            process.workingDirectory == project.path || process.workingDirectory.hasPrefix(project.path + "/")
        }
    }
}

private struct SidebarProjectRow: View {
    @EnvironmentObject private var model: ProcessMonitor
    @State private var confirmRemove = false
    let project: ProjectItem
    let isSelected: Bool
    let isRunning: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .pkFont(size: 12, weight: isSelected ? .bold : .semibold)
                        .foregroundStyle(isSelected ? PK.textPrimary : PK.textSecondary)
                        .lineLimit(1)
                    HStack(spacing: 5) {
                        PKTypeBadge(kind: project.kind)
                        if isRunning {
                            Circle().fill(PK.green).frame(width: 5, height: 5)
                            Text(":\(project.preferredPort ?? "")")
                                .pkFont(size: 9, weight: .medium, design: .monospaced)
                                .foregroundStyle(PK.green)
                        }
                    }
                }
                Spacer()
                Menu {
                    Button("Ungrouped") {
                        model.setGroup(nil, for: project.id)
                    }
                    if !model.groupNames.isEmpty {
                        Divider()
                        ForEach(model.groupNames, id: \.self) { groupName in
                            Button(groupName) {
                                model.setGroup(groupName, for: project.id)
                            }
                        }
                    }
                    Divider()
                    Button(confirmRemove ? "Confirm Remove Project" : "Remove Project", role: .destructive) {
                        if confirmRemove {
                            model.removeProject(id: project.id)
                            confirmRemove = false
                        } else {
                            confirmRemove = true
                        }
                    }
                } label: {
                    Text(isSelected ? "›" : "⋯")
                        .pkFont(size: 14)
                        .foregroundStyle(PK.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? PK.bgInput : .clear, in: RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct RunningProcessRow: View {
    let process: PortProcess
    let projectName: String
    let commandName: String
    let action: () -> Void
    let stop: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        PKRunningDot(isRunning: true)
                        Text(commandName)
                            .pkFont(size: 11, weight: .semibold)
                            .foregroundStyle(PK.textPrimary)
                            .lineLimit(1)
                    }
                    HStack(spacing: 8) {
                        Text(":\(process.port.map(String.init) ?? "?")")
                            .pkFont(size: 10, weight: .medium, design: .monospaced)
                            .foregroundStyle(PK.cyan)
                        Text("PID \(process.pid)")
                            .pkFont(size: 10)
                            .foregroundStyle(PK.textMuted)
                        Text(projectName)
                            .pkFont(size: 10)
                            .foregroundStyle(PK.textMuted)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button(action: stop) {
                Text("■")
                    .pkFont(size: 9, weight: .semibold)
                    .foregroundStyle(PK.red)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 4)
                    .background(PK.red.opacity(0.10), in: RoundedRectangle(cornerRadius: 3))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(PK.bgSection, in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(PK.green.opacity(0.20)))
    }

}

private struct ConsoleLine: View {
    let entry: CommandLogEntry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            Text(prefix)
                .pkFont(size: 10, weight: .semibold, design: .monospaced)
                .foregroundStyle(color.opacity(0.9))
                .frame(width: 18, alignment: .leading)
            Text(entry.text)
                .pkFont(size: 10, design: .monospaced)
                .foregroundStyle(color)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var prefix: String {
        switch entry.kind {
        case .command:
            "$"
        case .info:
            "i"
        case .output:
            ">"
        case .error:
            "!"
        case .exit:
            "x"
        }
    }

    private var color: Color {
        switch entry.kind {
        case .command:
            PK.cyan
        case .info, .exit:
            PK.textMuted
        case .output:
            PK.textSecondary
        case .error:
            PK.red
        }
    }
}

private struct DashboardCommandRow: View {
    let command: ProjectCommand
    let isSelected: Bool
    let action: () -> Void
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: action) {
                HStack(spacing: 8) {
                    Text(command.name)
                        .pkFont(size: 12, weight: isSelected ? .bold : .regular)
                        .foregroundStyle(isSelected ? PK.textPrimary : PK.textSecondary)
                        .frame(width: 80, alignment: .leading)
                    Text(command.command)
                        .pkFont(size: 11, design: .monospaced)
                        .foregroundStyle(isSelected ? PK.teal : PK.textMuted)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.vertical, 9)
                .padding(.leading, isSelected ? 12 : 14)
                .padding(.trailing, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isSelected ? PK.bgInput : .clear)
                .contentShape(Rectangle())
                .overlay(alignment: .leading) {
                    if isSelected {
                        Rectangle().fill(PK.teal).frame(width: 2)
                    }
                }
            }
            .buttonStyle(.plain)

            if command.isManual {
                Button("−") {
                    remove()
                }
                .buttonStyle(.plain)
                .pkFont(size: 11, weight: .bold)
                .foregroundStyle(PK.red)
                .padding(.trailing, 8)
            }
        }
        .overlay(Rectangle().fill(PK.divider.opacity(0.65)).frame(height: 1), alignment: .top)
    }
}

private struct AddCustomCommandRow: View {
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("+ Add custom command") {
                isExpanded.toggle()
            }
            .buttonStyle(.plain)
            .pkFont(size: 11)
            .foregroundStyle(PK.purple)

            if isExpanded {
                ManualCommandEditor()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .overlay(Rectangle().fill(PK.divider.opacity(0.65)).frame(height: 1), alignment: .top)
    }
}
