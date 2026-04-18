import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class AppUpdateService {
    enum UpdateState: Equatable {
        case idle
        case checking
        case upToDate
        case updateAvailable
        case downloading
        case installing
        case failed(String)
    }

    struct ReleaseInfo: Equatable {
        let version: String
        let downloadURL: URL
        let releasePageURL: URL
        let publishedAt: Date?
    }

    static let shared = AppUpdateService()

    private let owner = "HunKonTech"
    private let repository = "github-runer-mac"
    private let session = URLSession.shared

    var state: UpdateState = .idle
    var latestRelease: ReleaseInfo?
    var lastCheckedAt: Date?

    var installedVersion: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return shortVersion ?? buildVersion ?? "0.0.0"
    }

    var statusText: String {
        switch state {
        case .idle:
            return AppStrings.updateIdle
        case .checking:
            return AppStrings.updateChecking
        case .upToDate:
            return AppStrings.updateUpToDate
        case .updateAvailable:
            if let latestRelease {
                return AppStrings.updateAvailableVersion(latestRelease.version)
            }
            return AppStrings.updateAvailableFallback
        case .downloading:
            return AppStrings.updateDownloading
        case .installing:
            return AppStrings.updateInstalling
        case .failed(let message):
            return message
        }
    }

    var canInstallUpdate: Bool {
        if case .updateAvailable = state {
            return latestRelease != nil
        }

        return false
    }

    func checkForUpdates() {
        state = .checking

        Task {
            do {
                let release = try await fetchLatestRelease()
                latestRelease = release
                lastCheckedAt = Date()

                if isVersion(release.version, newerThan: installedVersion) {
                    state = .updateAvailable
                } else {
                    state = .upToDate
                }
            } catch {
                state = .failed(
                    AppStrings.updateErrorDetails(error.localizedDescription)
                )
            }
        }
    }

    func installLatestUpdate() {
        guard let release = latestRelease else {
            state = .failed(AppStrings.updateErrorNoRelease)
            return
        }

        state = .downloading

        Task {
            do {
                let downloadedZip = try await downloadReleaseAsset(from: release.downloadURL)
                state = .installing
                try stageAndInstall(zipURL: downloadedZip)
            } catch {
                state = .failed(
                    AppStrings.updateErrorDetails(error.localizedDescription)
                )
            }
        }
    }

    func openReleasePage() {
        guard let url = latestRelease?.releasePageURL else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    private func fetchLatestRelease() async throws -> ReleaseInfo {
        let apiURL = URL(string: "https://api.github.com/repos/\(owner)/\(repository)/releases/latest")!
        var request = URLRequest(url: apiURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("GitHubRunnerMenu", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateError.invalidResponse
        }

        if httpResponse.statusCode == 404 {
            throw UpdateError.noPublishedRelease
        }

        guard httpResponse.statusCode == 200 else {
            throw UpdateError.invalidResponse
        }

        let decoded = try JSONDecoder.github.decode(GitHubReleaseResponse.self, from: data)

        guard
            let asset = decoded.assets.first(where: {
                $0.isSupportedMacOSZipAsset
            }),
            let downloadURL = URL(string: asset.browserDownloadURL),
            let releasePageURL = URL(string: decoded.htmlURL)
        else {
            throw UpdateError.missingAsset
        }

        return ReleaseInfo(
            version: decoded.tagName.replacingOccurrences(of: "v", with: ""),
            downloadURL: downloadURL,
            releasePageURL: releasePageURL,
            publishedAt: decoded.publishedAt
        )
    }

    private func downloadReleaseAsset(from url: URL) async throws -> URL {
        let (tempURL, response) = try await session.download(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw UpdateError.downloadFailed
        }

        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("zip")

        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: tempURL, to: destination)

        return destination
    }

    private func stageAndInstall(zipURL: URL) throws {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("github-runner-update-\(UUID().uuidString)", isDirectory: true)
        let unzipDirectory = tempRoot.appendingPathComponent("unzipped", isDirectory: true)

        try FileManager.default.createDirectory(at: unzipDirectory, withIntermediateDirectories: true)

        let unzipResult = try Shell.run(
            executable: URL(fileURLWithPath: "/usr/bin/ditto"),
            arguments: ["-x", "-k", zipURL.path, unzipDirectory.path]
        )

        guard unzipResult.status == 0 else {
            throw UpdateError.unzipFailed(unzipResult.stderr)
        }

        let newBundleURL = try locateAppBundle(in: unzipDirectory)
        let currentBundleURL = Bundle.main.bundleURL.standardizedFileURL

        guard currentBundleURL.pathExtension == "app" else {
            throw UpdateError.invalidCurrentBundle
        }

        let updaterScriptURL = tempRoot.appendingPathComponent("install_update.sh")
        let script = """
        #!/bin/bash
        set -euo pipefail
        APP_PATH=\(shellQuote(currentBundleURL.path))
        NEW_APP_PATH=\(shellQuote(newBundleURL.path))
        while kill -0 \(ProcessInfo.processInfo.processIdentifier) >/dev/null 2>&1; do
          sleep 1
        done
        rm -rf "$APP_PATH"
        cp -R "$NEW_APP_PATH" "$APP_PATH"
        open -n "$APP_PATH"
        """

        try script.write(to: updaterScriptURL, atomically: true, encoding: .utf8)

        let chmodResult = try Shell.run(
            executable: URL(fileURLWithPath: "/bin/chmod"),
            arguments: ["+x", updaterScriptURL.path]
        )

        guard chmodResult.status == 0 else {
            throw UpdateError.installFailed(chmodResult.stderr)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "nohup \(shellQuote(updaterScriptURL.path)) >/dev/null 2>&1 &"]
        try process.run()

        NSApp.terminate(nil)
    }

    private func locateAppBundle(in directory: URL) throws -> URL {
        guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil) else {
            throw UpdateError.missingBundle
        }

        for case let url as URL in enumerator {
            if url.pathExtension == "app" {
                return url
            }
        }

        throw UpdateError.missingBundle
    }

    private func isVersion(_ lhs: String, newerThan rhs: String) -> Bool {
        let left = normalizedVersionComponents(lhs)
        let right = normalizedVersionComponents(rhs)
        let maxCount = max(left.count, right.count)

        for index in 0..<maxCount {
            let leftValue = index < left.count ? left[index] : 0
            let rightValue = index < right.count ? right[index] : 0

            if leftValue != rightValue {
                return leftValue > rightValue
            }
        }

        return false
    }

    private func normalizedVersionComponents(_ version: String) -> [Int] {
        version
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "v", with: "")
            .split(separator: ".")
            .map { Int($0) ?? 0 }
    }

    private func shellQuote(_ text: String) -> String {
        "'\(text.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}

private enum UpdateError: LocalizedError {
    case invalidResponse
    case noPublishedRelease
    case missingAsset
    case downloadFailed
    case unzipFailed(String)
    case missingBundle
    case invalidCurrentBundle
    case installFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            AppStrings.updateErrorInvalidResponse
        case .noPublishedRelease:
            AppStrings.updateErrorNoPublishedRelease
        case .missingAsset:
            AppStrings.updateErrorMissingAsset
        case .downloadFailed:
            AppStrings.updateErrorDownload
        case .unzipFailed(let details):
            AppStrings.updateErrorUnzip(details)
        case .missingBundle:
            AppStrings.updateErrorMissingBundle
        case .invalidCurrentBundle:
            AppStrings.updateErrorInvalidBundle
        case .installFailed(let details):
            AppStrings.updateErrorInstall(details)
        }
    }
}

private struct GitHubReleaseResponse: Decodable {
    let tagName: String
    let htmlURL: String
    let publishedAt: Date?
    let assets: [GitHubReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case publishedAt = "published_at"
        case assets
    }
}

private struct GitHubReleaseAsset: Decodable {
    let name: String
    let browserDownloadURL: String

    var isSupportedMacOSZipAsset: Bool {
        let normalizedName = name.lowercased()
        return normalizedName.contains("-macos-arm64") && normalizedName.hasSuffix(".zip")
    }

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}

private extension JSONDecoder {
    static let github: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
