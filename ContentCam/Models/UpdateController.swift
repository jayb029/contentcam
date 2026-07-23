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
            "https://github.com/jayb029/mac-native-content-camera/releases/latest/download/appcast.xml"
        case .nightly:
            "https://github.com/jayb029/mac-native-content-camera/releases/download/nightly/appcast-nightly.xml"
        }
    }
}

final class UpdateController: NSObject, ObservableObject, SPUUpdaterDelegate {
    @Published private(set) var channel: UpdateChannel
    @Published private(set) var canCheckForUpdates = false

    private var updaterController: SPUStandardUpdaterController!
    private var hasStarted = false
    override init() {
        let storedChannel = UserDefaults.standard.string(forKey: UpdateChannel.defaultsKey)
            .flatMap(UpdateChannel.init(rawValue:))
        channel = storedChannel ?? .production

        super.init()

        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: RunLoop.main)
            .assign(to: &$canCheckForUpdates)
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        updaterController.startUpdater()
    }

    func select(_ channel: UpdateChannel) {
        guard self.channel != channel else { return }
        self.channel = channel
        UserDefaults.standard.set(channel.rawValue, forKey: UpdateChannel.defaultsKey)
        if hasStarted {
            updaterController.updater.resetUpdateCycleAfterShortDelay()
        }
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    func feedURLString(for updater: SPUUpdater) -> String? {
        channel.feedURLString
    }
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
