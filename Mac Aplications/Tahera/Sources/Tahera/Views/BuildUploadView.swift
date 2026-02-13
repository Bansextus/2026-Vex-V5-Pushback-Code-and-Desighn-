import SwiftUI

struct BuildUploadView: View {
    @EnvironmentObject var model: TaheraModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PanelTitle(text: "Build & Upload", icon: "gearshape.2.fill")

                ForEach(model.projects.indices, id: \.self) { idx in
                    Card {
                        HStack {
                            Text(model.projects[idx].name)
                                .foregroundColor(Theme.text)
                                .font(.system(size: 25, weight: .semibold, design: .rounded))
                            Spacer()
                            Stepper("Slot \(model.projects[idx].slot)", value: $model.projects[idx].slot, in: 1...8)
                                .foregroundColor(Theme.subtext)
                                .font(.system(size: 18, weight: .semibold))
                        }

                        HStack {
                            Button("Build") { model.build(project: model.projects[idx]) }
                            Button("Upload") { model.upload(project: model.projects[idx]) }
                            Button("Build + Upload") { model.buildAndUpload(project: model.projects[idx]) }
                        }
                    }
                }
            }
            .buttonStyle(TaheraActionButtonStyle())
        }
    }
}
