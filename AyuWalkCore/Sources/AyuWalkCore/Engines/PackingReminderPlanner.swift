import Foundation

public enum PackingReminderPlanner {
    public static func suggestedReminder(for trip: Trip, packingList: PackingList) -> PackingReminder? {
        let unpackedCount = packingList.items.filter { !$0.isPacked }.count
        guard unpackedCount > 0 else {
            return nil
        }

        let offset = dayCount(from: trip.duration) >= 4 ? 2 : 1
        return PackingReminder(
            id: UUID(),
            dayOffsetBeforeTrip: offset,
            fireTime: "20:00",
            note: "还有 \(unpackedCount) 件行李未打包",
            isEnabled: false
        )
    }

    private static func dayCount(from duration: TripDuration) -> Int {
        switch duration {
        case .dayCount(let dayCount):
            return TripPlanningLimits.normalizedDayCount(dayCount)
        case .dateRange(let start, let end):
            let calendar = Calendar(identifier: .gregorian)
            let startOfDay = calendar.startOfDay(for: start)
            let endOfDay = calendar.startOfDay(for: end)
            let days = calendar.dateComponents([.day], from: startOfDay, to: endOfDay).day ?? 0
            return TripPlanningLimits.normalizedDayCount(days + 1)
        }
    }
}
