import AppKit
import Foundation
import Observation
import OSLog
import ServiceManagement

@MainActor
@Observable
final class RunnerMenuStore {
    private static let controlModeDefaultsKey = "RunnerControlMode"

    @ObservationIgnored private let controller: RunnerController
    @ObservationIgnored private let networkMonitor = NetworkConditionMonitor()
    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private let logger = Logger(
        subsystem: "com.koncsik.githubrunnermenu",
        category: "store"
    )

    var controlMode: RunnerControlMode
    var launchAtLoginStatus: SMAppService.Status
    var networkSnapshot: NetworkConditionSnapshot = .unknown
    var runnerSnapshot: RunnerSnapshot = .stopped
    var lastErrorMessage: String?

    init(
        runnerDirectory: URL = URL(
            fileURLWithPath: "/Users/koncsikbenedek/GitHub/actions-runner",
            isDirectory: true
        )
    ) {
        controller = RunnerController(runnerDirectory: runnerDirectory)

        if
            let rawValue = UserDefaults.standard.string(forKey: Self.controlModeDefaultsKey),
            let savedMode = RunnerControlMode(rawValue: rawValue)
        {
            controlMode = savedMode
        } else {
            controlMode = .automatic
        }

        launchAtLoginStatus = SMAppService.mainApp.status

        startMonitoring()
    }

    var menuBarSymbolName: String {
        if runnerSnapshot.isRunning {
            switch runnerSnapshot.activity.kind {
            case .busy:
                "hammer.circle.fill"
            case .waiting, .unknown:
                "play.circle.fill"
            }
        } else {
            "pause.circle.fill"
        }
    }

    var runnerStatusText: String {
        runnerSnapshot.isRunning ? AppStrings.runnerRunning : AppStrings.runnerStopped
    }

    var activityStatusText: String {
        runnerSnapshot.activity.description
    }

    var networkStatusText: String {
        networkSnapshot.description
    }

    var policySummary: String {
        switch controlMode {
        case .automatic:
            switch networkSnapshot.kind {
            case .unmetered:
                AppStrings.policyAutomaticRun
            case .expensive:
                AppStrings.policyAutomaticExpensive
            case .offline:
                AppStrings.policyAutomaticOffline
            case .unknown:
                AppStrings.policyAutomaticUnknown
            }
        case .forceRunning:
            AppStrings.policyForceRunning
        case .forceStopped:
            AppStrings.policyForceStopped
        }
    }

    var runnerPathDisplay: String {
        controller.runnerDirectory.path
    }

    var launchAtLoginEnabled: Bool {
        switch launchAtLoginStatus {
        case .enabled, .requiresApproval:
            true
        case .notRegistered, .notFound:
            false
        @unknown default:
            false
        }
    }

    var launchAtLoginStatusText: String {
        switch launchAtLoginStatus {
        case .enabled:
            AppStrings.launchAtLoginEnabled
        case .requiresApproval:
            AppStrings.launchAtLoginRequiresApproval
        case .notRegistered:
            AppStrings.launchAtLoginDisabled
        case .notFound:
            AppStrings.launchAtLoginUnavailable
        @unknown default:
            AppStrings.launchAtLoginUnknown
        }
    }

    func refreshNow() {
        reconcileState(trigger: "manual refresh")
    }

    func useAutomaticMode() {
        setControlMode(.automatic, trigger: "automatic mode")
    }

    func forceStart() {
        setControlMode(.forceRunning, trigger: "manual start")
    }

    func forceStop() {
        setControlMode(.forceStopped, trigger: "manual stop")
    }

    func openRunnerDirectory() {
        NSWorkspace.shared.open(controller.runnerDirectory)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }

            lastErrorMessage = nil
        } catch {
            lastErrorMessage = AppStrings.errorLaunchAtLoginUpdate(
                reason: error.localizedDescription
            )
        }

        refreshLaunchAtLoginStatus()
    }

    func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    private func startMonitoring() {
        networkMonitor.onChange = { [weak self] snapshot in
            Task { @MainActor [weak self] in
                guard let self else {
                    return
                }

                self.logger.info("Network changed: \(snapshot.description, privacy: .public)")
                self.networkSnapshot = snapshot
                self.reconcileState(trigger: "network change")
            }
        }

        networkMonitor.start()

        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                await MainActor.run {
                    self.performPeriodicRefresh()
                }
            }
        }

        reconcileState(trigger: "launch")
    }

    private func setControlMode(_ mode: RunnerControlMode, trigger: String) {
        controlMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: Self.controlModeDefaultsKey)
        reconcileState(trigger: trigger)
    }

    private func reconcileState(trigger: String) {
        refreshLaunchAtLoginStatus()
        logger.info(
            "Reconciling state from \(trigger, privacy: .public); mode=\(String(describing: self.controlMode), privacy: .public) network=\(self.networkSnapshot.description, privacy: .public)"
        )

        do {
            try applyDesiredRunnerState()
            lastErrorMessage = nil
        } catch {
            logger.error("Runner handling failed: \(error.localizedDescription, privacy: .public)")
            lastErrorMessage = AppStrings.errorRunnerHandling(
                reason: error.localizedDescription
            )
        }

        var latestSnapshot = controller.currentSnapshot()

        if latestSnapshot.isRunning && latestSnapshot.activity.kind == .unknown {
            if runnerSnapshot.isRunning && runnerSnapshot.activity.kind != .unknown {
                latestSnapshot.activity = runnerSnapshot.activity
            } else {
                latestSnapshot.activity = RunnerActivitySnapshot(
                    kind: .waiting,
                    description: AppStrings.activityWaitingOrStarting
                )
            }
        }

        runnerSnapshot = latestSnapshot
        logger.info(
            "Runner snapshot updated; running=\(self.runnerSnapshot.isRunning) activity=\(self.runnerSnapshot.activity.description, privacy: .public)"
        )
    }

    private func applyDesiredRunnerState() throws {
        switch controlMode {
        case .automatic:
            switch networkSnapshot.automaticDecision {
            case .run:
                try controller.startIfNeeded()
            case .stop:
                controller.stopIfNeeded()
            case .keep:
                break
            }
        case .forceRunning:
            try controller.startIfNeeded()
        case .forceStopped:
            controller.stopIfNeeded()
        }
    }

    private func refreshLaunchAtLoginStatus() {
        launchAtLoginStatus = SMAppService.mainApp.status
    }

    @MainActor
    private func performPeriodicRefresh() {
        reconcileState(trigger: "periodic refresh")
    }
}
