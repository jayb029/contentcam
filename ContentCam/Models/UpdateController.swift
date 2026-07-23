import Combine
import Sparkle
import SwiftUI

enum UpdateChannel: String, CaseIterable, Identifiable {
    case production
    case nightly

    static let defaultsKey = "ContentCamUpdateChannel"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .production: "Production updates"
        case .nightly: "Nightly updates"
        }
    }

    var detail: String {
        switch self {
        case .production: "Stable releases intended for everyday use."
        case .nightly: "The newest in-progress build. It may be less stable."
        }
    }

    fileprivate var feedURLString: String {
        switch self {
        case .production:
            "https://github.com/jayb029/contentcam/releases/latest/download/appcast.xml"
        case .nightly:
            "https://raw.githubusercontent.com/jayb029/contentcam/nightly-feed/appcast-nightly.xml"
        }
    }
}

final class UpdateController: NSObject, ObservableObject, SPUUpdaterDelegate, SPUStandardUserDriverDelegate {
    private static let automaticCheckInterval: TimeInterval = 30 * 60

    @Published private(set) var channel: UpdateChannel
    @Published private(set) var canCheckForUpdates = false

    private var updaterController: SPUStandardUpdaterController!
    private var automaticCheckTimer: AnyCancellable?
    private var hasStarted = false
    override init() {
        let storedChannel = UserDefaults.standard.string(forKey: UpdateChannel.defaultsKey)
            .flatMap(UpdateChannel.init(rawValue:))
        channel = storedChannel ?? .production

        super.init()

        InMemoryLog.shared.info("Updater initialized on the \(channel.rawValue) channel", category: "Updates")

        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: self,
            userDriverDelegate: self
        )
        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: RunLoop.main)
            .assign(to: &$canCheckForUpdates)
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        InMemoryLog.shared.info("Updater started", category: "Updates")
        updaterController.startUpdater()
        checkForUpdatesInBackground()
        automaticCheckTimer = Timer.publish(
            every: Self.automaticCheckInterval,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in
            self?.checkForUpdatesInBackground()
        }
    }

    func select(_ channel: UpdateChannel) {
        guard self.channel != channel else { return }
        self.channel = channel
        InMemoryLog.shared.info("Update channel changed to \(channel.rawValue)", category: "Updates")
        UserDefaults.standard.set(channel.rawValue, forKey: UpdateChannel.defaultsKey)
        if hasStarted {
            updaterController.updater.resetUpdateCycleAfterShortDelay()
        }
    }

    func checkForUpdates() {
        InMemoryLog.shared.info("Manual update check requested", category: "Updates")
        updaterController.checkForUpdates(nil)
    }

    private func checkForUpdatesInBackground() {
        InMemoryLog.shared.info("Automatic update check requested", category: "Updates")
        updaterController.updater.checkForUpdatesInBackground()
    }

    func feedURLString(for updater: SPUUpdater) -> String? {
        channel.feedURLString
    }

    func standardUserDriverShowVersionHistory(for item: SUAppcastItem) {
        InMemoryLog.shared.info("Changelog opened from update check", category: "Updates")
        NotificationCenter.default.post(name: .showContentCamChangelog, object: nil)
    }
}

extension Notification.Name {
    static let showContentCamChangelog = Notification.Name("ShowContentCamChangelog")
}

struct CheckForUpdatesCommand: View {
    @ObservedObject var updates: UpdateController

    var body: some View {
        Button("Check for Updates…") {
            updates.checkForUpdates()
        }
        .disabled(!updates.canCheckForUpdates)
    }
}
