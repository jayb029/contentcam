import AppKit
import SwiftUI

struct CameraPreview: View {
    @ObservedObject var camera: CameraEngine
    let showGuides: Bool
    let aspectRatio: CGFloat

    var body: some View {
        ZStack {
            Color.black

            if let image = camera.image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFit()
            } else {
                cameraState
            }

            if showGuides, camera.image != nil {
                FramingGuides()
                    .stroke(.white.opacity(0.22), lineWidth: 1)
                    .allowsHitTesting(false)
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.35), radius: 32, y: 20)
    }

    @ViewBuilder
    private var cameraState: some View {
        switch camera.state {
        case .idle, .requestingPermission:
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text(camera.state == .requestingPermission ? "Waiting for camera access" : "Starting camera")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
            }
        case .running:
            ProgressView()
                .controlSize(.large)
        case .denied:
            VStack(spacing: 16) {
                Image(systemName: "video.slash.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                VStack(spacing: 5) {
                    Text("Camera access is off")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Allow ContentCam in Privacy & Security to begin.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.55))
                }
                Button("Open Camera Settings") {
                    guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") else { return }
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.borderedProminent)
            }
        case .failed(let message):
            VStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }
        }
    }
}
private struct FramingGuides: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for fraction in [1.0 / 3.0, 2.0 / 3.0] {
            path.move(to: CGPoint(x: rect.width * fraction, y: 0))
            path.addLine(to: CGPoint(x: rect.width * fraction, y: rect.height))
            path.move(to: CGPoint(x: 0, y: rect.height * fraction))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height * fraction))
        }
        return path
    }
}
