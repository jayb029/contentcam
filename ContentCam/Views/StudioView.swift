import AVFoundation
import SwiftUI

struct StudioView: View {
    @EnvironmentObject private var studio: StudioModel
    @EnvironmentObject private var updates: UpdateController
    @Environment(\.openWindow) private var openWindow
    @AppStorage("hasCompletedContentCamOnboarding") private var hasCompletedOnboarding = false
    @State private var isShowingGuide = false

    var body: some View {
        HStack(spacing: 0) {
            sourceSidebar
                .frame(width: 238)

            Divider().opacity(0.45)

            VStack(spacing: 0) {
                toolbar
                previewArea
            }

            Divider().opacity(0.45)

            effectsInspector
                .frame(width: 292)
        }
        .background(Color(nsColor: NSColor(calibratedWhite: 0.075, alpha: 1)))
        .preferredColorScheme(.dark)
        .onAppear {
            InMemoryLog.shared.info("Studio window appeared", category: "Lifecycle")
            studio.start()
            if !hasCompletedOnboarding {
                InMemoryLog.shared.info("First-run guide presented", category: "Guide")
                isShowingGuide = true
            } else {
                updates.start()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            studio.start()
        }
        .sheet(isPresented: $isShowingGuide) {
            OnboardingView(
                isFirstRun: !hasCompletedOnboarding,
                onFinish: completeOnboarding,
                onOpenCleanOutput: {
                    completeOnboarding()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        openWindow(id: "clean-output")
                    }
                }
            )
            .environmentObject(studio)
        }
    }

    private var sourceSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.accentColor)
                    Image(systemName: "camera.aperture")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 30, height: 30)

                Text("ContentCam")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .padding(.horizontal, 18)
            .frame(height: 64)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    SidebarSection(title: "SOURCE") {
                        DevicePicker(camera: studio.camera)
                    }

                    SidebarSection(title: "CANVAS") {
                        VStack(spacing: 8) {
                            ForEach(OutputFormat.allCases) { format in
                                CanvasButton(format: format, isSelected: studio.outputFormat == format) {
                                    withAnimation(.easeOut(duration: 0.16)) {
                                        studio.outputFormat = format
                                    }
                                }
                            }

                            if studio.outputFormat == .custom {
                                CustomCanvasSizeEditor(
                                    width: $studio.customCanvasWidth,
                                    height: $studio.customCanvasHeight
                                )
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }

                    SidebarSection(title: "FRAMING") {
                        VStack(spacing: 4) {
                            CompactToggle(title: "Mirror camera", symbol: "arrow.left.and.right.righttriangle.left.righttriangle.right", isOn: $studio.isMirrored)
                            CompactToggle(title: "Composition guides", symbol: "grid", isOn: $studio.showGuides)
                        }
                    }
                }
                .padding(14)
            }

            Spacer(minLength: 8)

            if cameraHasError {
                CameraStatus(camera: studio.camera)
                    .padding(14)
            }
        }
        .background(Color(nsColor: NSColor(calibratedWhite: 0.095, alpha: 1)))
    }

    private var cameraHasError: Bool {
        switch studio.camera.state {
        case .denied, .failed:
            true
        default:
            false
        }
    }

    private var toolbar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Studio")
                    .font(.system(size: 15, weight: .semibold))
                Text("\(studio.outputRatioLabel) processed preview")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                InMemoryLog.shared.info("Clean Output opened", category: "Output")
                openWindow(id: "clean-output")
            } label: {
                Label("Open Clean Output", systemImage: "macwindow.on.rectangle")
            }
            .buttonStyle(OutputButtonStyle())
            .keyboardShortcut("o", modifiers: [.command, .shift])

        }
        .padding(.horizontal, 22)
        .frame(height: 64)
        .background(Color(nsColor: NSColor(calibratedWhite: 0.085, alpha: 1)))
    }

    private func completeOnboarding() {
        InMemoryLog.shared.info("Guide completed", category: "Guide")
        hasCompletedOnboarding = true
        isShowingGuide = false
        updates.start()
    }

    private var previewArea: some View {
        GeometryReader { proxy in
            CameraPreview(
                camera: studio.camera,
                showGuides: studio.showGuides,
                aspectRatio: studio.outputAspectRatio,
                cornerRadius: studio.cornerRadius,
                cropScale: $studio.cropScale,
                cropOffset: $studio.cropOffset,
                allowsCropAdjustment: true,
                showsCropEditor: studio.outputFormat == .custom,
                customCropRect: $studio.customCropRect,
                customCanvasWidth: $studio.customCanvasWidth,
                customCanvasHeight: $studio.customCanvasHeight
            )
            .frame(
                maxWidth: min(proxy.size.width - 64, 900),
                maxHeight: max(proxy.size.height - 58, 240)
            )
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            .animation(.snappy(duration: 0.28), value: studio.outputFormat)
        }
        .padding(22)
        .background {
            LinearGradient(
                colors: [
                    Color(nsColor: NSColor(calibratedWhite: 0.07, alpha: 1)),
                    Color(nsColor: NSColor(calibratedWhite: 0.055, alpha: 1))
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var effectsInspector: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Finish")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Shape and cover the feed before capture.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                InspectorSection(title: "FACE COVER") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(FaceEffect.allCases) { effect in
                            EffectButton(effect: effect, isSelected: studio.faceEffect == effect) {
                                studio.faceEffect = effect
                            }
                        }
                    }

                    if studio.faceEffect != .none {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Coverage")
                                Spacer()
                                Text("\(Int(studio.facePadding * 100))%")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            .font(.system(size: 11, weight: .medium))
                            Slider(value: $studio.facePadding, in: 0.05...0.35)
                        }
                        .padding(.top, 4)
                    }
                }

                InspectorSection(title: "CLEAN OUTPUT") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Corner radius")
                            Spacer()
                            Text("\(Int(studio.cornerRadius)) px")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        .font(.system(size: 11, weight: .medium))
                        Slider(value: $studio.cornerRadius, in: 0...180)
                    }

                    Text("Corners are transparent in Clean Output—no chroma key needed.")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }

            }
            .padding(18)
        }
        .background(Color(nsColor: NSColor(calibratedWhite: 0.095, alpha: 1)))
    }
}

