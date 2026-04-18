import Foundation

enum RunnerControlMode: String, CaseIterable {
    case automatic
    case forceRunning
    case forceStopped

    var title: String {
        switch self {
        case .automatic:
            AppStrings.controlModeAutomatic
        case .forceRunning:
            AppStrings.controlModeForceRunning
        case .forceStopped:
            AppStrings.controlModeForceStopped
        }
    }
}

enum NetworkConditionKind {
    case offline
    case expensive
    case unmetered
    case unknown
}

struct NetworkConditionSnapshot {
    var kind: NetworkConditionKind
    var description: String

    var automaticDecision: AutomaticDecision {
        switch kind {
        case .unmetered:
            .run
        case .offline, .expensive:
            .stop
        case .unknown:
            .keep
        }
    }

    static let unknown = NetworkConditionSnapshot(
        kind: .unknown,
        description: AppStrings.networkChecking
    )

    enum AutomaticDecision {
        case run
        case stop
        case keep
    }
}

enum RunnerActivityKind {
    case busy
    case waiting
    case unknown
}

struct RunnerActivitySnapshot {
    var kind: RunnerActivityKind
    var description: String

    static let stopped = RunnerActivitySnapshot(
        kind: .unknown,
        description: AppStrings.activityRunnerStopped
    )

    static let unknown = RunnerActivitySnapshot(
        kind: .unknown,
        description: AppStrings.activityUnknown
    )
}

struct RunnerSnapshot {
    var isRunning: Bool
    var activity: RunnerActivitySnapshot

    static let stopped = RunnerSnapshot(
        isRunning: false,
        activity: .stopped
    )
}
