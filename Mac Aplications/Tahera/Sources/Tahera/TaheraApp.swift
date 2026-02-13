import SwiftUI

@main
struct TaheraApp: App {
    @StateObject private var model = TaheraModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
    }
}
