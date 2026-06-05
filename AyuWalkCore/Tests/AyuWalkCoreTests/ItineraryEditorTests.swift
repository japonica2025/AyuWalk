import XCTest
@testable import AyuWalkCore

final class ItineraryEditorTests: XCTestCase {
    func testAddingActivityAppendsToRequestedDayAndAssignsNextRouteOrder() throws {
        let existing = activity(title: "Existing", routeOrder: 2)
        let newActivity = activity(title: "New")
        let days = [day(number: 1, activities: [existing])]

        let edit = try XCTUnwrap(
            ItineraryEditor.adding(newActivity, to: days[0].id, includeInRoute: true, in: days)
        )

        XCTAssertEqual(edit.days[0].activities.map(\.title), ["Existing", "New"])
        XCTAssertEqual(edit.days[0].activities.map(\.routeOrder), [1, 2])
        XCTAssertEqual(edit.previousDays, days)
    }

    func testDeletingActivityRemovesItAndNormalizesRouteOrder() throws {
        let first = activity(title: "First", routeOrder: 1)
        let second = activity(title: "Second", routeOrder: 3)
        let days = [day(number: 1, activities: [first, second])]

        let edit = try XCTUnwrap(
            ItineraryEditor.deleting(activityID: first.id, from: days[0].id, in: days)
        )

        XCTAssertEqual(edit.days[0].activities.map(\.id), [second.id])
        XCTAssertEqual(edit.days[0].activities[0].routeOrder, 1)
        XCTAssertEqual(edit.affectedActivityIDs, [first.id, second.id])
    }

    func testDuplicatingActivityCreatesIndependentIdentifiersAndInsertsAfterSource() throws {
        let source = activity(
            title: "Source",
            routeOrder: 1,
            place: Place(
                id: UUID(),
                name: "Place",
                address: nil,
                latitude: nil,
                longitude: nil,
                providerIDs: [:]
            ),
            reminder: Reminder(id: UUID(), fireTime: "10:00", note: nil)
        )
        let trailing = activity(title: "Trailing", routeOrder: 2)
        let days = [day(number: 1, activities: [source, trailing])]

        let edit = try XCTUnwrap(
            ItineraryEditor.duplicating(activityID: source.id, in: days[0].id, days: days)
        )
        let duplicate = edit.days[0].activities[1]

        XCTAssertEqual(edit.days[0].activities.map(\.title), ["Source", "Source", "Trailing"])
        XCTAssertNotEqual(duplicate.id, source.id)
        XCTAssertNotEqual(duplicate.place?.id, source.place?.id)
        XCTAssertNotEqual(duplicate.reminder?.id, source.reminder?.id)
        XCTAssertEqual(edit.days[0].activities.map(\.routeOrder), [1, 2, 3])
    }

    func testMovingActivityAcrossDaysNormalizesBothRouteSequences() throws {
        let moving = activity(title: "Moving", routeOrder: 2)
        let sourceRemaining = activity(title: "Source Remaining", routeOrder: 4)
        let destinationExisting = activity(title: "Destination Existing", routeOrder: 1)
        let days = [
            day(number: 1, activities: [moving, sourceRemaining]),
            day(number: 2, activities: [destinationExisting])
        ]

        let edit = try XCTUnwrap(
            ItineraryEditor.moving(
                activityID: moving.id,
                from: days[0].id,
                to: days[1].id,
                in: days
            )
        )

        XCTAssertEqual(edit.days[0].activities.map(\.id), [sourceRemaining.id])
        XCTAssertEqual(edit.days[0].activities[0].routeOrder, 1)
        XCTAssertEqual(edit.days[1].activities.map(\.id), [destinationExisting.id, moving.id])
        XCTAssertEqual(edit.days[1].activities.map(\.routeOrder), [1, 2])
    }

