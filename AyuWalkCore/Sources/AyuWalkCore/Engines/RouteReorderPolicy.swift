import Foundation

public enum RouteReorderPolicy {
    public static func routeActivityIDs(afterDisplaying activities: [Activity]) -> [UUID] {
        activities
            .filter { activity in
                activity.routeOrder != nil && !ScheduleConflictDetector.isLockedFixedNode(activity)
            }
            .map(\.id)
    }
}
