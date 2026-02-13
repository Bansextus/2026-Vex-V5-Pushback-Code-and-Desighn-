import SwiftUI

enum Theme {
    static let background = LinearGradient(
        gradient: Gradient(colors: [Color(hex: 0x0C1623), Color(hex: 0x12324B), Color(hex: 0x0F2E2A)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let card = Color(hex: 0x13253A).opacity(0.92)
    static let cardBorder = Color.white.opacity(0.14)
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
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 14, x: 0, y: 8)
    }
}

struct PanelTitle: View {
    let text: String
    let icon: String

    var body: some View {
        Label {
            Text(text)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(Theme.text)
        } icon: {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Theme.accent, Theme.accentMuted)
                .symbolRenderingMode(.palette)
        }
        .labelStyle(.titleAndIcon)
    }
}

struct TaheraActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundColor(Theme.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Theme.accentMuted, Theme.accent]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(configuration.isPressed ? 0.82 : 1.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(color: Theme.accent.opacity(0.26), radius: 10, x: 0, y: 5)
    }
}
