import Foundation
import SwiftUI

struct ChangelogView: View {
    @StateObject private var changelog = ChangelogController()

    var body: some View {
        HSplitView {
            releaseList
                .frame(minWidth: 220, idealWidth: 250, maxWidth: 300)

            releaseDetail
                .frame(minWidth: 460, maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 720, minHeight: 520)
        .task {
            await changelog.loadIfNeeded()
        }
    }

    private var releaseList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Changelog")
                    .font(.title2.weight(.semibold))

                Spacer()

                Button {
                    Task {
                        await changelog.reload()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh Changelog")
                .disabled(changelog.isLoading)
            }
            .padding()

            Divider()

            Group {
                if changelog.releases.isEmpty {
                    changelogStatus
                } else {
                    List(changelog.releases, selection: $changelog.selectedReleaseID) { release in
                        ChangelogReleaseRow(release: release)
                            .tag(release.id)
                    }
                    .listStyle(.sidebar)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var changelogStatus: some View {
        if changelog.isLoading {
            ProgressView("Loading updates…")
                .controlSize(.small)
        } else if let errorMessage = changelog.errorMessage {
            ContentUnavailableView {
                Label("Changelog Unavailable", systemImage: "wifi.exclamationmark")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("Try Again") {
                    Task {
                        await changelog.reload()
                    }
                }
            }
        } else {
            ContentUnavailableView(
                "No Releases Yet",
                systemImage: "clock.arrow.circlepath",
                description: Text("Published ContentCam updates will appear here.")
            )
        }
    }

    @ViewBuilder
    private var releaseDetail: some View {
        if let release = changelog.selectedRelease {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(release.displayName)
                                .font(.largeTitle.weight(.semibold))

                            Text(release.channelTitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(release.isPrerelease ? .orange : .blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    (release.isPrerelease ? Color.orange : Color.blue)
                                        .opacity(0.12),
                                    in: Capsule()
                                )
                        }

                        HStack(spacing: 6) {
                            Text(release.tagName)
                            if let publishedDate = release.publishedDate {
                                Text("•")
                                Text(publishedDate.formatted(date: .abbreviated, time: .omitted))
                            }
                        }
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    }

                    Divider()

                    if release.body.isEmpty {
                        Text("No release notes were published for this update.")
                            .foregroundStyle(.secondary)
                    } else {
                        MarkdownDocumentView(markdown: release.body)
                    }

                    Divider()

                    Link("View this release on GitHub", destination: release.htmlURL)
                }
                .padding(28)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .textSelection(.enabled)
        } else {
            ContentUnavailableView(
                "Select an Update",
                systemImage: "doc.text.magnifyingglass",
                description: Text("Choose a release to read its changelog.")
            )
        }
    }
}

private struct ChangelogReleaseRow: View {
    let release: ChangelogRelease

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(release.displayName)
                .fontWeight(.medium)
                .lineLimit(2)

            HStack(spacing: 5) {
                Text(release.channelTitle)
                if let publishedDate = release.publishedDate {
                    Text("•")
                    Text(publishedDate.formatted(date: .abbreviated, time: .omitted))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }
}

struct MarkdownDocumentView: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(markdown.components(separatedBy: .newlines).enumerated()), id: \.offset) { _, line in
                markdownLine(line)
            }
        }
    }

    @ViewBuilder
    private func markdownLine(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            Spacer()
                .frame(height: 4)
        } else if let heading = heading(in: trimmed) {
            inlineMarkdown(heading.text)
                .font(heading.level == 1 ? .title2.weight(.semibold) : .headline)
                .padding(.top, heading.level == 1 ? 8 : 4)
        } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("•")
                inlineMarkdown(String(trimmed.dropFirst(2)))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, 4)
        } else {
            inlineMarkdown(trimmed)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func heading(in line: String) -> (level: Int, text: String)? {
        let prefixLength = line.prefix(while: { $0 == "#" }).count
        guard (1...6).contains(prefixLength),
              line.dropFirst(prefixLength).first == " "
        else {
            return nil
        }

        return (prefixLength, String(line.dropFirst(prefixLength + 1)))
    }

    private func inlineMarkdown(_ source: String) -> Text {
        guard let attributed = try? AttributedString(
            markdown: source,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) else {
            return Text(source)
        }

        return Text(attributed)
    }
}

private struct ChangelogRelease: Decodable, Identifiable {
    let id: Int64
    let name: String?
    let tagName: String
    let body: String
    let isPrerelease: Bool
    let publishedAt: String?
    let htmlURL: URL

    var displayName: String {
        guard let name, !name.isEmpty else { return tagName }
        return name
    }

    var channelTitle: String {
        isPrerelease ? "Nightly" : "Production"
    }

    var publishedDate: Date? {
        guard let publishedAt else { return nil }
        return ISO8601DateFormatter().date(from: publishedAt)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case tagName = "tag_name"
        case body
        case isPrerelease = "prerelease"
        case publishedAt = "published_at"
        case htmlURL = "html_url"
    }
}

@MainActor
private final class ChangelogController: ObservableObject {
    @Published private(set) var releases: [ChangelogRelease] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var selectedReleaseID: ChangelogRelease.ID?

    var selectedRelease: ChangelogRelease? {
        releases.first { $0.id == selectedReleaseID }
    }

    func loadIfNeeded() async {
        guard releases.isEmpty, !isLoading else { return }
        await reload()
    }

    func reload() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            var request = URLRequest(
                url: URL(string: "https://api.github.com/repos/jayb029/contentcam/releases?per_page=30")!
            )
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("ContentCam", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                throw ChangelogError.invalidResponse
            }

            let decodedReleases = try JSONDecoder().decode([ChangelogRelease].self, from: data)
            releases = decodedReleases

            if !decodedReleases.contains(where: { $0.id == selectedReleaseID }) {
                selectedReleaseID = decodedReleases.first?.id
            }

            InMemoryLog.shared.info(
                "Loaded \(decodedReleases.count) changelog entries",
                category: "Updates"
            )
        } catch {
            errorMessage = "Check your internet connection and try again."
            InMemoryLog.shared.error(
                "Could not load the changelog: \(error.localizedDescription)",
                category: "Updates"
            )
        }
    }
}

private enum ChangelogError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        "GitHub returned an unexpected response."
    }
}
