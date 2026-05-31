import AyuWalkCore
import SwiftUI

struct ItineraryTimelineView: View {
    let days: [TripDay]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(days) { day in
                daySection(day)
            }
        }
    }

    private func daySection(_ day: TripDay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(day.dateLabel)｜\(day.title)")
                .font(.headline)
                .foregroundStyle(AyuWalkTheme.ink)

            ForEach(day.activities) { activity in
                HStack(alignment: .top, spacing: 12) {
                    routeBadge(activity.routeOrder)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(activity.title)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AyuWalkTheme.ink)

                        if let time = timeLabel(for: activity) {
                            Text(time)
                                .font(.caption)
                                .foregroundStyle(AyuWalkTheme.accent)
                        }

                        if let notes = activity.notes {
                            Text(notes)
                                .font(.callout)
                                .foregroundStyle(AyuWalkTheme.mutedInk)
                        }
                    }
                }
            }
        }
        .padding()
        .background(AyuWalkTheme.paper)
        .clipShape(RoundedRectangle(cornerRadius: AyuWalkTheme.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AyuWalkTheme.cardRadius)
                .stroke(AyuWalkTheme.border)
        )
    }

    private func routeBadge(_ order: Int?) -> some View {
        Text(order.map(String.init) ?? "-")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(AyuWalkTheme.accent)
            .clipShape(Circle())
    }

    private func timeLabel(for activity: Activity) -> String? {
        let parts = [activity.startTime, activity.endTime].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: "-")
    }
}

#Preview {
    ItineraryTimelineView(days: SampleTripFactory.tokyoFiveDayTrip().days)
        .padding()
}
