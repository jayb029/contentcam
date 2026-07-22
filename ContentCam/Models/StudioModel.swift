import AppKit
import Combine

@MainActor
final class StudioModel: ObservableObject {
    @Published var outputFormat: OutputFormat = .landscape { didSet { syncSettings() } }
    @Published var faceEffect: FaceEffect = .none { didSet { syncSettings() } }
    @Published var cornerRadius: CGFloat = 48
    @Published var isMirrored = true { didSet { syncSettings() } }
    @Published var facePadding: CGFloat = 0.18 { didSet { syncSettings() } }
    @Published var showGuides = true

    let camera = CameraEngine()

    init() {
        syncSettings()
    }

    var settings: FrameSettings {
        FrameSettings(
            outputFormat: outputFormat,
            faceEffect: faceEffect,
            isMirrored: isMirrored,
            facePadding: facePadding
        )
    }

    func start() {
        syncSettings()
        camera.start()
    }

    func stop() {
        camera.stop()
    }

    private func syncSettings() {
        camera.update(settings: settings)
    }
}
