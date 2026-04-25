import AppKit
import SwiftUI

struct SettingsView: View {
    @Bindable var store: RunnerMenuStore
    @Bindable var preferences: AppPreferencesStore
    @Bindable var updater: AppUpdateService

    @State private var selection: SettingsSection? = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(selectedSection.title)
                        .font(.title2.weight(.semibold))

                    detailView(for: selectedSection)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }

    private var selectedSection: SettingsSection {
        selection ?? .general
    }

    @ViewBuilder
    private func detailView(for section: SettingsSection) -> some View {
        switch section {
        case .general:
            GeneralSettingsPane(store: store, preferences: preferences)
        case .runner:
            RunnerSettingsPane(store: store)
        case .updates:
            UpdatesSettingsPane(preferences: preferences, updater: updater)
        case .network:
            NetworkSettingsPane(store: store)
        case .advanced:
            AdvancedSettingsPane(store: store)
        case .about:
            AboutSettingsPane(updater: updater)
        }
    }
}

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case runner
    case updates
    case network
    case advanced
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:
            AppStrings.settingsGeneralTitle
        case .runner:
            AppStrings.settingsRunnerTitle
        case .updates:
            AppStrings.settingsUpdatesTitle
        case .network:
            AppStrings.settingsNetworkTitle
        case .advanced:
            AppStrings.settingsAdvancedTitle
        case .about:
            AppStrings.settingsAboutTitle
        }
    }

    var systemImage: String {
        switch self {
        case .general:
            "gearshape"
        case .runner:
            "play.rectangle"
        case .updates:
            "arrow.down.circle"
        case .network:
            "network"
        case .advanced:
            "wrench.and.screwdriver"
        case .about:
            "info.circle"
        }
    }
}

private struct GeneralSettingsPane: View {
    @Bindable var store: RunnerMenuStore
    @Bindable var preferences: AppPreferencesStore

    var body: some View {
        SettingsGroup {
            Picker(AppStrings.settingsLanguageTitle, selection: $preferences.language) {
                ForEach(AppLanguagePreference.allCases) { language in
                    Text(language.title)
                        .tag(language)
                }
            }
            .pickerStyle(.menu)

            Text(AppStrings.settingsLanguageRestartHint)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(
                AppStrings.toggleLaunchAtLogin,
                isOn: Binding(
                    get: { store.launchAtLoginEnabled },
                    set: { store.setLaunchAtLogin($0) }
                )
            )

            if store.launchAtLoginStatus == .requiresApproval {
                Button(AppStrings.buttonOpenLoginItemsSettings) {
                    store.openLoginItemsSettings()
                }
            }
        }
    }
}

private struct RunnerSettingsPane: View {
    @Bindable var store: RunnerMenuStore

    var body: some View {
        SettingsGroup {
            InfoRow(title: AppStrings.statusRunnerTitle, value: store.runnerStatusText)
            InfoRow(title: AppStrings.statusActivityTitle, value: store.activityStatusText)
            InfoRow(title: AppStrings.settingsRunnerFolderTitle, value: store.runnerPathDisplay)

            HStack(spacing: 10) {
                Button(AppStrings.buttonOpenRunnerDirectory) {
                    store.openRunnerDirectory()
                }

                Button(AppStrings.buttonManualStart) {
                    store.forceStart()
                }

                Button(AppStrings.buttonManualStop) {
                    store.forceStop()
                }

                Button(AppStrings.buttonRefresh) {
                    store.refreshNow()
                }
            }
        }
    }
}

private struct UpdatesSettingsPane: View {
    @Bindable var preferences: AppPreferencesStore
    @Bindable var updater: AppUpdateService

    var body: some View {
        SettingsGroup {
            InfoRow(title: AppStrings.updateInstalledVersionTitle, value: updater.installedVersion)
            InfoRow(
                title: AppStrings.updateLatestVersionTitle,
                value: updater.latestRelease?.version ?? AppStrings.updateUnknownVersion
            )
            InfoRow(title: AppStrings.updateStatusTitle, value: updater.statusText)

            Toggle(AppStrings.settingsAutomaticUpdateCheckTitle, isOn: $preferences.automaticUpdateCheckEnabled)

            Picker(AppStrings.settingsUpdateChannelTitle, selection: $preferences.updateChannel) {
                ForEach(AppUpdateChannel.allCases) { channel in
                    Text(channel.title)
                        .tag(channel)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 10) {
                Button(AppStrings.buttonCheckForUpdates) {
                    updater.checkForUpdates()
                }
                .disabled(updater.isBusy)

                Button(AppStrings.buttonInstallUpdate) {
                    updater.installLatestUpdate()
                }
                .buttonStyle(.borderedProminent)
                .disabled(updater.isBusy)

                Button(AppStrings.buttonOpenReleasePage) {
                    updater.openReleasePage()
                }
            }
        }
    }
}

private struct NetworkSettingsPane: View {
    @Bindable var store: RunnerMenuStore

    var body: some View {
        SettingsGroup {
            InfoRow(title: AppStrings.settingsNetworkStateTitle, value: store.networkStatusText)
            InfoRow(title: AppStrings.settingsNetworkPolicyTitle, value: store.policySummary)
            InfoRow(title: AppStrings.settingsNetworkOverrideTitle, value: store.controlMode.title)

            Text(AppStrings.settingsNetworkExplanation)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct AdvancedSettingsPane: View {
    @Bindable var store: RunnerMenuStore

    var body: some View {
        SettingsGroup {
            InfoRow(
                title: AppStrings.settingsAdvancedRunnerProcessTitle,
                value: store.runnerResourceUsage.isRunning ? AppStrings.runnerRunning : AppStrings.runnerStopped
            )
            InfoRow(
                title: AppStrings.settingsAdvancedCPU,
                value: String(format: "%.1f%%", store.runnerResourceUsage.cpuPercent)
            )
            InfoRow(
                title: AppStrings.settingsAdvancedMemory,
                value: "\(Int(store.runnerResourceUsage.memoryMB.rounded())) MB"
            )
            InfoRow(
                title: AppStrings.settingsAdvancedJobActive,
                value: store.runnerResourceUsage.isJobActive ? AppStrings.booleanYes : AppStrings.booleanNo
            )
        }
    }
}

private struct AboutSettingsPane: View {
    @Bindable var updater: AppUpdateService

    private let githubURL = URL(string: "https://github.com/BenKoncsik")!
    private let xURL = URL(string: "https://x.com/BenedekKoncsik")!
    private let repositoryURL = URL(string: "https://github.com/HunKonTech/github-runer-mac")!

    var body: some View {
        SettingsGroup {
            InfoRow(title: AppStrings.settingsAboutAppNameTitle, value: AppStrings.appName)
            InfoRow(title: AppStrings.updateInstalledVersionTitle, value: updater.installedVersion)
            InfoRow(title: AppStrings.settingsAboutLicenseTitle, value: AppStrings.settingsAboutLicenseValue)

            HStack(spacing: 10) {
                Link(AppStrings.buttonOpenAuthorGitHub, destination: githubURL)
                Link(AppStrings.buttonOpenAuthorX, destination: xURL)
                Link(AppStrings.buttonOpenRepository, destination: repositoryURL)
            }
        }
    }
}

private struct SettingsGroup<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .frame(maxWidth: 520, alignment: .leading)
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .fontWeight(.medium)

            Spacer(minLength: 16)

            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .font(.subheadline)
    }
}
