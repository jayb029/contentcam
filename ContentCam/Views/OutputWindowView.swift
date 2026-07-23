import AppKit
import SwiftUI

struct OutputWindowView: View {
    @EnvironmentObject private var studio: StudioModel

    var body: some View {
        OutputFeed(
            camera: studio.camera,
            aspectRatio: studio.outputAspectRatio,
            cornerRadius: studio.cornerRadius
        )
        .background {
            CleanOutputWindowConfigurator(aspectRatio: studio.outputAspectRatio)
        }
        .background(Color.clear)
        .ignoresSafeArea()
        .onAppear { studio.start() }
    }
}

private struct OutputFeed: View {
    @ObservedObject var camera: CameraEngine
    let aspectRatio: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        ZStack {
            Color.black

            if let image = camera.image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFill()
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Removes all macOS title-bar surfaces from Clean Output. This hides the
/// traffic-light controls and prevents the title-bar sharing pill from appearing.
private struct CleanOutputWindowConfigurator: NSViewRepresentable {
    let aspectRatio: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        DispatchQueue.main.async {
            context.coordinator.configure(window: view.window, aspectRatio: aspectRatio)
        }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.configure(window: view.window, aspectRatio: aspectRatio)
        }
    }

    final class Coordinator {
        private weak var configuredWindow: NSWindow?
        private var configuredAspectRatio: CGFloat?

        func configure(window: NSWindow?, aspectRatio: CGFloat) {
            guard let window else { return }

            if configuredWindow !== window {
                window.styleMask = [.borderless, .resizable]
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.toolbar = nil
                window.isOpaque = false
                window.backgroundColor = .clear
                window.hasShadow = false
                window.isMovableByWindowBackground = true
                window.collectionBehavior.insert(.fullScreenAuxiliary)
                window.contentView?.wantsLayer = true
                window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor

                for type in [
                    NSWindow.ButtonType.closeButton,
                    .miniaturizeButton,
                    .zoomButton,
                    .toolbarButton,
                    .documentIconButton
                ] {
                    window.standardWindowButton(type)?.isHidden = true
                }

                configuredWindow = window
            }

            let safeAspectRatio = max(aspectRatio, 0.1)
            window.contentAspectRatio = CGSize(width: safeAspectRatio, height: 1)

            if configuredAspectRatio != safeAspectRatio {
                let currentSize = window.contentView?.bounds.size ?? window.frame.size
                let height = max(currentSize.height, 240)
                window.setContentSize(CGSize(width: height * safeAspectRatio, height: height))
                configuredAspectRatio = safeAspectRatio
            }
        }
    }
}
