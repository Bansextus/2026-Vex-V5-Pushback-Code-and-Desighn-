import SwiftUI
import AppKit

@main
struct TaheraApp: App {
    @StateObject private var model = TaheraModel()
    @State private var didResizeMainWindow = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .background(
                    WindowConfigurator { window in
                        guard !didResizeMainWindow else { return }
                        didResizeMainWindow = true
                        if let frame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame {
                            window.setFrame(frame, display: true, animate: true)
                        }
                    }
                )
        }
        .windowStyle(.titleBar)
        .windowResizability(.automatic)
    }
}
