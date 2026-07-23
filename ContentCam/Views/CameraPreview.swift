import AppKit
import SwiftUI

struct CameraPreview: View {
    @ObservedObject var camera: CameraEngine
    let showGuides: Bool
    let aspectRatio: CGFloat
    let cornerRadius: CGFloat
    @Binding var cropScale: CGFloat
    @Binding var cropOffset: CGSize
    let allowsCropAdjustment: Bool

    @State private var dragStartOffset: CGSize?
    @State private var magnificationStartScale: CGFloat?

    init(
        camera: CameraEngine,
        showGuides: Bool,
        aspectRatio: CGFloat,
        cornerRadius: CGFloat,
        cropScale: Binding<CGFloat> = .constant(1),
        cropOffset: Binding<CGSize> = .constant(.zero),
        allowsCropAdjustment: Bool = false
    ) {
        self.camera = camera
        self.showGuides = showGuides
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
        _cropScale = cropScale
        _cropOffset = cropOffset
        self.allowsCropAdjustment = allowsCropAdjustment
    }

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
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
        .overlay {
            if allowsCropAdjustment, camera.image != nil {
                GeometryReader { proxy in
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(dragGesture(in: proxy.size))
                        .simultaneousGesture(magnificationGesture)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if allowsCropAdjustment, camera.image != nil {
                cropControls
                    .padding(12)
            }
        }
        .shadow(color: .black.opacity(0.35), radius: 32, y: 20)
        .help("Drag to reposition. Pinch or use the controls to zoom.")
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if dragStartOffset == nil {
                    dragStartOffset = cropOffset
                }

                guard let start = dragStartOffset else { return }
                cropOffset = CGSize(
                    width: clamped(start.width + (value.translation.width * 2 / max(size.width, 1))),
                    height: clamped(start.height + (value.translation.height * 2 / max(size.height, 1)))
                )
            }
            .onEnded { _ in
                dragStartOffset = nil
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                if magnificationStartScale == nil {
                    magnificationStartScale = cropScale
                }

                cropScale = clampedScale((magnificationStartScale ?? cropScale) * value)
            }
            .onEnded { _ in
                magnificationStartScale = nil
            }
    }

    private var cropControls: some View {
        HStack(spacing: 4) {
            Button {
                cropScale = clampedScale(cropScale - 0.25)
            } label: {
                Image(systemName: "minus")
                    .frame(width: 24, height: 24)
            }
            .disabled(cropScale <= 1)
            .help("Zoom out")

            Text("\(Int((cropScale * 100).rounded()))%")
                .font(.system(size: 10, weight: .semibold))
                .monospacedDigit()
                .frame(width: 42)

            Button {
                cropScale = clampedScale(cropScale + 0.25)
            } label: {
                Image(systemName: "plus")
                    .frame(width: 24, height: 24)
            }
            .disabled(cropScale >= 4)
            .help("Zoom in")

            Divider()
                .frame(height: 16)
                .padding(.horizontal, 2)

            Button {
                cropScale = 1
                cropOffset = .zero
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .frame(width: 24, height: 24)
            }
            .disabled(cropScale == 1 && cropOffset == .zero)
            .help("Reset framing")
        }
        .buttonStyle(.plain)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(.white)
        .padding(5)
        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }

    private func clamped(_ value: CGFloat) -> CGFloat {
        min(max(value, -1), 1)
    }

    private func clampedScale(_ value: CGFloat) -> CGFloat {
        min(max(value, 1), 4)
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
