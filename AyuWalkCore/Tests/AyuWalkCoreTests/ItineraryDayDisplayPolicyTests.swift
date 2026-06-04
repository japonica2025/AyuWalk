import XCTest
@testable import AyuWalkCore

final class ItineraryDayDisplayPolicyTests: XCTestCase {
    func testCurrentDayIsPinnedFirst() {
        let days = [day(1), day(2), day(3)]

        let orderedDays = ItineraryDayDisplayPolicy.orderedDays(days, currentDayNumber: 2)

        XCTAssertEqual(orderedDays.map(\.dayNumber), [2, 1, 3])
    }

    func testOnlyCurrentDayIsExpandedByDefault() {
        let currentDay = day(2)
        let otherDay = day(3)

        XCTAssertTrue(
            ItineraryDayDisplayPolicy.isExpandedByDefault(
                currentDay,
                currentDayNumber: 2
            )
        )
        XCTAssertFalse(
            ItineraryDayDisplayPolicy.isExpandedByDefault(
                otherDay,
                currentDayNumber: 2
            )
        )
    }

    func testUncompletedPastDayActivityIsMissed() {
        let activityID = UUID()
        let activity = Activity(
            id: activityID,
            title: "Past sight",
            kind: .sight,
            place: nil,
            startTime: "10:00",
            endTime: nil,
            notes: nil,
            estimatedCost: nil,
            routeOrder: 1,
            reminder: nil
        )

        XCTAssertTrue(
            ItineraryDayDisplayPolicy.isMissed(
                activity,
                on: day(1),
                currentDayNumber: 2,
                completedActivityIDs: []
            )
        )
        XCTAssertFalse(
            ItineraryDayDisplayPolicy.isMissed(
                activity,
                on: day(1),
                currentDayNumber: 2,
                completedActivityIDs: [activityID]
            )
        )
    }

    private func day(_ number: Int) -> TripDay {
        TripDay(
            id: UUID(),
            dayNumber: number,
            dateLabel: "Day \(number)",
            title: "Day \(number)",
            activities: []
        )
    }
}
