import AyuWalkCore
import SwiftUI

struct PlanHomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AyuWalkTheme.spacing) {
                    tripHeader
                    ItineraryTimelineView(days: appState.trip.days)
                }
                .padding()
            }
            .background(AyuWalkTheme.pageBackground)
            .navigationTitle("织步记")
        }
    }

    private var tripHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appState.trip.title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(AyuWalkTheme.ink)

            Text("\(appState.trip.destination) · Ayu Walk")
                .font(.subheadline)
                .foregroundStyle(AyuWalkTheme.mutedInk)

            Text("AI 已生成初版路线。地图连线和编号点将在下一阶段接入 MapKit。")
                .font(.callout)
                .foregroundStyle(AyuWalkTheme.mutedInk)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AyuWalkTheme.paper)
        .clipShape(RoundedRectangle(cornerRadius: AyuWalkTheme.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AyuWalkTheme.cardRadius)
                .stroke(AyuWalkTheme.border)
        )
    }
}

#Preview {
    PlanHomeView()
        .environment(AppState())
}
