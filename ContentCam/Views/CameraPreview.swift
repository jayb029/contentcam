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
    let showsCropEditor: Bool
    @Binding var customCropRect: CGRect
    @Binding var customCanvasWidth: Int
    @Binding var customCanvasHeight: Int

    @State private var dragStartOffset: CGSize?
    @State private var magnificationStartScale: CGFloat?
    @State private var freeformDragStartRect: CGRect?
    @State private var freeformResizeStart: FreeformResizeStart?
    @State private var cropDrivenCanvasSize: CanvasDimensions?

    init(
        camera: CameraEngine,
        showGuides: Bool,
        aspectRatio: CGFloat,
        cornerRadius: CGFloat,
        cropScale: Binding<CGFloat> = .constant(1),
        cropOffset: Binding<CGSize> = .constant(.zero),
        allowsCropAdjustment: Bool = false,
        showsCropEditor: Bool = false,
        customCropRect: Binding<CGRect> = .constant(CGRect(x: 0, y: 0, width: 1, height: 1)),
        customCanvasWidth: Binding<Int> = .constant(1_920),
        customCanvasHeight: Binding<Int> = .constant(1_080)
    ) {
        self.camera = camera
        self.showGuides = showGuides
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
        _cropScale = cropScale
        _cropOffset = cropOffset
        self.allowsCropAdjustment = allowsCropAdjustment
        self.showsCropEditor = showsCropEditor
        _customCropRect = customCropRect
        _customCanvasWidth = customCanvasWidth
        _customCanvasHeight = customCanvasHeight
    }

    var body: some View {
        Group {
            if showsCropEditor, let sourceImage = camera.cropSourceImage {
                cropEditor(sourceImage: sourceImage)
            } else {
                outputPreview
            }
        }
        .shadow(color: .black.opacity(0.35), radius: 32, y: 20)
        .help(
            showsCropEditor
                ? "Drag inside to move the crop. Drag any edge or corner to resize it freely."
                : (allowsCropAdjustment ? "Drag to reposition. Pinch or use the controls to zoom." : "")
        )
    }

    private var outputPreview: some View {
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
    }

    private func cropEditor(sourceImage: CGImage) -> some View {
        GeometryReader { proxy in
            let editorInset: CGFloat = 18
            let fittedSourceRect = aspectFitRect(
                aspectRatio: CGFloat(sourceImage.width) / CGFloat(max(sourceImage.height, 1)),
                in: CGSize(
                    width: max(proxy.size.width - editorInset * 2, 1),
                    height: max(proxy.size.height - editorInset * 2, 1)
                )
            )
            let sourceRect = fittedSourceRect.offsetBy(dx: editorInset, dy: editorInset)
            let selectionRect = denormalized(customCropRect, in: sourceRect)
            let selectionCornerRadius = min(cornerRadius, min(selectionRect.width, selectionRect.height) / 2)

            ZStack {
                Color.black

                Image(decorative: sourceImage, scale: 1)
                    .resizable()
                    .scaledToFit()
                    .frame(width: sourceRect.width, height: sourceRect.height)
                    .position(x: sourceRect.midX, y: sourceRect.midY)

                cropMask(
                    bounds: CGRect(origin: .zero, size: proxy.size),
                    selection: selectionRect,
                    cornerRadius: selectionCornerRadius
                )

                cropGrid(in: selectionRect)
                    .stroke(.white.opacity(0.42), lineWidth: 1)
                    .allowsHitTesting(false)

                RoundedRectangle(cornerRadius: selectionCornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.9), lineWidth: 1.5)
                    .frame(width: selectionRect.width, height: selectionRect.height)
                    .position(x: selectionRect.midX, y: selectionRect.midY)
                    .allowsHitTesting(false)

                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: selectionRect.width, height: selectionRect.height)
                    .position(x: selectionRect.midX, y: selectionRect.midY)
                    .gesture(freeformCropMoveGesture(in: sourceRect))

                ForEach(CropHandlePosition.allCases) { handle in
                    CropHandle(position: handle)
                        .position(handle.position(in: selectionRect))
                        .gesture(freeformCropResizeGesture(handle: handle, in: sourceRect))
                }

                if allowsCropAdjustment {
                    freeformCropControls(sourceImage: sourceImage)
                        .position(
                            x: proxy.size.width / 2,
                            y: proxy.size.height - 26
                        )
                }
            }
        }
        .aspectRatio(
            CGFloat(sourceImage.width) / CGFloat(max(sourceImage.height, 1)),
            contentMode: .fit
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
        .onAppear {
            alignFreeformCropToCanvasAspect(
                sourceAspectRatio: CGFloat(sourceImage.width) / CGFloat(max(sourceImage.height, 1))
            )
        }
        .onChange(of: canvasDimensions) { _, newValue in
            if cropDrivenCanvasSize == newValue {
                cropDrivenCanvasSize = nil
                return
            }

            alignFreeformCropToCanvasAspect(
                sourceAspectRatio: CGFloat(sourceImage.width) / CGFloat(max(sourceImage.height, 1))
            )
        }
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

    private func freeformCropMoveGesture(in sourceRect: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if freeformDragStartRect == nil {
                    freeformDragStartRect = customCropRect
                }

                guard let start = freeformDragStartRect else { return }
                let x = min(
                    max(start.minX + value.translation.width / max(sourceRect.width, 1), 0),
                    1 - start.width
                )
                let y = min(
                    max(start.minY + value.translation.height / max(sourceRect.height, 1), 0),
                    1 - start.height
                )

                customCropRect = CGRect(x: x, y: y, width: start.width, height: start.height)
            }
            .onEnded { _ in
                freeformDragStartRect = nil
            }
    }

    private func freeformCropResizeGesture(
        handle: CropHandlePosition,
        in sourceRect: CGRect
    ) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if freeformResizeStart == nil {
                    freeformResizeStart = FreeformResizeStart(
                        rect: customCropRect,
                        canvasSize: canvasDimensions
                    )
                }

                guard let start = freeformResizeStart else { return }
                let horizontalDelta = value.translation.width / max(sourceRect.width, 1)
                let verticalDelta = value.translation.height / max(sourceRect.height, 1)
                let minimumWidth = min(max(44 / max(sourceRect.width, 1), 0.04), 1)
                let minimumHeight = min(max(44 / max(sourceRect.height, 1), 0.04), 1)

                var minimumX = start.rect.minX
                var maximumX = start.rect.maxX
                var minimumY = start.rect.minY
                var maximumY = start.rect.maxY

                if handle.movesLeftEdge {
                    minimumX = min(max(start.rect.minX + horizontalDelta, 0), maximumX - minimumWidth)
                }
                if handle.movesRightEdge {
                    maximumX = max(min(start.rect.maxX + horizontalDelta, 1), minimumX + minimumWidth)
                }
                if handle.movesTopEdge {
                    minimumY = min(max(start.rect.minY + verticalDelta, 0), maximumY - minimumHeight)
                }
                if handle.movesBottomEdge {
                    maximumY = max(min(start.rect.maxY + verticalDelta, 1), minimumY + minimumHeight)
                }

                let newRect = CGRect(
                    x: minimumX,
                    y: minimumY,
                    width: maximumX - minimumX,
                    height: maximumY - minimumY
                )
                let newCanvasSize = CanvasDimensions(
                    width: max(
                        1,
                        Int((CGFloat(start.canvasSize.width) * newRect.width / max(start.rect.width, 0.01)).rounded())
                    ),
                    height: max(
                        1,
                        Int((CGFloat(start.canvasSize.height) * newRect.height / max(start.rect.height, 0.01)).rounded())
                    )
                )

                cropDrivenCanvasSize = newCanvasSize
                customCanvasWidth = newCanvasSize.width
                customCanvasHeight = newCanvasSize.height
                customCropRect = newRect
            }
            .onEnded { _ in
                freeformResizeStart = nil
            }
    }

    private func freeformCropControls(sourceImage: CGImage) -> some View {
        HStack(spacing: 8) {
            Label("Drag edges or corners", systemImage: "crop")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))

            Divider()
                .frame(height: 16)
                .padding(.horizontal, 2)

            Button {
                let resetSize = CanvasDimensions(
                    width: max(sourceImage.width, 1),
                    height: max(sourceImage.height, 1)
                )
                cropDrivenCanvasSize = resetSize
                customCanvasWidth = resetSize.width
                customCanvasHeight = resetSize.height
                customCropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .frame(width: 24, height: 24)
            }
            .disabled(customCropRect == CGRect(x: 0, y: 0, width: 1, height: 1))
            .help("Reset crop")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .padding(5)
        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }

    private var cropControls: some View {
        HStack(spacing: 8) {
            Image(systemName: "rectangle.compress.vertical")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))

            Slider(value: $cropScale, in: 1...4)
                .controlSize(.mini)
                .frame(width: 112)
                .help("Zoom")

            Text("\(Int((cropScale * 100).rounded()))%")
                .font(.system(size: 10, weight: .semibold))
                .monospacedDigit()
                .frame(width: 42)

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

    private func aspectFitRect(aspectRatio: CGFloat, in size: CGSize) -> CGRect {
        let containerAspect = size.width / max(size.height, 1)
        if containerAspect > aspectRatio {
            let width = size.height * aspectRatio
            return CGRect(x: (size.width - width) / 2, y: 0, width: width, height: size.height)
        }

        let height = size.width / max(aspectRatio, 0.01)
        return CGRect(x: 0, y: (size.height - height) / 2, width: size.width, height: height)
    }

    private var canvasDimensions: CanvasDimensions {
        CanvasDimensions(
            width: max(customCanvasWidth, 1),
            height: max(customCanvasHeight, 1)
        )
    }

    private func denormalized(_ normalizedRect: CGRect, in sourceRect: CGRect) -> CGRect {
        CGRect(
            x: sourceRect.minX + normalizedRect.minX * sourceRect.width,
            y: sourceRect.minY + normalizedRect.minY * sourceRect.height,
            width: normalizedRect.width * sourceRect.width,
            height: normalizedRect.height * sourceRect.height
        )
    }

    private func alignFreeformCropToCanvasAspect(sourceAspectRatio: CGFloat) {
        let targetAspectRatio = CGFloat(canvasDimensions.width) / CGFloat(canvasDimensions.height)
        let normalizedAspectRatio = targetAspectRatio / max(sourceAspectRatio, 0.01)
        let currentRect = customCropRect
        let currentAspectRatio = currentRect.width / max(currentRect.height, 0.01)

        guard abs(currentAspectRatio - normalizedAspectRatio) > 0.002 else { return }

        let area = max(currentRect.width * currentRect.height, 0.001)
        var width = sqrt(area * normalizedAspectRatio)
        var height = sqrt(area / normalizedAspectRatio)
        let fitScale = min(1, 1 / max(width, height))
        width = min(max(width * fitScale, 0.01), 1)
        height = min(max(height * fitScale, 0.01), 1)

        let center = CGPoint(x: currentRect.midX, y: currentRect.midY)
        let x = min(max(center.x - width / 2, 0), 1 - width)
        let y = min(max(center.y - height / 2, 0), 1 - height)
        customCropRect = CGRect(x: x, y: y, width: width, height: height)
    }

    private func cropMask(bounds: CGRect, selection: CGRect, cornerRadius: CGFloat) -> some View {
        Path { path in
            path.addRect(bounds)
            path.addRoundedRect(
                in: selection,
                cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
            )
        }
        .fill(.black.opacity(0.58), style: FillStyle(eoFill: true))
        .allowsHitTesting(false)
    }

    private func cropGrid(in rect: CGRect) -> Path {
        var path = Path()
        for fraction in [1.0 / 3.0, 2.0 / 3.0] {
            path.move(to: CGPoint(x: rect.minX + rect.width * fraction, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * fraction, y: rect.maxY))
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * fraction))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * fraction))
        }
        return path
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

