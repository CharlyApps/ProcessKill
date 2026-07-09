import AppKit
import SwiftUI

enum PK {
    static let bgDeepest = Color(light: 0xFDFCFA, dark: 0x0A0818)
    static let bgMain = Color(light: 0xFAF9F6, dark: 0x121024)
    static let bgSection = Color(light: 0xF2F0EA, dark: 0x181330)
    static let bgInput = Color(light: 0xFFFFFF, dark: 0x1F1B3C)
    static let bgSelected = Color(light: 0xE4E3ED, dark: 0x292147)
    static let bgSidebar = Color(light: 0xFBFAF8, dark: 0x0A0816)
    static let bgDeep2 = Color(light: 0xF5F3EE, dark: 0x0D0A1C)

    static let textPrimary = Color(light: 0x211E2E, dark: 0xECE5F7)
    static let textSecondary = Color(light: 0x6B6558, dark: 0x9790B2)
    static let textMuted = Color(light: 0xA39C8C, dark: 0x5A5272)

    static let cyan = Color(hex: 0x00B4DA)
    static let teal = Color(hex: 0x5EDFD0)
    static let purple = Color(hex: 0x7A5CF0)
    static let red = Color(hex: 0xE53834)
    static let orange = Color(hex: 0xFF7043)
    static let green = Color(hex: 0x28BF7D)

    static let borderDefault = Color(light: 0x4C56C7, lightAlpha: 0.24, dark: 0x5B3CC4, darkAlpha: 0.16)
    static let borderNormal = Color(light: 0x4C56C7, lightAlpha: 0.34, dark: 0x5B3CC4, darkAlpha: 0.22)
    static let borderSelected = Color(light: 0x4C56C7, lightAlpha: 0.44, dark: 0x5B3CC4, darkAlpha: 0.32)
    static let borderActive = cyan.opacity(0.40)
    static let divider = Color(light: 0x4C56C7, lightAlpha: 0.18, dark: 0x5B3CC4, darkAlpha: 0.12)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255
        )
    }

    /// Dynamic color resolving per-appearance, so PK.* constants adapt when theme changes.
    init(light: UInt32, dark: UInt32) {
        self.init(light: light, lightAlpha: 1, dark: dark, darkAlpha: 1)
    }

    /// Dynamic color with independent alpha per appearance, needed since a fixed opacity
    /// reads very differently against a light vs. dark background.
    init(light: UInt32, lightAlpha: Double, dark: UInt32, darkAlpha: Double) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(Color(hex: isDark ? dark : light).opacity(isDark ? darkAlpha : lightAlpha))
        })
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

extension View {
    /// Shows the pointing-hand cursor while hovering, matching web-style button affordance.
    @ViewBuilder
    func pkPointerCursor(enabled: Bool = true) -> some View {
        if enabled {
            onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        } else {
            self
        }
    }
}

struct PKPlainButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .pkPointerCursor(enabled: isEnabled)
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
            .pkPointerCursor(enabled: isEnabled)
    }

    private func backgroundColor(configuration: Configuration) -> Color {
        guard isEnabled else {
            return PK.textMuted.opacity(0.16)
        }

        return color.opacity(configuration.isPressed ? 0.82 : 1)
    }
}
