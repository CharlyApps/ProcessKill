import AppKit
import SwiftUI

struct CompactView: View {
    @EnvironmentObject private var model: ProcessMonitor

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 0) {
                projectSelector
                commandInput
                commandList
                parameterFields
                workingDirectory
                actions
                latestLog
                statusBar
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(PK.bgDeepest)
        .task {
            await model.scan()
        }
    }

    private var projectSelector: some View {
        Menu {
            ForEach(model.groupedProjects, id: \.name) { group in
                Section(group.name) {
                    ForEach(group.projects) { project in
                        Button {
                            model.selectProject(id: project.id)
                            Task { await model.scan() }
                        } label: {
                            Text("\(project.name)  \(project.kind.rawValue)")
                        }
                    }
                }
            }
            Divider()
            Button("+ Add Project") {
                model.addProjectFolder()
            }
        } label: {
            HStack {
                HStack(spacing: 8) {
                    PKRunningDot(isRunning: model.isSelectedPortRunning)
                    Text(model.selectedProject?.name ?? "Select project")
                        .pkFont(size: 13, weight: .bold)
                        .foregroundStyle(PK.textPrimary)
                        .lineLimit(1)
                    if let project = model.selectedProject {
                        PKTypeBadge(kind: project.kind)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Text(":\(model.port)")
                        .pkFont(size: 12, weight: .medium, design: .monospaced)
                        .foregroundStyle(PK.cyan)
                    Text("▾")
                        .pkFont(size: 11)
                        .foregroundStyle(PK.textMuted)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(PK.bgSection, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(PK.borderNormal))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.top, 12)
    }

    private var commandInput: some View {
        HStack(spacing: 8) {
            Text("⌕")
                .pkFont(size: 15)
                .foregroundStyle(PK.textMuted)

            TextField("Command", text: $model.command)
                .textFieldStyle(.plain)
                .pkFont(size: 13, design: .monospaced)
                .foregroundStyle(PK.textPrimary)
                .onSubmit {
                    Task { await model.start() }
                }

            Text("↵ \(model.selectedCommand?.name ?? "run")")
                .pkFont(size: 9, weight: .semibold)
                .tracking(0.3)
                .foregroundStyle(PK.textMuted)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Color(red: 91 / 255, green: 60 / 255, blue: 196 / 255).opacity(0.14), in: RoundedRectangle(cornerRadius: 3))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(PK.bgSection, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(PK.borderActive))
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    private var commandList: some View {
        VStack(spacing: 0) {
            if let project = model.selectedProject, !project.commands.isEmpty {
                ForEach(project.commands.prefix(7)) { command in
                    CompactCommandRow(
                        command: command,
                        isSelected: model.selectedCommandID == command.id
                    ) {
                        model.useCommand(command)
                    }
                }
            } else {
                Text("Add a project to see commands.")
                    .pkFont(size: 12)
                    .foregroundStyle(PK.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(PK.bgMain)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(PK.borderDefault))
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    @ViewBuilder
    private var parameterFields: some View {
        if model.activeTemplateCommand != nil {
            TemplateParameterFields()
                .padding(.horizontal, 12)
                .padding(.top, 6)
        }
    }

    private var workingDirectory: some View {
        HStack(spacing: 8) {
            Text("Dir")
                .pkFont(size: 9, weight: .semibold)
                .tracking(1)
                .foregroundStyle(PK.textMuted)
                .textCase(.uppercase)
            Text(model.workingDirectory.isEmpty ? "No working directory" : model.workingDirectory)
                .pkFont(size: 10, design: .monospaced)
                .foregroundStyle(PK.textSecondary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(PK.bgSection, in: RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    private var actions: some View {
        HStack(spacing: 6) {
            Button {
                Task { await model.start() }
            } label: {
                Label("Start", systemImage: "play.fill")
            }
            .buttonStyle(PKPrimaryButtonStyle(color: PK.teal, foreground: PK.bgDeepest))

            Button("Restart") {
                Task { await model.restart() }
            }
            .buttonStyle(PKPrimaryButtonStyle(color: PK.orange, foreground: .white))
            .disabled(model.selectedProcess == nil || model.isBusy)

            Button(model.stopConfirmPending ? "Confirm?" : "Stop") {
                Task { await model.stop() }
            }
            .buttonStyle(PKPrimaryButtonStyle(color: PK.red, foreground: .white))
            .disabled(model.selectedProcess == nil || model.isBusy)
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var latestLog: some View {
        if let entry = model.commandLogs.last {
            HStack(spacing: 7) {
                Text(logPrefix(for: entry.kind))
                    .pkFont(size: 10, weight: .semibold, design: .monospaced)
                    .foregroundStyle(logColor(for: entry.kind))
                    .frame(width: 12, alignment: .leading)
                Text(entry.text)
                    .pkFont(size: 10, design: .monospaced)
                    .foregroundStyle(logColor(for: entry.kind))
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(PK.bgSection, in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(PK.borderNormal.opacity(0.7)))
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    private var statusBar: some View {
        HStack {
            HStack(spacing: 7) {
                Circle()
                    .fill(model.isSelectedPortRunning ? PK.green : PK.textMuted)
                    .frame(width: 6, height: 6)
                Text(model.status.text)
                    .pkFont(size: 11)
                    .foregroundStyle(PK.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button("↗ localhost") {
                model.openLocalhost()
            }
            .buttonStyle(.plain)
            .pkFont(size: 11, weight: .medium)
            .foregroundStyle(PK.cyan)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .overlay(Rectangle().fill(PK.divider).frame(height: 1), alignment: .top)
    }

    private func logPrefix(for kind: CommandLogEntry.Kind) -> String {
        switch kind {
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

    private func logColor(for kind: CommandLogEntry.Kind) -> Color {
        switch kind {
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

private struct CompactCommandRow: View {
    let command: ProjectCommand
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isSelected {
                    HStack(spacing: 9) {
                        Text("▶")
                            .pkFont(size: 10)
                            .foregroundStyle(PK.teal)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(command.name)
                                .pkFont(size: 12, weight: .semibold)
                                .foregroundStyle(PK.textPrimary)
                            Text(command.command)
                                .pkFont(size: 10, design: .monospaced)
                                .foregroundStyle(PK.teal)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    Text("⏎")
                        .pkFont(size: 10, weight: .semibold)
                        .foregroundStyle(PK.textMuted)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color(red: 91 / 255, green: 60 / 255, blue: 196 / 255).opacity(0.14), in: RoundedRectangle(cornerRadius: 3))
                } else {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(command.name)
                            .pkFont(size: 12)
                            .foregroundStyle(PK.textSecondary)
                        Text(command.command)
                            .pkFont(size: 10, design: .monospaced)
                            .foregroundStyle(PK.textMuted)
                            .lineLimit(1)
                    }
                    Spacer()
                }
            }
            .padding(.vertical, isSelected ? 8 : 7)
            .padding(.leading, isSelected ? 10 : 23)
            .padding(.trailing, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? PK.bgInput : PK.bgMain)
            .overlay(alignment: .leading) {
                if isSelected {
                    Rectangle().fill(PK.teal).frame(width: 2)
                }
            }
            .overlay(Rectangle().fill(PK.borderDefault.opacity(isSelected ? 0 : 0.65)).frame(height: 1), alignment: .top)
        }
        .buttonStyle(.plain)
    }
}

struct ProcessCard: View {
    let process: PortProcess
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(process.command)
                        .pkFont(size: 12, weight: .semibold)
                        .foregroundStyle(PK.textPrimary)
                    Spacer()
                    Text("PID \(process.pid)")
                        .pkFont(size: 10, design: .monospaced)
                        .foregroundStyle(PK.textMuted)
                }
                Text(process.arguments.isEmpty ? process.name : process.arguments)
                    .pkFont(size: 10, design: .monospaced)
                    .foregroundStyle(PK.textSecondary)
                    .lineLimit(2)
            }
            .padding(10)
            .background(PK.bgSection, in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(isSelected ? PK.borderSelected : PK.borderDefault))
        }
        .buttonStyle(.plain)
    }
}
