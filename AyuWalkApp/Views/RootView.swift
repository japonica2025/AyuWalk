import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            PlanHomeView()
                .tabItem {
                    Label("行程", systemImage: "map")
                }

            JournalPreviewView()
                .tabItem {
                    Label("手帐", systemImage: "book")
                }
        }
        .tint(AyuWalkTheme.accent)
    }
}

#Preview {
    RootView()
        .environment(AppState())
}
