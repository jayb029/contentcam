import AVFoundation
import AppKit
import CoreMedia

final class CameraEngine: NSObject, ObservableObject {
    enum CameraState: Equatable {
        case idle
        case requestingPermission
        case running
        case denied
        case failed(String)
    }

    @Published private(set) var image: CGImage?
    @Published private(set) var state: CameraState = .idle
    @Published private(set) var devices: [AVCaptureDevice] = []
    @Published var selectedDeviceID: String?

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.jay.contentcam.capture-session")
    private let frameQueue = DispatchQueue(label: "com.jay.contentcam.frames", qos: .userInteractive)
    private let processor = FrameProcessor()
    private let settingsLock = NSLock()
    private let displayLock = NSLock()
    private var frameSettings = FrameSettings()
    private var pendingDisplayImage: CGImage?
    private var isDisplayUpdateScheduled = false
    private var configured = false

    override init() {
        super.init()
        InMemoryLog.shared.info("Camera engine initialized", category: "Camera")
        refreshDevices()
    }

    func update(settings: FrameSettings) {
        settingsLock.lock()
        frameSettings = settings
        settingsLock.unlock()
    }

    func refreshDevices() {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .continuityCamera, .external],
            mediaType: .video,
            position: .unspecified
        )
        let available = discovery.devices
        InMemoryLog.shared.info("Camera discovery found \(available.count) device(s)", category: "Camera")
        DispatchQueue.main.async { [weak self] in
            self?.devices = available
            if self?.selectedDeviceID == nil {
                self?.selectedDeviceID = available.first?.uniqueID
            }
        }
    }

    func start() {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        InMemoryLog.shared.info(
            "Camera start requested with authorization status \(authorizationStatus.logDescription)",
            category: "Camera"
        )

        switch authorizationStatus {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            InMemoryLog.shared.info("Requesting camera permission", category: "Camera")
            DispatchQueue.main.async { [weak self] in self?.state = .requestingPermission }
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    InMemoryLog.shared.info("Camera permission granted", category: "Camera")
                    self?.configureAndStart()
                } else {
                    InMemoryLog.shared.warning("Camera permission denied", category: "Camera")
                    DispatchQueue.main.async { self?.state = .denied }
                }
            }
        default:
            InMemoryLog.shared.warning("Camera access is unavailable", category: "Camera")
            DispatchQueue.main.async { [weak self] in self?.state = .denied }
        }
    }

    func stop() {
        InMemoryLog.shared.info("Camera stop requested", category: "Camera")
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async { self.state = .idle }
        }
    }

    func selectDevice(id: String) {
        selectedDeviceID = id
        InMemoryLog.shared.info("Camera selection changed", category: "Camera")
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.configured = false
            if self.session.isRunning { self.session.stopRunning() }
            self.configureSession()
            guard !self.session.inputs.isEmpty else { return }
            self.session.startRunning()
            InMemoryLog.shared.info("Camera session started after selection change", category: "Camera")
            DispatchQueue.main.async { self.state = .running }
        }
    }

    private func configureAndStart() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.configured { self.configureSession() }
            guard !self.session.inputs.isEmpty else { return }
            if !self.session.isRunning { self.session.startRunning() }
            InMemoryLog.shared.info("Camera session is running", category: "Camera")
            DispatchQueue.main.async { self.state = .running }
        }
    }

    private func configureSession() {
        InMemoryLog.shared.info("Configuring camera session", category: "Camera")
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .high
        session.inputs.forEach(session.removeInput)
        session.outputs.forEach(session.removeOutput)

        let device = devices.first(where: { $0.uniqueID == selectedDeviceID }) ?? devices.first
        guard let device else {
            fail("No camera was found.")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                fail("ContentCam could not connect to \(device.localizedName).")
                return
            }
            session.addInput(input)

            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            output.setSampleBufferDelegate(self, queue: frameQueue)
            guard session.canAddOutput(output) else {
                fail("ContentCam could not create a video output.")
                return
            }
            session.addOutput(output)
            configured = true
            InMemoryLog.shared.info("Camera session configured", category: "Camera")
        } catch {
            fail(error.localizedDescription)
        }
    }

    private func fail(_ message: String) {
        InMemoryLog.shared.error(message, category: "Camera")
        DispatchQueue.main.async { [weak self] in self?.state = .failed(message) }
    }

    private func scheduleForDisplay(_ image: CGImage) {
        displayLock.lock()
        // SwiftUI can render more slowly than capture produces frames. Replace
        // the pending frame instead of retaining one main-queue block per frame.
        pendingDisplayImage = image

        guard !isDisplayUpdateScheduled else {
            displayLock.unlock()
            return
        }

        isDisplayUpdateScheduled = true
        displayLock.unlock()

        DispatchQueue.main.async { [weak self] in
            self?.displayLatestImage()
        }
    }

    private func displayLatestImage() {
        displayLock.lock()
        let latestImage = pendingDisplayImage
        pendingDisplayImage = nil
        isDisplayUpdateScheduled = false
        displayLock.unlock()

        image = latestImage
    }
}

private extension AVAuthorizationStatus {
    var logDescription: String {
        switch self {
        case .notDetermined: "not determined"
        case .restricted: "restricted"
        case .denied: "denied"
        case .authorized: "authorized"
        @unknown default: "unknown"
        }
    }
}

extension CameraEngine: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        autoreleasepool {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            settingsLock.lock()
            let settings = frameSettings
            settingsLock.unlock()

            guard let processed = processor.process(pixelBuffer: pixelBuffer, settings: settings) else { return }
            scheduleForDisplay(processed)
        }
    }
}
