import SwiftUI

struct TemplateParameterFields: View {
    @EnvironmentObject private var model: ProcessMonitor

    var body: some View {
        if let template = model.activeTemplateCommand, !template.placeholders.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Parameters")
                    .pkFont(size: 12, weight: .bold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                    ForEach(template.placeholders, id: \.self) { placeholder in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(placeholder)
                                .pkFont(size: 11, weight: .bold)
                                .foregroundStyle(.secondary)
                            TextField(placeholder, text: Binding(
                                get: { model.templateValues[placeholder, default: ""] },
                                set: { model.setTemplateValue($0, for: placeholder) }
                            ))
                            .textFieldStyle(.plain)
                            .pkFont(size: 12, design: .monospaced)
                            .padding(.horizontal, 10)
                            .frame(height: 34)
                            .background(.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.10)))
                        }
                    }
                }
            }
            .padding(10)
            .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.10)))
        }
    }
}

struct ManualCommandEditor: View {
    @EnvironmentObject private var model: ProcessMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Manual template")
                    .pkFont(size: 12, weight: .bold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Button("Add") {
                    model.addManualCommand()
                }
                .buttonStyle(PKPlainButtonStyle())
                .pkFont(size: 12, weight: .bold)
                .foregroundStyle(Color(red: 0.36, green: 0.78, blue: 0.65))
                .disabled(model.selectedProject == nil)
            }

            TextField("Name, e.g. migrate", text: $model.manualCommandName)
                .textFieldStyle(.plain)
                .pkFont(size: 12, weight: .medium)
                .padding(.horizontal, 10)
                .frame(height: 34)
                .background(.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.10)))

            TextField("npm run migrate -- --tenant {{tenant}}", text: $model.manualCommandTemplate, axis: .vertical)
                .textFieldStyle(.plain)
                .pkFont(size: 12, design: .monospaced)
                .lineLimit(2...3)
                .padding(10)
                .background(.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.10)))
        }
        .padding(10)
        .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.10)))
    }
}
