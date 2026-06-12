import XCTest
@testable import AyuWalkCore

final class PackingReminderPlannerTests: XCTestCase {
    func testSuggestsReminderTwoDaysBeforeLongTripWithUnpackedItems() {
        let trip = trip(duration: .dayCount(6))
        let packingList = PackingList(items: [
            PackingItem(id: UUID(), title: "护照", isPacked: false, notes: nil),
            PackingItem(id: UUID(), title: "充电器", isPacked: true, notes: nil),
            PackingItem(id: UUID(), title: "雨伞", isPacked: false, notes: nil)
        ])

        let reminder = PackingReminderPlanner.suggestedReminder(for: trip, packingList: packingList)

        XCTAssertEqual(reminder?.dayOffsetBeforeTrip, 2)
        XCTAssertEqual(reminder?.fireTime, "20:00")
        XCTAssertEqual(reminder?.note, "还有 2 件行李未打包")
        XCTAssertEqual(reminder?.isEnabled, false)
    }

    func testSuggestsReminderOneDayBeforeShortTrip() {
        let reminder = PackingReminderPlanner.suggestedReminder(
            for: trip(duration: .dayCount(2)),
            packingList: PackingList(items: [
                PackingItem(id: UUID(), title: "身份证件", isPacked: false, notes: nil)
            ])
        )

        XCTAssertEqual(reminder?.dayOffsetBeforeTrip, 1)
    }

    func testDoesNotSuggestReminderWhenEverythingIsPacked() {
        let reminder = PackingReminderPlanner.suggestedReminder(
            for: trip(duration: .dayCount(5)),
            packingList: PackingList(items: [
                PackingItem(id: UUID(), title: "护照", isPacked: true, notes: nil)
            ])
        )

        XCTAssertNil(reminder)
    }

    private func trip(duration: TripDuration) -> Trip {
        Trip(
            id: UUID(),
            title: "Test Trip",
            englishProductName: "AyuWalk",
            destination: "Tokyo",
            purpose: [.cityWalk],
            duration: duration,
            days: [],
            participants: [],
            importedSources: [],
            budgetPlan: nil,
            packingList: nil,
            journalPages: [],
            planningScripts: []
        )
    }
}
