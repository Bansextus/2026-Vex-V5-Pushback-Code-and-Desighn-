import SwiftUI
import AppKit

struct SDCardView: View {
    @EnvironmentObject var model: TaheraModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PanelTitle(text: "SD Card", icon: "externaldrive.fill")

            Card {
                Text(model.sdMounted ? "Mounted: \(model.sdPath)" : "Not mounted")
                    .foregroundColor(Theme.subtext)
                    .font(.system(size: 20, weight: .medium))
                HStack {
                    Button("Refresh") { model.refreshSDStatus() }
                    Button("Open SD") {
                        NSWorkspace.shared.open(URL(fileURLWithPath: model.sdPath))
                    }
                }
            }
        }
        .buttonStyle(TaheraActionButtonStyle())
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
