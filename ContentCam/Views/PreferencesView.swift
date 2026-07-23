import SwiftUI

struct PreferencesView: View {
    @ObservedObject var updates: UpdateController

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
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 240)
    }

    private var updateChannel: Binding<UpdateChannel> {
        Binding(
            get: { updates.channel },
            set: { updates.select($0) }
        )
    }
}
