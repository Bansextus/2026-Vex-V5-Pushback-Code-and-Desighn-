import SwiftUI

struct RootView: View {
    @EnvironmentObject var model: TaheraModel

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $model.currentSection) { section in
                Text(section.rawValue)
                    .foregroundColor(Theme.text)
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.opacity(0.2))
        } detail: {
            ZStack {
                Theme.background.ignoresSafeArea()
                sectionView
                    .padding(24)
            }
            .frame(minWidth: 880, minHeight: 620)
        }
    }

    @ViewBuilder
    private var sectionView: some View {
        switch model.currentSection {
        case .home:
            HomeView()
        case .build:
            BuildUploadView()
        case .portMap:
            PortMapView()
        case .sdCard:
            SDCardView()
        case .field:
            FieldReplayView()
        case .github:
            GitHubView()
        }
    }
}
