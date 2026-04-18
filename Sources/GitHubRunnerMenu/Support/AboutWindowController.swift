import AppKit
import SwiftUI

@MainActor
final class AboutWindowController {
    static let shared = AboutWindowController()

    private var window: NSWindow?

    func show() {
        if let window {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let hostingController = NSHostingController(rootView: AboutWindowView())
        let window = NSWindow(contentViewController: hostingController)
        window.title = AppStrings.aboutWindowTitle
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.center()
        window.setContentSize(NSSize(width: 460, height: 240))
        window.isReleasedWhenClosed = false
        window.level = .floating

        self.window = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
