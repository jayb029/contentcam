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
    private var frameSettings = FrameSettings()
    private var configured = false

    override init() {
        super.init()
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
        DispatchQueue.main.async { [weak self] in
            self?.devices = available
            if self?.selectedDeviceID == nil {
                self?.selectedDeviceID = available.first?.uniqueID
            }
        }
    }

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            DispatchQueue.main.async { [weak self] in self?.state = .requestingPermission }
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.configureAndStart()
                } else {
                    DispatchQueue.main.async { self?.state = .denied }
                }
            }
        default:
            DispatchQueue.main.async { [weak self] in self?.state = .denied }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async { self.state = .idle }
        }
    }

    func selectDevice(id: String) {
        selectedDeviceID = id
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.configured = false
            if self.session.isRunning { self.session.stopRunning() }
            self.configureSession()
            self.session.startRunning()
            DispatchQueue.main.async { self.state = .running }
        }
    }

    private func configureAndStart() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.configured { self.configureSession() }
            guard !self.session.inputs.isEmpty else { return }
            if !self.session.isRunning { self.session.startRunning() }
            DispatchQueue.main.async { self.state = .running }
        }
    }

    private func configureSession() {
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
        } catch {
            fail(error.localizedDescription)
        }
    }

    private func fail(_ message: String) {
        DispatchQueue.main.async { [weak self] in self?.state = .failed(message) }
    }
}

extension CameraEngine: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        settingsLock.lock()
        let settings = frameSettings
        settingsLock.unlock()

        guard let processed = processor.process(pixelBuffer: pixelBuffer, settings: settings) else { return }
        DispatchQueue.main.async { [weak self] in self?.image = processed }
    }
}
