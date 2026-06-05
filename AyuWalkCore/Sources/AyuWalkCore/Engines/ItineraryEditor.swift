import Foundation

public struct ItineraryEdit: Equatable, Sendable {
    public let previousDays: [TripDay]
    public let days: [TripDay]
    public let affectedActivityIDs: Set<UUID>

    public init(previousDays: [TripDay], days: [TripDay], affectedActivityIDs: Set<UUID>) {
        self.previousDays = previousDays
        self.days = days
        self.affectedActivityIDs = affectedActivityIDs
    }
}

public enum ItineraryEditor {
    public static func adding(
        _ activity: Activity,
        to dayID: UUID,
        includeInRoute: Bool,
        in days: [TripDay]
    ) -> ItineraryEdit? {
        guard let dayIndex = days.firstIndex(where: { $0.id == dayID }) else {
            return nil
        }

        var updatedDays = days
        var addedActivity = activity
        addedActivity.routeOrder = includeInRoute && !activity.isFixedNode
            ? nextRouteOrder(in: updatedDays[dayIndex])
            : nil
        updatedDays[dayIndex].activities.append(addedActivity)
        normalizeRouteOrders(in: &updatedDays[dayIndex])

        return edit(previousDays: days, days: updatedDays, changedDayIndices: [dayIndex])
    }

    public static func deleting(
        activityID: UUID,
        from dayID: UUID,
        in days: [TripDay]
    ) -> ItineraryEdit? {
        guard let dayIndex = days.firstIndex(where: { $0.id == dayID }),
              days[dayIndex].activities.contains(where: { $0.id == activityID }) else {
            return nil
        }

        var updatedDays = days
        updatedDays[dayIndex].activities.removeAll { $0.id == activityID }
        normalizeRouteOrders(in: &updatedDays[dayIndex])

        var result = edit(previousDays: days, days: updatedDays, changedDayIndices: [dayIndex])
        result = ItineraryEdit(
            previousDays: result.previousDays,
            days: result.days,
            affectedActivityIDs: result.affectedActivityIDs.union([activityID])
        )
        return result
    }

    public static func duplicating(
        activityID: UUID,
        in dayID: UUID,
        days: [TripDay]
    ) -> ItineraryEdit? {
        guard let dayIndex = days.firstIndex(where: { $0.id == dayID }),
              let activityIndex = days[dayIndex].activities.firstIndex(where: { $0.id == activityID }) else {
            return nil
        }

        var updatedDays = days
        let duplicate = duplicate(of: updatedDays[dayIndex].activities[activityIndex])
        updatedDays[dayIndex].activities.insert(duplicate, at: activityIndex + 1)
        normalizeRouteOrders(in: &updatedDays[dayIndex])

        return edit(previousDays: days, days: updatedDays, changedDayIndices: [dayIndex])
    }

    public static func moving(
        activityID: UUID,
        from sourceDayID: UUID,
        to destinationDayID: UUID,
        in days: [TripDay]
    ) -> ItineraryEdit? {
        guard sourceDayID != destinationDayID,
              let sourceDayIndex = days.firstIndex(where: { $0.id == sourceDayID }),
              let destinationDayIndex = days.firstIndex(where: { $0.id == destinationDayID }),
              let activityIndex = days[sourceDayIndex].activities.firstIndex(where: { $0.id == activityID }) else {
            return nil
        }

        var updatedDays = days
        var activity = updatedDays[sourceDayIndex].activities.remove(at: activityIndex)
        if activity.routeOrder != nil {
            activity.routeOrder = nextRouteOrder(in: updatedDays[destinationDayIndex])
        }
        updatedDays[destinationDayIndex].activities.append(activity)
        normalizeRouteOrders(in: &updatedDays[sourceDayIndex])
        normalizeRouteOrders(in: &updatedDays[destinationDayIndex])

        return edit(
            previousDays: days,
            days: updatedDays,
            changedDayIndices: [sourceDayIndex, destinationDayIndex]
        )
    }

    public static func settingRouteInclusion(
        _ included: Bool,
        activityID: UUID,
        dayID: UUID,
        in days: [TripDay]
    ) -> ItineraryEdit? {
        guard let dayIndex = days.firstIndex(where: { $0.id == dayID }),
              let activityIndex = days[dayIndex].activities.firstIndex(where: { $0.id == activityID }),
              !days[dayIndex].activities[activityIndex].isFixedNode,
              (days[dayIndex].activities[activityIndex].routeOrder != nil) != included else {
            return nil
        }

        var updatedDays = days
        updatedDays[dayIndex].activities[activityIndex].routeOrder = included
            ? nextRouteOrder(in: updatedDays[dayIndex])
            : nil
        normalizeRouteOrders(in: &updatedDays[dayIndex])

        return edit(previousDays: days, days: updatedDays, changedDayIndices: [dayIndex])
    }

