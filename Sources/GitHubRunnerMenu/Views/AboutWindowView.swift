import SwiftUI

struct AboutWindowView: View {
    private let githubURL = URL(string: "https://github.com/BenKoncsik")!
    private let xURL = URL(string: "https://x.com/BenedekKoncsik")!
    private let repositoryURL = URL(string: "https://github.com/BenKoncsik/github-runer-mac")!

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(AppStrings.aboutWindowTitle)
                    .font(.title2.weight(.semibold))

                Text(AppStrings.aboutDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 12) {
                Link(AppStrings.buttonOpenAuthorGitHub, destination: githubURL)
                    .buttonStyle(.borderedProminent)

                Link(AppStrings.buttonOpenAuthorX, destination: xURL)
                    .buttonStyle(.bordered)

                Link(AppStrings.buttonOpenRepository, destination: repositoryURL)
                    .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(minWidth: 420, idealWidth: 460, minHeight: 220)
    }
}
