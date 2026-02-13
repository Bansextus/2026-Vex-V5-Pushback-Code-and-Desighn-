import SwiftUI

struct HomeView: View {
    @EnvironmentObject var model: TaheraModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PanelTitle(text: "Tahera Control Center", icon: "sparkles")

                Card {
                    Text("Repository")
                        .foregroundColor(Theme.text)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                    TextField("Repo path", text: $model.repoPath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                }

                Card {
                    Text("Connections")
                        .foregroundColor(Theme.text)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                    Text(model.brainDetected ? "Brain: \(model.brainPort)" : "Brain: not detected")
                        .foregroundColor(Theme.subtext)
                        .font(.system(size: 19, weight: .medium))
                    Text(model.sdMounted ? "SD: mounted at \(model.sdPath)" : "SD: not mounted")
                        .foregroundColor(Theme.subtext)
                        .font(.system(size: 19, weight: .medium))
                    HStack {
                        Button("Refresh Brain") { model.refreshBrainStatus() }
                        Button("Refresh SD") { model.refreshSDStatus() }
                    }
                }

                Card {
                    Text("Output")
                        .foregroundColor(Theme.text)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                    ScrollView {
                        Text(model.outputLog.isEmpty ? "No output yet" : model.outputLog)
                            .foregroundColor(Theme.subtext)
                            .font(.system(size: 16, weight: .regular, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 180)
                }
            }
            .buttonStyle(TaheraActionButtonStyle())
        }
    }
}
