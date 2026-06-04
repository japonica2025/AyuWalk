import Foundation

public enum ItineraryDayDisplayPolicy {
    public static func orderedDays(
        _ days: [TripDay],
        currentDayNumber: Int
    ) -> [TripDay] {
        guard let currentDay = days.first(where: { $0.dayNumber == currentDayNumber }) else {
            return days
        }

        return [currentDay] + days.filter { $0.id != currentDay.id }
    }

    public static func isExpandedByDefault(
        _ day: TripDay,
        currentDayNumber: Int
    ) -> Bool {
        day.dayNumber == currentDayNumber
    }

    public static func isMissed(
        _ activity: Activity,
        on day: TripDay,
        currentDayNumber: Int,
        completedActivityIDs: Set<UUID>
    ) -> Bool {
        day.dayNumber < currentDayNumber && !completedActivityIDs.contains(activity.id)
    }
}
