import XCTest
@testable import GitHubRunnerMenu

final class AppPreferencesStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "AppPreferencesStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    @MainActor
    func testDefaultLanguageIsSystem() {
        let store = AppPreferencesStore(defaults: defaults)

        XCTAssertEqual(store.language, .system)
    }

    @MainActor
    func testLanguagePersists() {
        let store = AppPreferencesStore(defaults: defaults)
        store.language = .hungarian

        let reloadedStore = AppPreferencesStore(defaults: defaults)

        XCTAssertEqual(reloadedStore.language, .hungarian)
        XCTAssertEqual(defaults.string(forKey: AppPreferencesStore.languageDefaultsKey), "hu")
    }

    @MainActor
    func testUpdateChannelPersists() {
        let store = AppPreferencesStore(defaults: defaults)
        store.updateChannel = .preview

        let reloadedStore = AppPreferencesStore(defaults: defaults)

        XCTAssertEqual(reloadedStore.updateChannel, .preview)
        XCTAssertEqual(defaults.string(forKey: AppPreferencesStore.updateChannelDefaultsKey), "preview")
    }

    @MainActor
    func testAutomaticUpdateCheckPersists() {
        let store = AppPreferencesStore(defaults: defaults)
        store.automaticUpdateCheckEnabled = true

        let reloadedStore = AppPreferencesStore(defaults: defaults)

        XCTAssertTrue(reloadedStore.automaticUpdateCheckEnabled)
    }

}
