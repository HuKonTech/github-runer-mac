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
        let releasePageURL: URL
        let downloadURL: URL
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
        true
    }

    var isBusy: Bool {
        switch state {
        case .checking, .downloading, .installing:
            true
        case .idle, .upToDate, .updateAvailable, .failed:
            false
        }
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
                let downloadedDMG = try await downloadReleaseAsset(from: release.downloadURL)
                state = .installing
                try openInstaller(at: downloadedDMG)
            } catch {
                state = .failed(
                    AppStrings.updateErrorDetails(error.localizedDescription)
                )
            }
        }
    }

    func openReleasePage() {
        let url = latestRelease?.releasePageURL ?? releasesPageURL
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

        guard let releasePageURL = URL(string: decoded.htmlURL) else {
            throw UpdateError.invalidResponse
        }

        guard
            let asset = GitHubReleaseAsset.bestSupportedDMGAsset(in: decoded.assets),
            let downloadURL = URL(string: asset.browserDownloadURL)
        else {
            throw UpdateError.missingAsset
        }

        return ReleaseInfo(
            version: decoded.tagName.replacingOccurrences(of: "v", with: ""),
            releasePageURL: releasePageURL,
            downloadURL: downloadURL,
            publishedAt: decoded.publishedAt
        )
    }

    private var releasesPageURL: URL {
        URL(string: "https://github.com/\(owner)/\(repository)/releases")!
    }

    private func downloadReleaseAsset(from url: URL) async throws -> URL {
        let (tempURL, response) = try await session.download(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw UpdateError.downloadFailed
        }

        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("dmg")

        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: tempURL, to: destination)

        return destination
    }

    private func openInstaller(at url: URL) throws {
        guard NSWorkspace.shared.open(url) else {
            throw UpdateError.openInstallerFailed
        }
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

}

private enum UpdateError: LocalizedError {
    case invalidResponse
    case noPublishedRelease
    case missingAsset
    case downloadFailed
    case openInstallerFailed

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
        case .openInstallerFailed:
            AppStrings.updateErrorOpenInstaller
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

    static func bestSupportedDMGAsset(in assets: [GitHubReleaseAsset]) -> GitHubReleaseAsset? {
        assets.first(where: { $0.isCurrentArchitectureMacOSDMGAsset })
            ?? assets.first(where: { $0.isMacOSDMGAsset })
    }

    private var isCurrentArchitectureMacOSDMGAsset: Bool {
        let normalizedName = name.lowercased()
        return normalizedName.contains("-macos-\(Self.currentArchitecture)") && normalizedName.hasSuffix(".dmg")
    }

    private var isMacOSDMGAsset: Bool {
        let normalizedName = name.lowercased()
        return normalizedName.contains("-macos-") && normalizedName.hasSuffix(".dmg")
    }

    private static var currentArchitecture: String {
        #if arch(arm64)
        "arm64"
        #elseif arch(x86_64)
        "x86_64"
        #else
        ""
        #endif
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
