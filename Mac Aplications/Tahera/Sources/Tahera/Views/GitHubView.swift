import SwiftUI

struct GitHubView: View {
    @EnvironmentObject var model: TaheraModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Repository Settings")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Theme.text)

            if model.repoSettingsUnlocked {
                unlockedView
            } else {
                lockedView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var lockedView: some View {
        Card {
            Text("Locked")
                .font(.headline)
                .foregroundColor(Theme.text)
            Text("Enter the password to access repository settings.")
                .foregroundColor(Theme.subtext)
            SecureField("Password", text: $model.repoSettingsPasswordInput)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 320)
            HStack {
                Button("Unlock") { model.unlockRepositorySettings() }
                if !model.repoSettingsAuthError.isEmpty {
                    Text(model.repoSettingsAuthError)
                        .foregroundColor(.red)
                }
            }
        }
    }

    private var unlockedView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Card {
                Text("Git Commit & Push")
                    .font(.headline)
                    .foregroundColor(Theme.text)
                TextField("Commit message", text: $model.gitCommitMessage)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Commit") { model.gitCommit() }
                    Button("Push") { model.gitPush() }
                }
            }

            Card {
                Text("Tag + Release")
                    .font(.headline)
                    .foregroundColor(Theme.text)
                TextField("Tag", text: $model.gitTag)
                    .textFieldStyle(.roundedBorder)
                TextField("Tag message", text: $model.gitTagMessage)
                    .textFieldStyle(.roundedBorder)
                TextField("Release title", text: $model.gitReleaseTitle)
                    .textFieldStyle(.roundedBorder)
                TextEditor(text: $model.gitReleaseNotes)
                    .frame(height: 120)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.15), lineWidth: 1))
                HStack {
                    Button("Tag + Push") { model.gitTagAndPush() }
                    Button("Create Release") { model.githubRelease() }
                    Button("Lock") { model.lockRepositorySettings() }
                }
            }
        }
    }
}
