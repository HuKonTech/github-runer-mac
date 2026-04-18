import Darwin
import Foundation
import OSLog

final class RunnerController: @unchecked Sendable {
    let runnerDirectory: URL

    private let runScriptName = "run.sh"
    private var managedProcess: Process?
    private let logger = Logger(
        subsystem: "com.koncsik.githubrunnermenu",
        category: "runner"
    )

    init(runnerDirectory: URL) {
        self.runnerDirectory = runnerDirectory
    }

    func currentSnapshot() -> RunnerSnapshot {
        let isRunning = isRunnerRunning()
        let activity = isRunning
            ? RunnerLogParser.latestActivity(in: runnerDirectory)
            : .stopped

        return RunnerSnapshot(
            isRunning: isRunning,
            activity: activity
        )
    }

    func startIfNeeded() throws {
        guard !isRunnerRunning() else {
            logger.info("Runner start skipped because it is already running.")
            return
        }

        let runScriptURL = runnerDirectory.appendingPathComponent(runScriptName)

        guard FileManager.default.fileExists(atPath: runScriptURL.path) else {
            throw RunnerControllerError.missingRunnerScript(runScriptURL.path)
        }

        let process = Process()
        process.currentDirectoryURL = runnerDirectory
        process.executableURL = runScriptURL
        process.environment = runnerEnvironment()
        process.standardInput = try FileHandle(forReadingFrom: URL(fileURLWithPath: "/dev/null"))
        process.standardOutput = try FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        process.standardError = try FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.managedProcess = nil
            }
        }

        try process.run()
        managedProcess = process
        logger.info("Runner process started from \(runScriptURL.path, privacy: .public)")
    }

    func stopIfNeeded() {
        if let managedProcess, managedProcess.isRunning {
            managedProcess.interrupt()
        }

        let processIDs = runnerProcesses().map(\.pid)

        logger.info("Stopping runner processes: \(String(describing: processIDs), privacy: .public)")

        send(signal: SIGINT, to: processIDs)
        waitForProcessesToExit()

        let remainingAfterInterrupt = runnerProcesses().map(\.pid)
        send(signal: SIGTERM, to: remainingAfterInterrupt)
        waitForProcessesToExit()

        let remainingAfterTerminate = runnerProcesses().map(\.pid)
        send(signal: SIGKILL, to: remainingAfterTerminate)
    }

    private func isRunnerRunning() -> Bool {
        (managedProcess?.isRunning ?? false) || !runnerProcesses().isEmpty
    }

    private func runnerProcesses() -> [RunnerProcessInfo] {
        guard let result = try? Shell.run(
            executable: URL(fileURLWithPath: "/bin/ps"),
            arguments: ["-axo", "pid=,command="]
        ) else {
            return []
        }

        guard result.status == 0 else {
            return []
        }

        return result.stdout
            .split(whereSeparator: \.isNewline)
            .compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else {
                    return nil
                }

                let pieces = trimmed.split(
                    maxSplits: 1,
                    whereSeparator: { $0.isWhitespace }
                )

                guard
                    pieces.count == 2,
                    let pid = Int32(pieces[0])
                else {
                    return nil
                }

                let command = String(pieces[1])
                let isMatch = matchesRunnerProcess(command: command)

                guard isMatch else {
                    return nil
                }

                return RunnerProcessInfo(pid: pid, command: command)
            }
    }

    private func runnerEnvironment() -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        environment["RUNNER_MANUALLY_TRAP_SIG"] = "1"
        return environment
    }

    private func matchesRunnerProcess(command: String) -> Bool {
        let runnerPath = runnerDirectory.path
        let runScript = "\(runnerPath)/run.sh"
        let runHelper = "\(runnerPath)/run-helper.sh"
        let listener = "\(runnerPath)/bin/Runner.Listener"

        return
            command == runScript ||
            command == runHelper ||
            command == listener ||
            command.hasPrefix("/bin/bash \(runScript)") ||
            command.hasPrefix("/bin/bash \(runHelper)") ||
            command.hasPrefix("/bin/sh \(runScript)") ||
            command.hasPrefix("/bin/sh \(runHelper)") ||
            command.hasPrefix("\(listener) ")
    }

    private func send(signal: Int32, to processIDs: [Int32]) {
        for pid in processIDs {
            _ = kill(pid, signal)
        }
    }

    private func waitForProcessesToExit() {
        Thread.sleep(forTimeInterval: 0.4)
    }
}

private struct RunnerProcessInfo {
    let pid: Int32
    let command: String
}

private enum RunnerControllerError: LocalizedError {
    case missingRunnerScript(String)

    var errorDescription: String? {
        switch self {
        case .missingRunnerScript(let path):
            AppStrings.errorMissingRunnerScript(path: path)
        }
    }
}
