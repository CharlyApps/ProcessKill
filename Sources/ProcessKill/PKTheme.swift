import SwiftUI

enum PK {
    static let bgDeepest = Color(hex: 0x0A0818)
    static let bgMain = Color(hex: 0x121024)
    static let bgSection = Color(hex: 0x181330)
    static let bgInput = Color(hex: 0x1F1B3C)
    static let bgSelected = Color(hex: 0x292147)
    static let bgSidebar = Color(hex: 0x0A0816)
    static let bgDeep2 = Color(hex: 0x0D0A1C)

    static let textPrimary = Color(hex: 0xECE5F7)
    static let textSecondary = Color(hex: 0x9790B2)
    static let textMuted = Color(hex: 0x5A5272)

    static let cyan = Color(hex: 0x00B4DA)
    static let teal = Color(hex: 0x5EDFD0)
    static let purple = Color(hex: 0x7A5CF0)
    static let red = Color(hex: 0xE53834)
    static let orange = Color(hex: 0xFF7043)
    static let green = Color(hex: 0x28BF7D)

    static let borderDefault = Color(red: 91 / 255, green: 60 / 255, blue: 196 / 255).opacity(0.16)
    static let borderNormal = Color(red: 91 / 255, green: 60 / 255, blue: 196 / 255).opacity(0.22)
    static let borderSelected = Color(red: 91 / 255, green: 60 / 255, blue: 196 / 255).opacity(0.32)
    static let borderActive = cyan.opacity(0.40)
    static let divider = Color(red: 91 / 255, green: 60 / 255, blue: 196 / 255).opacity(0.12)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255
        )
    }
}

struct PKTypeBadge: View {
    let kind: ProjectKind

    var body: some View {
        Text(kind.rawValue.uppercased())
            .pkFont(size: 9, weight: .semibold)
            .tracking(0.4)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(kind == .dotnet ? 0.10 : 0.12), in: RoundedRectangle(cornerRadius: 3))
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(color.opacity(kind == .flutter ? 0.28 : 0.22)))
    }

    private var color: Color {
        switch kind {
        case .flutter:
            PK.teal
        case .dotnet:
            PK.cyan
        case .node, .vue, .generic:
            PK.purple
        }
    }
}

struct PKTrafficLights: View {
    var body: some View {
        HStack(spacing: 7) {
            Circle().fill(Color(hex: 0xFF5F56))
            Circle().fill(Color(hex: 0xFFBD2E))
            Circle().fill(Color(hex: 0x27C93F))
        }
        .frame(width: 50, height: 12)
        .frame(maxWidth: 50)
    }
}

struct PKRunningDot: View {
    let isRunning: Bool
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(isRunning ? PK.green : PK.textMuted)
            .opacity(isRunning ? (pulse ? 0.25 : 1) : 1)
            .frame(width: 7, height: 7)
            .onAppear {
                guard isRunning else { return }
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

extension Text {
    @MainActor
    func pkSectionLabel(size: CGFloat = 10) -> some View {
        self
            .pkFont(size: size, weight: .semibold)
            .tracking(1.1)
            .foregroundStyle(PK.textMuted)
            .textCase(.uppercase)
    }
}

struct PKPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let color: Color
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .pkFont(size: 12, weight: .bold)
            .foregroundStyle(isEnabled ? foreground : PK.textMuted.opacity(0.85))
            .frame(maxWidth: .infinity, minHeight: 38)
            .background(backgroundColor(configuration: configuration), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(isEnabled ? .clear : PK.borderNormal.opacity(0.8)))
    }

    private func backgroundColor(configuration: Configuration) -> Color {
        guard isEnabled else {
            return PK.textMuted.opacity(0.16)
        }

        return color.opacity(configuration.isPressed ? 0.82 : 1)
    }
}
