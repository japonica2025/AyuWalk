import Foundation

public struct ScheduleConflict: Equatable, Sendable {
    public let activityID: UUID
    public let fixedActivityID: UUID
    public let fixedTime: String
    public let message: String

    public init(activityID: UUID, fixedActivityID: UUID, fixedTime: String, message: String) {
        self.activityID = activityID
        self.fixedActivityID = fixedActivityID
        self.fixedTime = fixedTime
        self.message = message
    }
}

public enum ScheduleConflictDetector {
    public static func conflicts(in day: TripDay) -> [ScheduleConflict] {
        let fixedNodes = day.activities.filter(isLockedFixedNode)
        let movableActivities = day.activities.filter { !isLockedFixedNode($0) }

        return movableActivities.flatMap { activity in
            fixedNodes.compactMap { fixedNode in
                guard let fixedMinute = startMinute(for: fixedNode),
                      activityTimeRange(activity, contains: fixedMinute) else {
                    return nil
                }

                let fixedTime = fixedNode.startTime ?? fixedNode.reminder?.fireTime ?? ""
                return ScheduleConflict(
                    activityID: activity.id,
                    fixedActivityID: fixedNode.id,
                    fixedTime: fixedTime,
                    message: "与固定节点 \(fixedTime) 冲突"
                )
            }
        }
    }

    public static func isLockedFixedNode(_ activity: Activity) -> Bool {
        activity.reminder != nil && activity.routeOrder == nil
    }

    private static func activityTimeRange(_ activity: Activity, contains minute: Int) -> Bool {
        guard let start = minuteValue(activity.startTime) else {
            return false
        }
        let end = minuteValue(activity.endTime) ?? start
        return start <= minute && minute <= end
    }

    private static func startMinute(for activity: Activity) -> Int? {
        minuteValue(activity.startTime ?? activity.reminder?.fireTime)
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
