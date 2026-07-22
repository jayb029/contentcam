import SwiftUI

@main
struct ContentCamApp: App {
    @StateObject private var studio = StudioModel()

    var body: some Scene {
        WindowGroup("ContentCam") {
            StudioView()
                .environmentObject(studio)
                .frame(minWidth: 1_080, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1_280, height: 800)

        WindowGroup("ContentCam — Clean Output", id: "clean-output") {
            OutputWindowView()
                .environmentObject(studio)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 960, height: 540)
        .commandsRemoved()
    }
}
