import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    func show(store: RunnerMenuStore) {
        if let window {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let hostingController = NSHostingController(
            rootView: SettingsView(
                store: store,
                preferences: .shared,
                updater: .shared
            )
        )
        let window = NSWindow(contentViewController: hostingController)
        window.title = AppStrings.settingsWindowTitle
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.center()
        window.setContentSize(NSSize(width: 700, height: 500))
        window.minSize = NSSize(width: 700, height: 500)
        window.isReleasedWhenClosed = false

        self.window = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
