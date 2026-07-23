import AppKit
import SwiftUI

@main
struct ContentCamApp: App {
    @StateObject private var studio = StudioModel()
    @StateObject private var updates = UpdateController()

    var body: some Scene {
        WindowGroup("ContentCam") {
            StudioView()
                .environmentObject(studio)
                .environmentObject(updates)
                .frame(minWidth: 1_080, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1_280, height: 800)
        .commands {
            AboutCommands()
            PreferencesCommands()

            CommandGroup(after: .help) {
                CheckForUpdatesCommand(updates: updates)
            }
        }

        Settings {
            PreferencesView(updates: updates)
        }

        WindowGroup("ContentCam — Clean Output", id: "clean-output") {
            OutputWindowView()
                .environmentObject(studio)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 960, height: 540)
        .commandsRemoved()
    }
}

private struct AboutCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About ContentCam") {
                NSApp.orderFrontStandardAboutPanel(options: AboutPanel.options)
            }
        }
    }
}

private enum AboutPanel {
    static var options: [NSApplication.AboutPanelOptionKey: Any] {
        [
            .applicationName: "ContentCam",
            .applicationVersion: version,
            .credits: credits
        ]
    }

    private static var version: String {
        let release = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        switch (release, build) {
        case let (.some(release), .some(build)):
            return "\(release) (\(build))"
        case let (.some(release), .none):
            return release
        default:
            return "Unknown"
        }
    }

    private static var credits: NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.paragraphSpacing = 8

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraphStyle
        ]
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            .foregroundColor: NSColor.linkColor,
            .link: URL(string: "https://github.com/jayb029/contentcam")!,
            .paragraphStyle: paragraphStyle
        ]

        let credits = NSMutableAttributedString(
            string: "A native camera studio for a polished, private video feed.\nCamera processing stays on this Mac.\n\n",
            attributes: textAttributes
        )
        credits.append(NSAttributedString(string: "View ContentCam on GitHub", attributes: linkAttributes))
        return credits
    }
}
