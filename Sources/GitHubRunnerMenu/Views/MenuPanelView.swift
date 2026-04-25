import AppKit
import SwiftUI

struct MenuPanelView: View {
    let store: RunnerMenuStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppStrings.appName)
                    .font(.headline)

                Text(store.policySummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                StatusRow(
                    title: AppStrings.statusRunnerTitle,
                    value: store.runnerStatusText,
                    color: runnerStatusColor
                )

                StatusRow(
                    title: AppStrings.statusActivityTitle,
                    value: store.activityStatusText,
                    color: activityStatusColor
                )

                StatusRow(
                    title: AppStrings.statusNetworkTitle,
                    value: store.networkStatusText,
                    color: networkStatusColor
                )

                StatusRow(
                    title: AppStrings.statusModeTitle,
                    value: store.controlMode.title,
                    color: controlModeColor
                )

                StatusRow(
                    title: AppStrings.statusLaunchAtLoginTitle,
                    value: store.launchAtLoginStatusText,
                    color: launchAtLoginColor
                )

                RunnerResourceUsageView(usage: store.runnerResourceUsage)
            }

            if let errorMessage = store.lastErrorMessage {
                Divider()

                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            HStack(spacing: 10) {
                Button(AppStrings.buttonManualStart) {
                    store.forceStart()
                }
                .buttonStyle(.borderedProminent)

                Button(AppStrings.buttonManualStop) {
                    store.forceStop()
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 10) {
                Button(AppStrings.buttonAutomaticMode) {
                    store.useAutomaticMode()
                }
                .buttonStyle(.bordered)
                .disabled(store.controlMode == .automatic)

                Button(AppStrings.buttonRefresh) {
                    store.refreshNow()
                }
                .buttonStyle(.bordered)
            }

            Divider()

            Toggle(
                AppStrings.toggleLaunchAtLogin,
                isOn: Binding(
                    get: { store.launchAtLoginEnabled },
                    set: { store.setLaunchAtLogin($0) }
                )
            )

            Divider()

            Button(AppStrings.buttonOpenSettingsWindow) {
                SettingsWindowController.shared.show(store: store)
            }

            Button(AppStrings.buttonQuit) {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    private var runnerStatusColor: Color {
        store.runnerSnapshot.isRunning ? .green : .red
    }

    private var activityStatusColor: Color {
        switch store.runnerSnapshot.activity.kind {
        case .busy:
            .orange
        case .waiting:
            .gray
        case .unknown:
            store.runnerSnapshot.isRunning ? .yellow : .red
        }
    }

    private var networkStatusColor: Color {
        switch store.networkSnapshot.kind {
        case .unmetered:
            .green
        case .expensive:
            .orange
        case .offline:
            .red
        case .unknown:
            .gray
        }
    }

    private var controlModeColor: Color {
        switch store.controlMode {
        case .automatic:
            .blue
        case .forceRunning:
            .green
        case .forceStopped:
            .red
        }
    }

    private var launchAtLoginColor: Color {
        switch store.launchAtLoginStatus {
        case .enabled:
            .green
        case .requiresApproval:
            .orange
        case .notRegistered:
            .gray
        case .notFound:
            .red
        @unknown default:
            .yellow
        }
    }
}

private struct RunnerResourceUsageView: View {
    let usage: RunnerResourceUsage

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(AppStrings.advancedViewTitle, isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                UsageRow(
                    title: AppStrings.statusRunnerTitle,
                    value: usage.isRunning ? AppStrings.runnerRunning : AppStrings.runnerStopped
                )

                UsageRow(
                    title: AppStrings.settingsAdvancedCPU,
                    value: String(format: "%.1f%%", usage.cpuPercent)
                )

                UsageRow(
                    title: AppStrings.settingsAdvancedMemory,
                    value: "\(Int(usage.memoryMB.rounded())) MB"
                )

                UsageRow(
                    title: AppStrings.settingsAdvancedJobActive,
                    value: usage.isJobActive ? AppStrings.booleanYes : AppStrings.booleanNo
                )
            }
            .padding(.top, 6)
        }
        .font(.subheadline)
    }
}

private struct UsageRow: View {
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
    }
}

private struct StatusRow: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

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
