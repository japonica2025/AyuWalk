import SwiftUI

private enum AppTab: Hashable {
    case plan
    case journal
}

struct RootView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: AppTab = .plan
    @State private var isCreatingTrip = false
    @State private var isJournalBottomToolActive = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                AyuWalkTheme.pageBackground
                    .ignoresSafeArea()

                Group {
                    switch selectedTab {
                    case .plan:
                        PlanHomeView(
                            onOpenJournal: {
                                selectedTab = .journal
                            },
                            onCreateTrip: {
                                isCreatingTrip = true
                            }
                        )
                    case .journal:
                        JournalPreviewView { isActive in
                            isJournalBottomToolActive = isActive
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if !isJournalBottomToolActive {
                    bottomMenu
                        .padding(.bottom, menuBottomOffset(for: proxy))
                        .disabled(appState.isGeneratingTrip)
                        .opacity(appState.isGeneratingTrip ? 0.55 : 1)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if appState.isGeneratingTrip {
                    generationOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        .zIndex(2)
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.88), value: appState.isGeneratingTrip)
        }
        .tint(AyuWalkTheme.accent)
        .sheet(isPresented: $isCreatingTrip) {
            CreateTripView { draft in
                Task {
                    await appState.generateTrip(
                        destination: draft.destination,
                        confirmedDestinationLocation: draft.destinationLocation,
                        dayCount: draft.dayCount,
                        duration: draft.duration,
                        purpose: [draft.purpose],
                        notes: draft.notes,
                        importedSource: draft.importedSource
                    )
                }
                selectedTab = .plan
            }
            .presentationDetents([.large])
        }
    }

    private var bottomMenu: some View {
        AWFloatingTabBar(
            selection: $selectedTab,
            items: [
                AWFloatingTabItem(id: .plan, label: "行程", systemImage: "map.fill"),
                AWFloatingTabItem(id: .journal, label: "手帐", systemImage: "book.fill")
            ],
            actionLabel: "创建行程",
            actionSystemImage: "plus"
        ) {
            isCreatingTrip = true
        }
    }

    private var generationOverlay: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(AyuWalkTheme.accent)
                .scaleEffect(1.15)

            VStack(spacing: 6) {
                Text("正在生成行程")
                    .font(AyuWalkTypography.sectionTitle)
                    .foregroundStyle(AyuWalkTheme.ink)

                Text(appState.aiPlanningMessage ?? "正在整理目的地、路线点位和每日安排")
                    .font(AyuWalkTypography.caption)
                    .foregroundStyle(AyuWalkTheme.mutedInk)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .frame(maxWidth: 300)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AyuWalkTheme.panelRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AyuWalkTheme.panelRadius, style: .continuous)
                .stroke(AyuWalkTheme.hairline, lineWidth: 1)
        }
        .shadow(color: AyuWalkTheme.softShadow, radius: 24, x: 0, y: 12)
        .padding(.horizontal, 24)
    }

    private func menuBottomOffset(for proxy: GeometryProxy) -> CGFloat {
        max(proxy.safeAreaInsets.bottom * 0.18, 4)
    }

}

#Preview {
    RootView()
        .environment(AppState())
}
