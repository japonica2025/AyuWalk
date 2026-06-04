import XCTest
@testable import AyuWalkCore

final class ScheduleConflictDetectorTests: XCTestCase {
    func testDetectsActivityOverlappingLockedFixedNode() {
        let fixedNode = Activity(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000A001")!,
            title: "固定交通：航班到达 09:00",
            kind: .transport,
            place: nil,
            startTime: "09:00",
            endTime: nil,
            notes: nil,
            estimatedCost: nil,
            routeOrder: nil,
            reminder: Reminder(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000B001")!,
                fireTime: "09:00",
                note: "固定时间节点"
            )
        )
        let activity = Activity(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000A002")!,
            title: "大阪城",
            kind: .sight,
            place: nil,
            startTime: "08:30",
            endTime: "09:30",
            notes: nil,
            estimatedCost: nil,
            routeOrder: 1,
            reminder: nil
        )
        let day = TripDay(
            id: UUID(),
            dayNumber: 1,
            dateLabel: "Day 1",
            title: "测试",
            activities: [fixedNode, activity]
        )

        let conflicts = ScheduleConflictDetector.conflicts(in: day)

        XCTAssertEqual(conflicts.count, 1)
        XCTAssertEqual(conflicts.first?.activityID, activity.id)
        XCTAssertEqual(conflicts.first?.fixedActivityID, fixedNode.id)
        XCTAssertEqual(conflicts.first?.fixedTime, "09:00")
    }

    func testDoesNotFlagActivitiesOutsideFixedNodeTime() {
        let fixedNode = Activity(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000A011")!,
            title: "酒店入住 15:00",
            kind: .hotel,
            place: nil,
            startTime: "15:00",
            endTime: nil,
            notes: nil,
            estimatedCost: nil,
            routeOrder: nil,
            reminder: Reminder(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000B011")!,
                fireTime: "15:00",
                note: nil
            )
        )
        let activity = Activity(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000A012")!,
            title: "午饭",
            kind: .meal,
            place: nil,
            startTime: "12:00",
            endTime: "13:30",
            notes: nil,
            estimatedCost: nil,
            routeOrder: 1,
            reminder: nil
        )
        let day = TripDay(
            id: UUID(),
            dayNumber: 1,
            dateLabel: "Day 1",
            title: "测试",
            activities: [fixedNode, activity]
        )

        XCTAssertTrue(ScheduleConflictDetector.conflicts(in: day).isEmpty)
    }
}
