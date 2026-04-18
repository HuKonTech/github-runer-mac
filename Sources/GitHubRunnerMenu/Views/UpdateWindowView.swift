import SwiftUI

struct UpdateWindowView: View {
    @Bindable var updater: AppUpdateService

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(AppStrings.updateWindowTitle)
                    .font(.title2.weight(.semibold))

                Text(AppStrings.updateDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                InfoRow(title: AppStrings.updateInstalledVersionTitle, value: updater.installedVersion)
                InfoRow(
                    title: AppStrings.updateLatestVersionTitle,
                    value: updater.latestRelease?.version ?? AppStrings.updateUnknownVersion
                )
                InfoRow(title: AppStrings.updateStatusTitle, value: updater.statusText)
            }

            HStack(spacing: 12) {
                Button(AppStrings.buttonCheckForUpdates) {
                    updater.checkForUpdates()
                }
                .buttonStyle(.bordered)
                .disabled(isBusy)

                Button(AppStrings.buttonInstallUpdate) {
                    updater.installLatestUpdate()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!updater.canInstallUpdate || isBusy)

                Button(AppStrings.buttonOpenReleasePage) {
                    updater.openReleasePage()
                }
                .buttonStyle(.bordered)
                .disabled(updater.latestRelease == nil)
            }
        }
        .padding(24)
        .frame(minWidth: 500, idealWidth: 540, minHeight: 250)
    }

    private var isBusy: Bool {
        switch updater.state {
        case .checking, .downloading, .installing:
            true
        case .idle, .upToDate, .updateAvailable, .failed:
            false
        }
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .fontWeight(.medium)

            Spacer(minLength: 12)

            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
