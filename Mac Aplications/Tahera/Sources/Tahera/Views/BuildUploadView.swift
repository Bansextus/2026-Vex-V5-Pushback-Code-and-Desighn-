import SwiftUI

struct BuildUploadView: View {
    @EnvironmentObject var model: TaheraModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Build & Upload")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.text)

                ForEach(model.projects.indices, id: \.self) { idx in
                    Card {
                        HStack {
                            Text(model.projects[idx].name)
                                .foregroundColor(Theme.text)
                                .font(.headline)
                            Spacer()
                            Stepper("Slot \(model.projects[idx].slot)", value: $model.projects[idx].slot, in: 1...8)
                                .foregroundColor(Theme.subtext)
                        }

                        HStack {
                            Button("Build") { model.build(project: model.projects[idx]) }
                            Button("Upload") { model.upload(project: model.projects[idx]) }
                            Button("Build + Upload") { model.buildAndUpload(project: model.projects[idx]) }
                        }
                    }
                }
            }
        }
    }
}
