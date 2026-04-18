import Foundation
import Network
import OSLog

final class NetworkConditionMonitor: @unchecked Sendable {
    var onChange: (@Sendable (NetworkConditionSnapshot) -> Void)?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "github.runner.menu.network")
    private var isStarted = false
    private let logger = Logger(
        subsystem: "com.koncsik.githubrunnermenu",
        category: "network"
    )

    func start() {
        guard !isStarted else {
            return
        }

        isStarted = true

        monitor.pathUpdateHandler = { [weak self] path in
            let snapshot = Self.snapshot(from: path)
            let callback = self?.onChange
            self?.logger.info("Monitor produced snapshot: \(snapshot.description, privacy: .public)")

            DispatchQueue.main.async {
                callback?(snapshot)
            }
        }

        monitor.start(queue: queue)
    }

    func stop() {
        guard isStarted else {
            return
        }

        monitor.cancel()
        isStarted = false
    }

    private static func snapshot(from path: NWPath) -> NetworkConditionSnapshot {
        let interfaceDescription = activeInterfaceDescription(for: path)

        guard path.status == .satisfied else {
            return NetworkConditionSnapshot(
                kind: .offline,
                description: AppStrings.networkNoInternet
            )
        }

        if path.isExpensive {
            return NetworkConditionSnapshot(
                kind: .expensive,
                description: AppStrings.networkMetered(interface: interfaceDescription)
            )
        }

        return NetworkConditionSnapshot(
            kind: .unmetered,
            description: AppStrings.networkUnmetered(interface: interfaceDescription)
        )
    }

    private static func activeInterfaceDescription(for path: NWPath) -> String {
        if path.usesInterfaceType(.wiredEthernet) {
            return AppStrings.interfaceEthernet
        }

        if path.usesInterfaceType(.wifi) {
            return AppStrings.interfaceWiFi
        }

        if path.usesInterfaceType(.cellular) {
            return AppStrings.interfaceCellular
        }

        if path.usesInterfaceType(.other) {
            return AppStrings.interfaceOther
        }

        return AppStrings.interfaceGeneric
    }
}
