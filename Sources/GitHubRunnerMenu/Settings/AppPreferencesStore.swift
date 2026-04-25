import Foundation
import Observation

enum AppLanguagePreference: String, CaseIterable, Identifiable {
    case system
    case hungarian = "hu"
    case english = "en"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            AppStrings.languageSystemDefault
        case .hungarian:
            AppStrings.languageHungarian
        case .english:
            AppStrings.languageEnglish
        }
    }

    var appStringsIdentifier: String? {
        switch self {
        case .system:
            nil
        case .hungarian:
            "hu"
        case .english:
            "en"
        }
    }
}

enum AppUpdateChannel: String, CaseIterable, Identifiable {
    case stable
    case preview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stable:
            AppStrings.updateChannelStable
        case .preview:
            AppStrings.updateChannelPreview
        }
    }
}

@MainActor
@Observable
final class AppPreferencesStore {
    static let shared = AppPreferencesStore()

    nonisolated static let languageDefaultsKey = "AppLanguagePreference"
    nonisolated static let automaticUpdateCheckDefaultsKey = "AutomaticUpdateCheckEnabled"
    nonisolated static let updateChannelDefaultsKey = "UpdateChannel"

    @ObservationIgnored private let defaults: UserDefaults

    var language: AppLanguagePreference {
        didSet {
            defaults.set(language.rawValue, forKey: Self.languageDefaultsKey)
        }
    }

    var automaticUpdateCheckEnabled: Bool {
        didSet {
            defaults.set(automaticUpdateCheckEnabled, forKey: Self.automaticUpdateCheckDefaultsKey)
        }
    }

    var updateChannel: AppUpdateChannel {
        didSet {
            defaults.set(updateChannel.rawValue, forKey: Self.updateChannelDefaultsKey)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if
            let rawLanguage = defaults.string(forKey: Self.languageDefaultsKey),
            let savedLanguage = AppLanguagePreference(rawValue: rawLanguage)
        {
            language = savedLanguage
        } else {
            language = .system
        }

        if defaults.object(forKey: Self.automaticUpdateCheckDefaultsKey) == nil {
            automaticUpdateCheckEnabled = false
        } else {
            automaticUpdateCheckEnabled = defaults.bool(forKey: Self.automaticUpdateCheckDefaultsKey)
        }

        if
            let rawChannel = defaults.string(forKey: Self.updateChannelDefaultsKey),
            let savedChannel = AppUpdateChannel(rawValue: rawChannel)
        {
            updateChannel = savedChannel
        } else {
            updateChannel = .stable
        }
    }
}
