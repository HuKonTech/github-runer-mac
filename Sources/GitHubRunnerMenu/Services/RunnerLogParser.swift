import Foundation

enum RunnerLogParser {
    static func latestActivity(in runnerDirectory: URL) -> RunnerActivitySnapshot {
        guard
            let logURL = latestRunnerLogURL(in: runnerDirectory),
            let contents = try? String(contentsOf: logURL, encoding: .utf8)
        else {
            return .unknown
        }

        var latestActivity = RunnerActivitySnapshot.unknown

        for line in contents.split(whereSeparator: \.isNewline) {
            let text = String(line)

            if let jobName = extractJobName(from: text) {
                latestActivity = RunnerActivitySnapshot(
                    kind: .busy,
                    description: AppStrings.activityWorking(jobName: jobName)
                )
                continue
            }

            if text.contains("Listening for Jobs") {
                latestActivity = RunnerActivitySnapshot(
                    kind: .waiting,
                    description: AppStrings.activityWaitingForJob
                )
                continue
            }

            if text.contains(" completed with result:") {
                latestActivity = RunnerActivitySnapshot(
                    kind: .waiting,
                    description: AppStrings.activityWaitingForJob
                )
                continue
            }

            if text.contains("Exiting...") {
                latestActivity = RunnerActivitySnapshot(
                    kind: .unknown,
                    description: AppStrings.activityStopping
                )
            }
        }

        return latestActivity
    }

    private static func latestRunnerLogURL(in runnerDirectory: URL) -> URL? {
        let diagnosticsDirectory = runnerDirectory.appendingPathComponent(
            "_diag",
            isDirectory: true
        )

        guard
            let fileURLs = try? FileManager.default.contentsOfDirectory(
                at: diagnosticsDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return nil
        }

        return fileURLs
            .filter { $0.lastPathComponent.hasPrefix("Runner_") && $0.pathExtension == "log" }
            .sorted { lhs, rhs in
                let lhsDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let rhsDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return lhsDate > rhsDate
            }
            .first
    }

    private static func extractJobName(from line: String) -> String? {
        let marker = "Running job: "

        guard let range = line.range(of: marker) else {
            return nil
        }

        return String(line[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