    func testSettingRouteInclusionAddsAndRemovesActivity() throws {
        let routed = activity(title: "Routed", routeOrder: 3)
        let note = activity(title: "Note")
        let days = [day(number: 1, activities: [routed, note])]

        let added = try XCTUnwrap(
            ItineraryEditor.settingRouteInclusion(
                true,
                activityID: note.id,
                dayID: days[0].id,
                in: days
            )
        )
        XCTAssertEqual(added.days[0].activities.map(\.routeOrder), [1, 2])

        let removed = try XCTUnwrap(
            ItineraryEditor.settingRouteInclusion(
                false,
                activityID: routed.id,
                dayID: days[0].id,
                in: added.days
            )
        )
        XCTAssertNil(removed.days[0].activities[0].routeOrder)
        XCTAssertEqual(removed.days[0].activities[1].routeOrder, 1)
    }

    func testUndoRestoresExactPreviousDays() throws {
        let source = activity(title: "Source", routeOrder: 1)
        let days = [day(number: 1, activities: [source])]
        let edit = try XCTUnwrap(
            ItineraryEditor.deleting(activityID: source.id, from: days[0].id, in: days)
        )

        XCTAssertEqual(ItineraryEditor.undo(edit), days)
    }

    func testFixedNodeCannotBeAddedToOrToggledIntoRoute() throws {
        let fixed = Activity(
            id: UUID(),
            title: "Fixed",
            kind: .transport,
            place: nil,
            startTime: "09:00",
            endTime: nil,
            notes: nil,
            estimatedCost: nil,
            routeOrder: nil,
            reminder: Reminder(id: UUID(), fireTime: "09:00", note: nil),
            isFixedNode: true
        )
        let days = [day(number: 1, activities: [])]
        let added = try XCTUnwrap(
            ItineraryEditor.adding(fixed, to: days[0].id, includeInRoute: true, in: days)
        )

        XCTAssertNil(added.days[0].activities[0].routeOrder)
        XCTAssertNil(
            ItineraryEditor.settingRouteInclusion(
                true,
                activityID: fixed.id,
                dayID: days[0].id,
                in: added.days
            )
        )
    }

    func testUpdatingActivityMovesAndChangesRouteInOneUndoableEdit() throws {
        let source = activity(title: "Old", routeOrder: 1)
        let days = [
            day(number: 1, activities: [source]),
            day(number: 2, activities: [])
        ]
        var updated = source
        updated.title = "Updated"
        updated.place = Place(id: UUID(), name: "New place", address: nil, latitude: nil, longitude: nil, providerIDs: [:])

        let edit = try XCTUnwrap(
            ItineraryEditor.updating(
                activityID: source.id,
                from: days[0].id,
                to: days[1].id,
                with: updated,
                includeInRoute: false,
                in: days
            )
        )

        XCTAssertTrue(edit.days[0].activities.isEmpty)
        XCTAssertEqual(edit.days[1].activities[0].title, "Updated")
        XCTAssertNil(edit.days[1].activities[0].routeOrder)
        XCTAssertEqual(ItineraryEditor.undo(edit), days)
    }

    func testMutationPreservesUserReorderedRouteInsteadOfArrayOrder() throws {
        let arrayFirst = activity(title: "Array first", routeOrder: 2)
        let userFirst = activity(title: "User first", routeOrder: 1)
        let note = activity(title: "Note")
        let days = [day(number: 1, activities: [arrayFirst, userFirst, note])]

        let edit = try XCTUnwrap(
            ItineraryEditor.deleting(activityID: note.id, from: days[0].id, in: days)
        )
        let routeOrderByID = Dictionary(
            uniqueKeysWithValues: edit.days[0].activities.map { ($0.id, $0.routeOrder) }
        )

        XCTAssertEqual(routeOrderByID[userFirst.id]!, 1)
        XCTAssertEqual(routeOrderByID[arrayFirst.id]!, 2)
    }

    private func day(number: Int, activities: [Activity]) -> TripDay {
        TripDay(
            id: UUID(),
            dayNumber: number,
            dateLabel: "Day \(number)",
            title: "Day \(number)",
            activities: activities
        )
    }

    private func activity(
        title: String,
        routeOrder: Int? = nil,
        place: Place? = nil,
        reminder: Reminder? = nil
    ) -> Activity {
        Activity(
            id: UUID(),
            title: title,
            kind: .sight,
            place: place,
            startTime: nil,
            endTime: nil,
            notes: nil,
            estimatedCost: nil,
            routeOrder: routeOrder,
            reminder: reminder
        )
    }
}