    public static func updating(
        activityID: UUID,
        from sourceDayID: UUID,
        to destinationDayID: UUID,
        with activity: Activity,
        includeInRoute: Bool,
        in days: [TripDay]
    ) -> ItineraryEdit? {
        guard activity.id == activityID,
              let sourceDayIndex = days.firstIndex(where: { $0.id == sourceDayID }),
              let destinationDayIndex = days.firstIndex(where: { $0.id == destinationDayID }),
              let activityIndex = days[sourceDayIndex].activities.firstIndex(where: { $0.id == activityID }) else {
            return nil
        }

        var updatedDays = days
        updatedDays[sourceDayIndex].activities.remove(at: activityIndex)
        var updatedActivity = activity
        if includeInRoute && !activity.isFixedNode {
            updatedActivity.routeOrder = sourceDayIndex == destinationDayIndex
                ? days[sourceDayIndex].activities[activityIndex].routeOrder ?? nextRouteOrder(in: days[sourceDayIndex])
                : nextRouteOrder(in: updatedDays[destinationDayIndex])
        } else {
            updatedActivity.routeOrder = nil
        }

        if sourceDayIndex == destinationDayIndex {
            updatedDays[sourceDayIndex].activities.insert(updatedActivity, at: activityIndex)
            normalizeRouteOrders(in: &updatedDays[sourceDayIndex])
            return edit(previousDays: days, days: updatedDays, changedDayIndices: [sourceDayIndex])
        }

        updatedDays[destinationDayIndex].activities.append(updatedActivity)
        normalizeRouteOrders(in: &updatedDays[sourceDayIndex])
        normalizeRouteOrders(in: &updatedDays[destinationDayIndex])
        return edit(
            previousDays: days,
            days: updatedDays,
            changedDayIndices: [sourceDayIndex, destinationDayIndex]
        )
    }

    public static func undo(_ edit: ItineraryEdit) -> [TripDay] {
        edit.previousDays
    }

    private static func duplicate(of activity: Activity) -> Activity {
        Activity(
            id: UUID(),
            title: activity.title,
            kind: activity.kind,
            place: activity.place.map {
                Place(
                    id: UUID(),
                    name: $0.name,
                    address: $0.address,
                    latitude: $0.latitude,
                    longitude: $0.longitude,
                    providerIDs: $0.providerIDs
                )
            },
            startTime: activity.startTime,
            endTime: activity.endTime,
            notes: activity.notes,
            estimatedCost: activity.estimatedCost,
            routeOrder: activity.routeOrder,
            reminder: activity.reminder.map {
                Reminder(id: UUID(), fireTime: $0.fireTime, note: $0.note)
            },
            isFixedNode: activity.isFixedNode
        )
    }

    private static func nextRouteOrder(in day: TripDay) -> Int {
        (day.activities.compactMap(\.routeOrder).max() ?? 0) + 1
    }

    private static func normalizeRouteOrders(in day: inout TripDay) {
        let orderedRouteIndices = day.activities.indices
            .filter { day.activities[$0].routeOrder != nil && !day.activities[$0].isFixedNode }
            .sorted { lhs, rhs in
                let lhsOrder = day.activities[lhs].routeOrder ?? Int.max
                let rhsOrder = day.activities[rhs].routeOrder ?? Int.max
                return lhsOrder == rhsOrder ? lhs < rhs : lhsOrder < rhsOrder
            }

        for (offset, index) in orderedRouteIndices.enumerated() {
            day.activities[index].routeOrder = offset + 1
        }
    }

    private static func edit(
        previousDays: [TripDay],
        days: [TripDay],
        changedDayIndices: Set<Int>
    ) -> ItineraryEdit {
        let affectedActivityIDs = changedDayIndices.reduce(into: Set<UUID>()) { ids, index in
            ids.formUnion(previousDays[index].activities.map(\.id))
            ids.formUnion(days[index].activities.map(\.id))
        }
        return ItineraryEdit(
            previousDays: previousDays,
            days: days,
            affectedActivityIDs: affectedActivityIDs
        )
    }
}
