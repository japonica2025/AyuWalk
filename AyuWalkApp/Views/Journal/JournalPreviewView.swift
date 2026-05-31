import SwiftUI

struct JournalPreviewView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 18) {
                    ForEach(appState.journalPages) { page in
                        JournalPageCard(page: page)
                            .containerRelativeFrame(.horizontal, count: 1, span: 1, spacing: 18)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(18, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .background(AyuWalkTheme.pageBackground)
            .navigationTitle("电子手帐")
        }
    }
}

#Preview {
    JournalPreviewView()
        .environment(AppState())
}
