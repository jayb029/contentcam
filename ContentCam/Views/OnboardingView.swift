import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var studio: StudioModel
    @EnvironmentObject private var updates: UpdateController

    let isFirstRun: Bool
    let onFinish: () -> Void
    let onOpenCleanOutput: () -> Void

    @State private var page = 0
    @State private var selectedPreset: OnboardingPreset?
    @State private var selectedUpdateChannel: UpdateChannel?
    @State private var didChooseProduction = false

    private let pageCount = 4

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.45)

            Group {
                switch page {
                case 0:
                    welcomePage
                case 1:
                    setupPage
                case 2:
                    updatesPage
                default:
                    connectionPage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider().opacity(0.45)
            footer
        }
        .frame(width: 780, height: 590)
        .background(Color(nsColor: NSColor(calibratedWhite: 0.085, alpha: 1)))
        .preferredColorScheme(.dark)
        .onAppear {
            if !isFirstRun {
                selectedUpdateChannel = updates.channel
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor)
                Image(systemName: "camera.aperture")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 28, height: 28)

            Text("ContentCam")
                .font(.system(size: 14, weight: .semibold, design: .rounded))

            Spacer()

            Button(isFirstRun ? "Skip setup" : "Close") {
                onFinish()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 22)
        .frame(height: 56)
    }

    private var welcomePage: some View {
        HStack(spacing: 42) {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .padding(.bottom, 22)

                Text("You brought the camera.\nWe'll make it content-ready.")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .tracking(-0.6)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Frame it for any platform, cover your face when you want privacy, and use the finished feed in the apps you already have.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)

                Text("Everything happens on this Mac.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(.top, 18)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                OnboardingBenefit(
                    symbol: "rectangle.on.rectangle",
                    title: "Fit the destination",
                    detail: "Landscape for calls, vertical for shorts, or square for social."
                )
                Divider().padding(.leading, 46)
                OnboardingBenefit(
                    symbol: "face.dashed",
                    title: "Choose what people see",
                    detail: "Blur, pixelate, or cover your face while the camera keeps moving."
                )
                Divider().padding(.leading, 46)
                OnboardingBenefit(
                    symbol: "lock.shield",
                    title: "Keep the footage yours",
                    detail: "No account, no upload, and no recording in the background."
                )
            }
            .frame(width: 310)
            .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.white.opacity(0.06), lineWidth: 1)
            }
        }
        .padding(.horizontal, 46)
        .padding(.vertical, 38)
    }

    private var setupPage: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Start with a setup that fits")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                Text("Pick one now or tune every setting yourself in the studio. You can change this anytime.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 24) {
                CameraPreview(
                    camera: studio.camera,
                    showGuides: studio.showGuides,
                    aspectRatio: studio.outputFormat.aspectRatio
                )
                .frame(width: 390, height: 300)
                .animation(.easeOut(duration: 0.2), value: studio.outputFormat)

                VStack(spacing: 9) {
                    ForEach(OnboardingPreset.allCases) { preset in
                        PresetButton(preset: preset, isSelected: selectedPreset == preset) {
                            selectedPreset = preset
                            preset.apply(to: studio)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 30)
    }

    private var connectionPage: some View {
        HStack(alignment: .top, spacing: 42) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("From ContentCam to any camera app")
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                    Text("OBS is the bridge. Set it up once, then choose OBS Virtual Camera wherever you join or record.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 17) {
                    GuideStep(
                        number: 1,
                        title: "Open Clean Output",
                        detail: "This is your camera feed without controls, guides, or window chrome."
                    )
                    GuideStep(
                        number: 2,
                        title: "Capture it in OBS",
                        detail: "Add a macOS Screen Capture source and select “ContentCam — Clean Output.”"
                    )
                    GuideStep(
                        number: 3,
                        title: "Start OBS Virtual Camera",
                        detail: "In Zoom, Meet, FaceTime, or your recorder, select “OBS Virtual Camera.”"
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 0) {
                Text("A few ways to use it")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.bottom, 5)

                ExampleRow(
                    symbol: "person.wave.2",
                    title: "Meetings and streams",
                    detail: "Landscape · 16:9 · light corner radius"
                )
                Divider()
                ExampleRow(
                    symbol: "rectangle.portrait",
                    title: "Short-form video",
                    detail: "Vertical · 9:16 · composition guides"
                )
                Divider()
                ExampleRow(
                    symbol: "eye.slash",
                    title: "Private calls",
                    detail: "Blur, pixelate, or use a tracked face cover"
                )

                HStack(spacing: 7) {
                    Image(systemName: "checkmark.shield")
                    Text("No video leaves your Mac")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.top, 15)
            }
            .padding(18)
            .frame(width: 286, alignment: .leading)
            .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.white.opacity(0.06), lineWidth: 1)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 34)
    }

    private var updatesPage: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Choose how ContentCam updates")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                Text("ContentCam checks GitHub and installs signed updates for you. You can change this later by reopening the guide.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            if didChooseProduction {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(Color.accentColor)
                    Text("If you downloaded this build from Nightly, ContentCam will automatically move to Production when the next production release ships.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 13)
                .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .transition(.opacity)
            }

            VStack(spacing: 10) {
                ForEach(UpdateChannel.allCases) { channel in
                    UpdateChannelButton(
                        channel: channel,
                        isSelected: selectedUpdateChannel == channel
                    ) {
                        selectedUpdateChannel = channel
                        didChooseProduction = channel == .production
                        updates.select(channel)
                    }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield")
                Text("Updates are verified before installation. Camera frames are never part of an update check.")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 80)
        .padding(.vertical, 48)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Circle()
                        .fill(index == page ? Color.accentColor : .white.opacity(0.14))
                        .frame(width: 6, height: 6)
                }
            }
            .accessibilityLabel("Step \(page + 1) of \(pageCount)")

            Text("Step \(page + 1) of \(pageCount)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)

            Spacer()

            if page > 0 {
                Button("Back") {
                    withAnimation(.easeOut(duration: 0.16)) {
                        page -= 1
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
            }

            if page < pageCount - 1 {
                Button(page == 0 ? "Show me around" : "Continue") {
                    withAnimation(.easeOut(duration: 0.16)) {
                        page += 1
                    }
                }
                .buttonStyle(OnboardingPrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
                .disabled(page == 2 && selectedUpdateChannel == nil)
            } else {
                Button("Finish in Studio") {
                    onFinish()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

                Button("Open Clean Output") {
                    onOpenCleanOutput()
                }
                .buttonStyle(OnboardingPrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal, 22)
        .frame(height: 64)
    }
}

private struct UpdateChannelButton: View {
    let channel: UpdateChannel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: channel == .production ? "shippingbox" : "moon.stars")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(channel.title)
                        .font(.system(size: 13, weight: .semibold))
                    Text(channel.detail)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.55))
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
            .background(isSelected ? Color.accentColor.opacity(0.08) : .white.opacity(0.025))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.5) : .white.opacity(0.07), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private enum OnboardingPreset: String, CaseIterable, Identifiable {
    case meeting
    case vertical
    case privateCall

    var id: String { rawValue }

    var title: String {
        switch self {
        case .meeting: "Meeting ready"
        case .vertical: "Vertical creator"
        case .privateCall: "Privacy first"
        }
    }

    var detail: String {
        switch self {
        case .meeting: "A clean 16:9 frame for calls and streams"
        case .vertical: "A guided 9:16 frame for Shorts and Reels"
        case .privateCall: "A landscape feed with live face blur"
        }
    }

    var symbol: String {
        switch self {
        case .meeting: "person.wave.2"
        case .vertical: "rectangle.portrait"
        case .privateCall: "eye.slash"
        }
    }

    @MainActor
    func apply(to studio: StudioModel) {
        studio.isMirrored = true

        switch self {
        case .meeting:
            studio.outputFormat = .landscape
            studio.faceEffect = .none
            studio.cornerRadius = 48
            studio.showGuides = false
        case .vertical:
            studio.outputFormat = .portrait
            studio.faceEffect = .none
            studio.cornerRadius = 72
            studio.showGuides = true
        case .privateCall:
            studio.outputFormat = .landscape
            studio.faceEffect = .blur
            studio.cornerRadius = 36
            studio.showGuides = false
        }
    }
}

private struct OnboardingBenefit: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(15)
    }
}

private struct PresetButton: View {
    let preset: OnboardingPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: preset.symbol)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.title)
                        .font(.system(size: 12, weight: .semibold))
                    Text(preset.detail)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 13)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .background(isSelected ? Color.accentColor.opacity(0.10) : .white.opacity(0.035), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.55) : .white.opacity(0.06), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct GuideStep: View {
    let number: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.accentColor, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct ExampleRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                Text(detail)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 13)
    }
}

private struct OnboardingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 16)
            .frame(height: 34)
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.72 : 1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .foregroundStyle(.white)
    }
}
