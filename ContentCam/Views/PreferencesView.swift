import SwiftUI

struct PreferencesView: View {
    @ObservedObject var updates: UpdateController
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Form {
            Section("Software Updates") {
                Picker("Update channel", selection: updateChannel) {
                    ForEach(UpdateChannel.allCases) { channel in
                        Text(channel.title)
                            .tag(channel)
                    }
                }
                .pickerStyle(.radioGroup)

                Text(updates.channel.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Button("Check for Updates…") {
                    updates.checkForUpdates()
                }
                .disabled(!updates.canCheckForUpdates)

                Button("View Changelog…") {
                    InMemoryLog.shared.info("Changelog opened from Settings", category: "Updates")
                    openWindow(id: "changelog")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 280)
    }

    private var updateChannel: Binding<UpdateChannel> {
        Binding(
            get: { updates.channel },
            set: { updates.select($0) }
        )
    }
}
