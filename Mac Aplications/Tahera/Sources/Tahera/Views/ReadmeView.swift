import SwiftUI
import AppKit

struct ReadmeView: View {
    @EnvironmentObject var model: TaheraModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PanelTitle(text: "README", icon: "book.closed.fill")

                Card {
                    HStack(spacing: 16) {
                        Image("tahera_logo", bundle: .module)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 72)
                            .shadow(color: Theme.accent.opacity(0.35), radius: 10)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Tahera Project Readme")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.text)
                            Text("Loaded from README.md in your repository (GitHub-tracked).")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Theme.subtext)
                        }

                        Spacer()
                    }

                    HStack {
                        Button("Refresh README") {
                            model.loadReadme()
                        }
                        Button("Open README File") {
                            let url = URL(fileURLWithPath: model.repoPath).appendingPathComponent("README.md")
                            NSWorkspace.shared.open(url)
                        }
                    }
                }

                Card {
                    if model.readmeContent.isEmpty {
                        Text("README is empty.")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Theme.subtext)
                    } else {
                        Text(model.readmeContent)
                            .font(.system(size: 16, weight: .regular, design: .monospaced))
                            .foregroundColor(Theme.subtext)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .buttonStyle(TaheraActionButtonStyle())
        }
        .onAppear {
            model.loadReadme()
        }
    }
}
