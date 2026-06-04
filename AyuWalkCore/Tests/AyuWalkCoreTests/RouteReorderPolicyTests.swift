import XCTest
@testable import AyuWalkCore

final class RouteReorderPolicyTests: XCTestCase {
    func testReorderIDsExcludeLockedFixedNodes() {
        let firstSight = activity(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000A101")!,
            title: "Osaka Castle",
            kind: .sight,
            routeOrder: 1
        )
        let lockedHotel = activity(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000A102")!,
            title: "酒店入住",
            kind: .hotel,
            routeOrder: nil,
            reminder: Reminder(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000B102")!,
                fireTime: "15:00",
                note: nil
            )
        )
        let secondSight = activity(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000A103")!,
            title: "Nakanoshima Park",
            kind: .sight,
            routeOrder: 2
        )

        let routeIDs = RouteReorderPolicy.routeActivityIDs(
            afterDisplaying: [secondSight, lockedHotel, firstSight]
        )

        XCTAssertEqual(routeIDs, [secondSight.id, firstSight.id])
    }

    private func activity(
        id: UUID,
        title: String,
        kind: ActivityKind,
        routeOrder: Int?,
        reminder: Reminder? = nil
    ) -> Activity {
        Activity(
            id: id,
            title: title,
            kind: kind,
            place: nil,
            startTime: reminder?.fireTime,
            endTime: nil,
            notes: nil,
            estimatedCost: nil,
            routeOrder: routeOrder,
            reminder: reminder
        )
    }
}
