import AppKit
import Combine

@MainActor
final class StudioModel: ObservableObject {
    @Published var restoresPreviousSession: Bool {
        didSet {
            UserDefaults.standard.set(restoresPreviousSession, forKey: DefaultsKey.restoresPreviousSession)
            if restoresPreviousSession {
                persistSession()
            } else {
                UserDefaults.standard.removeObject(forKey: DefaultsKey.savedSession)
            }
        }
    }
    @Published var outputFormat: OutputFormat = .landscape { didSet { settingsDidChange() } }
    @Published var customCanvasWidth = 1_920 {
        didSet {
            if customCanvasWidth < 1 {
                customCanvasWidth = 1
            } else {
                settingsDidChange()
            }
        }
    }
    @Published var customCanvasHeight = 1_080 {
        didSet {
            if customCanvasHeight < 1 {
                customCanvasHeight = 1
            } else {
                settingsDidChange()
            }
        }
    }
    @Published var faceEffect: FaceEffect = .none { didSet { settingsDidChange() } }
    @Published var cornerRadius: CGFloat = 48 { didSet { persistSession() } }
    @Published var isMirrored = true { didSet { settingsDidChange() } }
    @Published var facePadding: CGFloat = 0.18 { didSet { settingsDidChange() } }
    @Published var showGuides = true { didSet { persistSession() } }
    @Published var cropScale: CGFloat = 1 { didSet { settingsDidChange() } }
    @Published var cropOffset: CGSize = .zero { didSet { settingsDidChange() } }
    @Published var customCropRect = CGRect(x: 0, y: 0, width: 1, height: 1) {
        didSet { settingsDidChange() }
    }

    let camera: CameraEngine
    private var cameraSelectionCancellable: AnyCancellable?

    init() {
        let defaults = UserDefaults.standard
        let shouldRestorePreviousSession =
            defaults.object(forKey: DefaultsKey.restoresPreviousSession) as? Bool ?? true
        restoresPreviousSession = shouldRestorePreviousSession

        let savedSession = shouldRestorePreviousSession
            ? Self.loadSavedSession(from: defaults)
            : nil

        if let savedSession {
            outputFormat = OutputFormat(rawValue: savedSession.outputFormat) ?? .landscape
            customCanvasWidth = max(savedSession.customCanvasWidth, 1)
            customCanvasHeight = max(savedSession.customCanvasHeight, 1)
            faceEffect = FaceEffect(rawValue: savedSession.faceEffect) ?? .none
            cornerRadius = savedSession.cornerRadius
            isMirrored = savedSession.isMirrored
            facePadding = savedSession.facePadding
            showGuides = savedSession.showGuides
            cropScale = savedSession.cropScale
            cropOffset = CGSize(width: savedSession.cropOffsetX, height: savedSession.cropOffsetY)
            customCropRect = CGRect(
                x: savedSession.customCropRectX,
                y: savedSession.customCropRectY,
                width: savedSession.customCropRectWidth,
                height: savedSession.customCropRectHeight
            )
        }

        camera = CameraEngine(preferredDeviceID: savedSession?.selectedDeviceID)
        syncSettings()
        cameraSelectionCancellable = camera.$selectedDeviceID
            .dropFirst()
            .sink { [weak self] _ in
                self?.persistSession()
            }
    }

    var settings: FrameSettings {
        FrameSettings(
            outputAspectRatio: outputAspectRatio,
            showsCropEditor: outputFormat == .custom,
            customCropRect: outputFormat == .custom ? customCropRect : nil,
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

    private func settingsDidChange() {
        syncSettings()
        persistSession()
    }

    private func syncSettings() {
        camera.update(settings: settings)
    }

    private func persistSession() {
        guard restoresPreviousSession else { return }

        let savedSession = SavedSession(
            outputFormat: outputFormat.rawValue,
            customCanvasWidth: customCanvasWidth,
            customCanvasHeight: customCanvasHeight,
            faceEffect: faceEffect.rawValue,
            cornerRadius: cornerRadius,
            isMirrored: isMirrored,
            facePadding: facePadding,
            showGuides: showGuides,
            cropScale: cropScale,
            cropOffsetX: cropOffset.width,
            cropOffsetY: cropOffset.height,
            customCropRectX: customCropRect.origin.x,
            customCropRectY: customCropRect.origin.y,
            customCropRectWidth: customCropRect.width,
            customCropRectHeight: customCropRect.height,
            selectedDeviceID: camera.selectedDeviceID
        )

        guard let data = try? JSONEncoder().encode(savedSession) else { return }
        UserDefaults.standard.set(data, forKey: DefaultsKey.savedSession)
    }

    private static func loadSavedSession(from defaults: UserDefaults) -> SavedSession? {
        guard let data = defaults.data(forKey: DefaultsKey.savedSession) else { return nil }
        return try? JSONDecoder().decode(SavedSession.self, from: data)
    }
}

private enum DefaultsKey {
    static let restoresPreviousSession = "restoresPreviousSession"
    static let savedSession = "savedStudioSession"
}

private struct SavedSession: Codable {
    let outputFormat: String
    let customCanvasWidth: Int
    let customCanvasHeight: Int
    let faceEffect: String
    let cornerRadius: CGFloat
    let isMirrored: Bool
    let facePadding: CGFloat
    let showGuides: Bool
    let cropScale: CGFloat
    let cropOffsetX: CGFloat
    let cropOffsetY: CGFloat
    let customCropRectX: CGFloat
    let customCropRectY: CGFloat
    let customCropRectWidth: CGFloat
    let customCropRectHeight: CGFloat
    let selectedDeviceID: String?
}