private struct CanvasDimensions: Equatable {
    let width: Int
    let height: Int
}

private struct FreeformResizeStart {
    let rect: CGRect
    let canvasSize: CanvasDimensions
}

private enum CropHandlePosition: CaseIterable, Identifiable, Equatable {
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
    case left

    var id: Self { self }

    var movesLeftEdge: Bool {
        self == .topLeft || self == .left || self == .bottomLeft
    }

    var movesRightEdge: Bool {
        self == .topRight || self == .right || self == .bottomRight
    }

    var movesTopEdge: Bool {
        self == .topLeft || self == .top || self == .topRight
    }

    var movesBottomEdge: Bool {
        self == .bottomLeft || self == .bottom || self == .bottomRight
    }

    var isCorner: Bool {
        (movesLeftEdge || movesRightEdge) && (movesTopEdge || movesBottomEdge)
    }

    func position(in rect: CGRect) -> CGPoint {
        CGPoint(
            x: movesLeftEdge ? rect.minX : (movesRightEdge ? rect.maxX : rect.midX),
            y: movesTopEdge ? rect.minY : (movesBottomEdge ? rect.maxY : rect.midY)
        )
    }
}

private struct CropHandle: View {
    let position: CropHandlePosition

    var body: some View {
        ZStack {
            if position.isCorner {
                Path { path in
                    let x: CGFloat = position.movesLeftEdge ? 10 : 26
                    let y: CGFloat = position.movesTopEdge ? 10 : 26
                    let horizontalDirection: CGFloat = position.movesLeftEdge ? -1 : 1
                    let verticalDirection: CGFloat = position.movesTopEdge ? -1 : 1
                    path.move(to: CGPoint(x: x, y: y - verticalDirection * 10))
                    path.addLine(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x - horizontalDirection * 10, y: y))
                }
                .stroke(.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            } else {
                Capsule()
                    .fill(.white)
                    .frame(
                        width: position == .top || position == .bottom ? 24 : 4,
                        height: position == .left || position == .right ? 24 : 4
                    )
            }
        }
        .frame(width: 36, height: 36)
        .contentShape(Rectangle())
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
