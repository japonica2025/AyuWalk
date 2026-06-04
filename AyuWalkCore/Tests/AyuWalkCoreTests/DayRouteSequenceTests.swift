import XCTest
@testable import AyuWalkCore

final class DayRouteSequenceTests: XCTestCase {
    func testIncludesLockedFixedNodesInTimeOrder() {
        let lockedAirport = Activity(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000E001")!,
            title: "固定交通：机场到达",
            kind: .transport,
            place: place(name: "机场"),
            startTime: "09:00",
            endTime: nil,
            notes: nil,
            estimatedCost: nil,
            routeOrder: nil,
            reminder: Reminder(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000F001")!,
                fireTime: "09:00",
                note: nil
            )
        )
        let sight = Activity(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000E002")!,
            title: "第一个景点",
            kind: .sight,
            place: place(name: "景点"),
            startTime: "10:30",
            endTime: "12:00",
            notes: nil,
            estimatedCost: nil,
            routeOrder: 1,
            reminder: nil
        )
        let day = TripDay(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000E010")!,
            dayNumber: 1,
            dateLabel: "Day 1",
            title: "测试",
            activities: [sight, lockedAirport]
        )

        let sequence = DayRouteSequence.activities(in: day)

        XCTAssertEqual(sequence.map(\.title), ["固定交通：机场到达", "第一个景点"])
    }

    func testExcludesActivitiesWithoutRouteOrderOrLock() {
        let note = Activity(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000E011")!,
            title: "备注",
            kind: .note,
            place: nil,
            startTime: nil,
            endTime: nil,
            notes: nil,
            estimatedCost: nil,
            routeOrder: nil,
            reminder: nil
        )
        let sight = Activity(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000E012")!,
            title: "景点",
            kind: .sight,
            place: place(name: "景点"),
            startTime: "09:00",
            endTime: "10:30",
            notes: nil,
            estimatedCost: nil,
            routeOrder: 1,
            reminder: nil
        )
        let day = TripDay(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000E020")!,
            dayNumber: 1,
            dateLabel: "Day 1",
            title: "测试",
            activities: [note, sight]
        )

        XCTAssertEqual(DayRouteSequence.activities(in: day).map(\.title), ["景点"])
    }

    private func place(name: String) -> Place {
        Place(
            id: UUID(),
            name: name,
            address: nil,
            latitude: 34.0,
            longitude: 135.0,
            providerIDs: [:]
        )
    }
}
