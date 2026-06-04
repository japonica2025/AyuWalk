import Foundation

public enum DayRouteSequence {
    public static func activities(in day: TripDay) -> [Activity] {
        day.activities
            .filter { activity in
                activity.routeOrder != nil || ScheduleConflictDetector.isLockedFixedNode(activity)
            }
            .sorted(by: routeSequencePrecedes)
    }

    private static func routeSequencePrecedes(_ lhs: Activity, _ rhs: Activity) -> Bool {
        let lhsTime = minuteValue(lhs.startTime ?? lhs.reminder?.fireTime)
        let rhsTime = minuteValue(rhs.startTime ?? rhs.reminder?.fireTime)

        switch (lhsTime, rhsTime) {
        case let (.some(lhsTime), .some(rhsTime)):
            if lhsTime == rhsTime {
                return tieBreaker(lhs, rhs)
            }
            return lhsTime < rhsTime
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return tieBreaker(lhs, rhs)
        }
    }

    private static func tieBreaker(_ lhs: Activity, _ rhs: Activity) -> Bool {
        switch (lhs.routeOrder, rhs.routeOrder) {
        case let (.some(lhsOrder), .some(rhsOrder)):
            return lhsOrder < rhsOrder
        case (.none, .some):
            return true
        case (.some, .none):
            return false
        case (.none, .none):
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }

    private static func minuteValue(_ timeText: String?) -> Int? {
        guard let timeText else {
            return nil
        }

        let parts = timeText.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              (0...23).contains(hour),
              (0...59).contains(minute) else {
            return nil
        }

        return hour * 60 + minute
    }
}
