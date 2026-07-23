import AppKit
import Combine

@MainActor
final class StudioModel: ObservableObject {
    @Published var outputFormat: OutputFormat = .landscape { didSet { syncSettings() } }
    @Published var customCanvasWidth = 1_920 {
        didSet {
            customCanvasWidth = max(customCanvasWidth, 1)
            syncSettings()
        }
    }
    @Published var customCanvasHeight = 1_080 {
        didSet {
            customCanvasHeight = max(customCanvasHeight, 1)
            syncSettings()
        }
    }
    @Published var faceEffect: FaceEffect = .none { didSet { syncSettings() } }
    @Published var cornerRadius: CGFloat = 48
    @Published var isMirrored = true { didSet { syncSettings() } }
    @Published var facePadding: CGFloat = 0.18 { didSet { syncSettings() } }
    @Published var showGuides = true
    @Published var cropScale: CGFloat = 1 { didSet { syncSettings() } }
    @Published var cropOffset: CGSize = .zero { didSet { syncSettings() } }

    let camera = CameraEngine()

    init() {
        syncSettings()
    }

    var settings: FrameSettings {
        FrameSettings(
            outputAspectRatio: outputAspectRatio,
            faceEffect: faceEffect,
            isMirrored: isMirrored,
            facePadding: facePadding,
            cropScale: cropScale,
            cropOffset: cropOffset
        )
    }

    var outputAspectRatio: CGFloat {
        guard outputFormat == .custom else { return outputFormat.aspectRatio }
        return CGFloat(max(customCanvasWidth, 1)) / CGFloat(max(customCanvasHeight, 1))
    }

    var outputRatioLabel: String {
        outputFormat == .custom
            ? "\(customCanvasWidth) × \(customCanvasHeight)"
            : outputFormat.ratioLabel
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
