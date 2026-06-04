import Foundation

public enum DayScheduleRescheduler {
    public static func reschedule(
        _ day: TripDay,
        travelMinutesBeforeActivityID: [UUID: Int] = [:]
    ) -> TripDay {
        let lockedNodes = day.activities
            .filter(ScheduleConflictDetector.isLockedFixedNode)
            .sorted(by: timePrecedes)
        let routeActivities = day.activities
            .filter { $0.routeOrder != nil }
            .sorted { ($0.routeOrder ?? 0) < ($1.routeOrder ?? 0) }
        let hasReturnTransport = lockedNodes.contains(where: isReturnTransport)

        var rescheduledRouteActivities: [Activity] = []
        var occupiedWindows = lockedNodes.compactMap(window(for:))
        occupiedWindows.append(
            contentsOf: lockedNodes.flatMap { activity in
                bufferWindows(
                    for: activity,
                    travelMinutesBeforeActivityID: travelMinutesBeforeActivityID
                )
            }
        )
        let returnBufferStart = lockedNodes
            .filter(isReturnTransport)
            .compactMap { activity in
                bufferWindows(
                    for: activity,
                    travelMinutesBeforeActivityID: travelMinutesBeforeActivityID
                ).first?.lowerBound
            }
            .min()

        var previousRouteEnd: Int?
        for (index, activity) in routeActivities.enumerated() {
            var nextActivity = activity
            nextActivity.routeOrder = index + 1

            let duration = durationMinutes(for: activity)
            let travelMinutes = max(travelMinutesBeforeActivityID[activity.id] ?? 0, 0)
            let sequenceStart = previousRouteEnd.map { $0 + travelMinutes }
            let preferredStart = max(
                preferredStartMinute(for: activity, at: index, hasReturnTransport: hasReturnTransport),
                sequenceStart ?? 0
            )
            let start = availableStart(
                preferredStart: preferredStart,
                duration: duration,
                occupiedWindows: occupiedWindows,
                earliestStart: sequenceStart ?? 0,
                latestEnd: returnBufferStart
            )
            nextActivity.startTime = timeString(from: start)
            nextActivity.endTime = timeString(from: start + duration)

            occupiedWindows.append(start..<(start + duration))
            rescheduledRouteActivities.append(nextActivity)
            previousRouteEnd = start + duration
        }

        var rescheduledActivities = lockedNodes + rescheduledRouteActivities
        rescheduledActivities.sort(by: timePrecedes)

        var nextDay = day
        nextDay.activities = rescheduledActivities
        return nextDay
    }

    private static func preferredStartMinute(
        for activity: Activity,
        at index: Int,
        hasReturnTransport: Bool
    ) -> Int {
        if hasReturnTransport, activity.kind == .meal, activity.title.contains("晚") {
            return 15 * 60
        }

        if activity.kind == .meal {
            if activity.title.contains("晚") || index >= 3 {
                return 18 * 60
            }
            return 12 * 60
        }

        let templateStarts = hasReturnTransport
            ? [9 * 60, 12 * 60, 14 * 60, 15 * 60]
            : [9 * 60, 12 * 60, 15 * 60, 18 * 60]
        return templateStarts[min(index, templateStarts.count - 1)]
    }

    private static func durationMinutes(for activity: Activity) -> Int {
        switch activity.kind {
        case .meal:
            return 60
        case .transport:
            return 60
        case .hotel, .shopping, .concert:
            return 90
        case .sight, .freeTime, .note:
            return 90
        }
    }

    private static func firstAvailableStart(
        preferredStart: Int,
        duration: Int,
        occupiedWindows: [Range<Int>]
    ) -> Int {
        var start = preferredStart
        while overlaps(start..<(start + duration), occupiedWindows: occupiedWindows) {
            let blockingWindow = occupiedWindows
                .filter { windowsOverlap(start..<(start + duration), $0) }
                .min { $0.lowerBound < $1.lowerBound }
            start = blockingWindow?.upperBound ?? start
        }
        return start
    }

