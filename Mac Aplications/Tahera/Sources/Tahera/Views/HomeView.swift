import SwiftUI

struct HomeView: View {
    @EnvironmentObject var model: TaheraModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Tahera Control Center")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.text)

                Card {
                    Text("Repository")
                        .foregroundColor(Theme.text)
                        .font(.headline)
                    TextField("Repo path", text: $model.repoPath)
                        .textFieldStyle(.roundedBorder)
                }

                Card {
                    Text("Connections")
                        .foregroundColor(Theme.text)
                        .font(.headline)
                    Text(model.brainDetected ? "Brain: \(model.brainPort)" : "Brain: not detected")
                        .foregroundColor(Theme.subtext)
                    Text(model.sdMounted ? "SD: mounted at \(model.sdPath)" : "SD: not mounted")
                        .foregroundColor(Theme.subtext)
                    HStack {
                        Button("Refresh Brain") { model.refreshBrainStatus() }
                        Button("Refresh SD") { model.refreshSDStatus() }
                    }
                }

                Card {
                    Text("Output")
                        .foregroundColor(Theme.text)
                        .font(.headline)
                    ScrollView {
                        Text(model.outputLog.isEmpty ? "No output yet" : model.outputLog)
                            .foregroundColor(Theme.subtext)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 180)
                }
            }
        }
    }
}
