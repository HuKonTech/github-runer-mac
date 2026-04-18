import SwiftUI

@main
struct GitHubRunnerMenuApp: App {
    @State private var store = RunnerMenuStore()

    var body: some Scene {
        MenuBarExtra {
            MenuPanelView(store: store)
        } label: {
            Label(AppStrings.appName, systemImage: store.menuBarSymbolName)
        }
        .menuBarExtraStyle(.window)
    }
}