private struct CustomCanvasSizeEditor: View {
    @Binding var width: Int
    @Binding var height: Int

    var body: some View {
        HStack(spacing: 6) {
            dimensionField("W", value: $width)

            Text("×")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)

            dimensionField("H", value: $height)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 2)
    }

    private func dimensionField(_ label: String, value: Binding<Int>) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)

            TextField("", value: value, format: .number.grouping(.never))
                .textFieldStyle(.plain)
                .font(.system(size: 11, weight: .medium).monospacedDigit())
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 7)
        .frame(height: 28)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct DevicePicker: View {
    @ObservedObject var camera: CameraEngine

    var body: some View {
        Menu {
            if camera.devices.isEmpty {
                Text("No cameras found")
            } else {
                ForEach(camera.devices, id: \.uniqueID) { device in
                    Button {
                        camera.selectDevice(id: device.uniqueID)
                    } label: {
                        if camera.selectedDeviceID == device.uniqueID {
                            Label(device.localizedName, systemImage: "checkmark")
                        } else {
                            Text(device.localizedName)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "video.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 18)
                Text(selectedName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 11)
            .frame(height: 36)
            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .menuStyle(.borderlessButton)
    }

    private var selectedName: String {
        camera.devices.first(where: { $0.uniqueID == camera.selectedDeviceID })?.localizedName ?? "Choose camera"
    }
}

private struct CanvasButton: View {
    let format: OutputFormat
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: format.symbol)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 18)
                Text(format.title)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text(format.ratioLabel)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.6))
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .padding(.horizontal, 11)
            .frame(height: 34)
            .background(isSelected ? Color.accentColor.opacity(0.14) : Color.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct CompactToggle: View {
    let title: String
    let symbol: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

private struct EffectButton: View {
    let effect: FaceEffect
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                if effect.emoji != nil {
                    Text(effect.symbol).font(.system(size: 20))
                } else {
                    Image(systemName: effect.symbol)
                        .font(.system(size: 17, weight: .medium))
                        .frame(height: 22)
                }
                Text(effect.title)
                    .font(.system(size: 9, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            .background(isSelected ? Color.accentColor.opacity(0.13) : .white.opacity(0.045), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.65) : .white.opacity(0.04), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct CameraStatus: View {
    @ObservedObject var camera: CameraEngine

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
                .shadow(color: statusColor.opacity(0.7), radius: 4)
            Text(statusText)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            if camera.state == .running {
                Text("LIVE")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var statusText: String {
        switch camera.state {
        case .idle: "Camera idle"
        case .requestingPermission: "Awaiting permission"
        case .running: "Processing locally"
        case .denied: "Camera blocked"
        case .failed: "Camera error"
        }
    }

    private var statusColor: Color {
        switch camera.state {
        case .running: .green
        case .denied, .failed: .red
        default: .yellow
        }
    }
}

private struct SidebarSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 4)
            content
        }
    }
}

private struct InspectorSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(.tertiary)
            content
        }
    }
}

private struct OutputButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .foregroundStyle(.white)
    }
}
