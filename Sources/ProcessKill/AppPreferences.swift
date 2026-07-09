import SwiftUI

private struct PKFontScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

extension EnvironmentValues {
    var pkFontScale: CGFloat {
        get { self[PKFontScaleKey.self] }
        set { self[PKFontScaleKey.self] = newValue }
    }
}

private struct PKScaledFont: ViewModifier {
    @Environment(\.pkFontScale) private var scale

    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    func body(content: Content) -> some View {
        content.font(.system(size: size * scale, weight: weight, design: design))
    }
}

extension View {
    func pkFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(PKScaledFont(size: size, weight: weight, design: design))
    }
}

enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

struct PreferencesView: View {
    @Binding var fontScale: Double
    @Binding var theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Preferences")
                .pkFont(size: 22, weight: .bold)

            VStack(alignment: .leading, spacing: 10) {
                Text("Theme")
                    .pkFont(size: 13, weight: .semibold)

                Picker("Theme", selection: $theme) {
                    ForEach(AppTheme.allCases, id: \.self) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Font size")
                        .pkFont(size: 13, weight: .semibold)
                    Spacer()
                    Text("\(Int(fontScale * 100))%")
                        .pkFont(size: 12, weight: .medium, design: .monospaced)
                        .foregroundStyle(PK.textSecondary)
                }

                Slider(value: $fontScale, in: 0.9...1.6, step: 0.05)

                HStack {
                    Text("Small")
                    Spacer()
                    Text("Large")
                }
                .pkFont(size: 11)
                .foregroundStyle(PK.textMuted)
            }

            HStack {
                Button("Reset") {
                    fontScale = 1
                }
                Spacer()
                Text("Shortcuts: Cmd+Plus, Cmd+Minus, Cmd+0")
                    .pkFont(size: 11)
                    .foregroundStyle(PK.textMuted)
            }
        }
        .padding(22)
        .frame(width: 420)
        .background(PK.bgDeep2)
        .foregroundStyle(PK.textPrimary)
        .environment(\.pkFontScale, CGFloat(fontScale))
    }
}
