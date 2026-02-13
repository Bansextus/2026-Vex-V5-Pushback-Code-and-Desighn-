import SwiftUI

enum Theme {
    static let background = LinearGradient(
        gradient: Gradient(colors: [Color(hex: 0x0C1623), Color(hex: 0x12324B), Color(hex: 0x0F2E2A)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let card = Color(hex: 0x13253A).opacity(0.92)
    static let accent = Color(hex: 0x4CD7A8)
    static let accentMuted = Color(hex: 0x2B6C8A)
    static let text = Color(hex: 0xE7EEF7)
    static let subtext = Color(hex: 0xB2C1D1)
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

struct Card<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .cornerRadius(14)
    }
}
