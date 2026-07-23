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
            CommandGroup(after: .help) {
                CheckForUpdatesCommand(updates: updates)
            }
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