    private static func availableStart(
        preferredStart: Int,
        duration: Int,
        occupiedWindows: [Range<Int>],
        earliestStart: Int,
        latestEnd: Int?
    ) -> Int {
        guard let latestEnd else {
            return firstAvailableStart(
                preferredStart: preferredStart,
                duration: duration,
                occupiedWindows: occupiedWindows
            )
        }

        let latestStart = latestEnd - duration
        if latestStart >= earliestStart {
            let forwardStart = min(max(preferredStart, earliestStart), latestStart)
            let forwardCandidate = firstAvailableStart(
                preferredStart: forwardStart,
                duration: duration,
                occupiedWindows: occupiedWindows
            )
            if forwardCandidate + duration <= latestEnd {
                return forwardCandidate
            }

            var backwardCandidate = latestStart
            while backwardCandidate >= earliestStart {
                if !overlaps(backwardCandidate..<(backwardCandidate + duration), occupiedWindows: occupiedWindows) {
                    return backwardCandidate
                }
                backwardCandidate -= 15
            }
        }

        return firstAvailableStart(
            preferredStart: preferredStart,
            duration: duration,
            occupiedWindows: occupiedWindows
        )
    }

    private static func overlaps(_ candidate: Range<Int>, occupiedWindows: [Range<Int>]) -> Bool {
        occupiedWindows.contains { windowsOverlap(candidate, $0) }
    }

    private static func windowsOverlap(_ lhs: Range<Int>, _ rhs: Range<Int>) -> Bool {
        lhs.lowerBound < rhs.upperBound && rhs.lowerBound < lhs.upperBound
    }

    private static func window(for activity: Activity) -> Range<Int>? {
        guard let start = minuteValue(activity.startTime ?? activity.reminder?.fireTime) else {
            return nil
        }
        let end = minuteValue(activity.endTime) ?? (start + durationMinutes(for: activity))
        return start..<max(end, start + 1)
    }

    private static func bufferWindows(
        for activity: Activity,
        travelMinutesBeforeActivityID: [UUID: Int]
    ) -> [Range<Int>] {
        guard ScheduleConflictDetector.isLockedFixedNode(activity),
              let start = minuteValue(activity.startTime ?? activity.reminder?.fireTime) else {
            return []
        }

        if isCheckout(activity) {
            return [max(start - 60, 0)..<start]
        }

        if isReturnTransport(activity) {
            let travelMinutes = travelMinutesBeforeActivityID[activity.id] ?? 60
            let bufferMinutes = max(travelMinutes, 0) + 120
            return [max(start - bufferMinutes, 0)..<start]
        }

        return []
    }

    private static func isCheckout(_ activity: Activity) -> Bool {
        let text = "\(activity.title) \(activity.notes ?? "")".lowercased()
        return activity.kind == .hotel
            && (text.contains("退房")
                || text.contains("离店")
                || text.contains("checkout")
                || text.contains("check-out")
                || text.contains("check out"))
    }

    private static func isReturnTransport(_ activity: Activity) -> Bool {
        let text = "\(activity.title) \(activity.notes ?? "")".lowercased()
        return activity.kind == .transport
            && (text.contains("返程")
                || text.contains("回程")
                || text.contains("返航")
                || text.contains("离境")
                || text.contains("departure")
                || text.contains("depart"))
    }

    private static func timePrecedes(_ lhs: Activity, _ rhs: Activity) -> Bool {
        let lhsTime = minuteValue(lhs.startTime ?? lhs.reminder?.fireTime) ?? Int.max
        let rhsTime = minuteValue(rhs.startTime ?? rhs.reminder?.fireTime) ?? Int.max
        if lhsTime == rhsTime {
            return (lhs.routeOrder ?? Int.max) < (rhs.routeOrder ?? Int.max)
        }
        return lhsTime < rhsTime
    }

    private static func minuteValue(_ text: String?) -> Int? {
        guard let text else {
            return nil
        }

        let parts = text.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              (0...23).contains(hour),
              (0...59).contains(minute) else {
            return nil
        }

        return hour * 60 + minute
    }

    private static func timeString(from minutes: Int) -> String {
        let clampedMinutes = min(max(minutes, 0), 23 * 60 + 59)
        let hour = clampedMinutes / 60
        let minute = clampedMinutes % 60
        return String(format: "%02d:%02d", hour, minute)
    }
}
