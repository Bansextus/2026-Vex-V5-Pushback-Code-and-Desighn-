import SwiftUI
import AppKit

struct FieldReplayView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Field Replay")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Theme.text)

            Card {
                Text("Replay overlay")
                    .font(.headline)
                    .foregroundColor(Theme.text)
                if let image = loadFieldImage() {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                } else {
                    Text("Field image not found")
                        .foregroundColor(Theme.subtext)
                }
            }
        }
    }

    private func loadFieldImage() -> NSImage? {
        guard let url = Bundle.module.url(forResource: "field", withExtension: "png") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
}
