import AppKit
import SwiftUI

@MainActor
final class UpdateWindowController {
    static let shared = UpdateWindowController()

    private let updater = AppUpdateService.shared
    private var window: NSWindow?

    func show() {
        if let window {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let hostingController = NSHostingController(rootView: UpdateWindowView(updater: updater))
        let window = NSWindow(contentViewController: hostingController)
        window.title = AppStrings.updateWindowTitle
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.center()
        window.setContentSize(NSSize(width: 540, height: 260))
        window.isReleasedWhenClosed = false
        window.level = .floating

        self.window = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        updater.checkForUpdates()
    }
}
