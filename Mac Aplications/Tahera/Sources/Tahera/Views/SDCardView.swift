import SwiftUI
import AppKit

struct SDCardView: View {
    @EnvironmentObject var model: TaheraModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SD Card")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Theme.text)

            Card {
                Text(model.sdMounted ? "Mounted: \(model.sdPath)" : "Not mounted")
                    .foregroundColor(Theme.subtext)
                HStack {
                    Button("Refresh") { model.refreshSDStatus() }
                    Button("Open SD") {
                        NSWorkspace.shared.open(URL(fileURLWithPath: model.sdPath))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
