import AppKit
import SwiftUI

@main
struct ProcessKillApp: App {
    @StateObject private var model = ProcessMonitor()
    @AppStorage("fontScale") private var fontScale = 1.0

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(model)
                .environment(\.pkFontScale, CGFloat(fontScale))
                .frame(minWidth: 980, idealWidth: 1280, minHeight: 680, idealHeight: 780)
                .background(WindowAccessor())
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("View") {
                Button("Increase Font Size") {
                    adjustFontScale(by: 0.05)
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Decrease Font Size") {
                    adjustFontScale(by: -0.05)
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("Reset Font Size") {
                    fontScale = 1
                }
                .keyboardShortcut("0", modifiers: .command)
            }
        }

        MenuBarExtra("ProcessKill", systemImage: "bolt.circle") {
            CompactView()
                .environmentObject(model)
                .environment(\.pkFontScale, CGFloat(fontScale))
                .frame(width: 480, height: 520)
                .background(PK.bgDeepest)
        }
        .menuBarExtraStyle(.window)

        Settings {
            PreferencesView(fontScale: $fontScale)
                .environment(\.pkFontScale, CGFloat(fontScale))
        }
    }

    private func adjustFontScale(by delta: Double) {
        fontScale = min(1.6, max(0.9, fontScale + delta))
    }
}

private struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.title = "ProcessKill"
            window.isMovableByWindowBackground = true
            window.titlebarAppearsTransparent = true
            window.backgroundColor = .windowBackgroundColor
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
