import AppKit
import SwiftUI

@main
struct ContentCamApp: App {
    @StateObject private var studio = StudioModel()
    @StateObject private var updates = UpdateController()

    init() {
        InMemoryLog.shared.info("Application initialized", category: "Lifecycle")
    }

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

            CommandGroup(replacing: .help) {
                Button("ContentCam Documentation") {
                    ContentCamHelp.openDocumentation()
                }

                Button("Export Logs…") {
                    ContentCamHelp.exportLogs()
                }

                Divider()
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
            .applicationVersion: releaseVersion,
            .version: buildVersion,
            .credits: credits
        ]
    }

    private static var releaseVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }

    private static var buildVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
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
