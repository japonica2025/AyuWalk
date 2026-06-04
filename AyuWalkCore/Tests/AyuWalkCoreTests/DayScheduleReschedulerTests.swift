import XCTest
@testable import AyuWalkCore

final class DayScheduleReschedulerTests: XCTestCase {
    func testMovesRouteActivitiesAfterEarlyLockedNode() {
        let lockedNode = Activity(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000C001")!,
            title: "固定交通：航班到达 09:00",
            kind: .transport,
            place: nil,
            startTime: "09:00",
            endTime: nil,
            notes: nil,
            estimatedCost: nil,
            routeOrder: nil,
            reminder: Reminder(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000D001")!,
                fireTime: "09:00",
                note: "固定时间节点"
            )
        )
        let sight = routeActivity(
            id: "00000000-0000-0000-0000-00000000C002",
            title: "大阪城",
            kind: .sight,
            startTime: "08:30",
            endTime: "09:30",
            routeOrder: 1
        )
        let lunch = routeActivity(
            id: "00000000-0000-0000-0000-00000000C003",
            title: "午饭",
            kind: .meal,
            startTime: "12:00",
            endTime: "13:00",
            routeOrder: 2
        )
        let day = TripDay(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000C010")!,
            dayNumber: 1,
            dateLabel: "Day 1",
            title: "大阪",
            activities: [lockedNode, sight, lunch]
        )

        let rescheduledDay = DayScheduleRescheduler.reschedule(day)

        let routeActivities = rescheduledDay.activities.filter { $0.routeOrder != nil }
        XCTAssertEqual(routeActivities.map(\.title), ["大阪城", "午饭"])
        XCTAssertEqual(routeActivities.map(\.routeOrder), [1, 2])
        XCTAssertEqual(routeActivities.map(\.startTime), ["10:00", "12:00"])
        XCTAssertEqual(routeActivities.map(\.endTime), ["11:30", "13:00"])
        XCTAssertEqual(ScheduleConflictDetector.conflicts(in: rescheduledDay), [])
    }

    func testKeepsLateLockedNodeInPlaceAndSchedulesBeforeIt() {
        let sight = routeActivity(
            id: "00000000-0000-0000-0000-00000000C011",
            title: "伦敦塔",
            kind: .sight,
            startTime: "09:00",
            endTime: "10:30",
            routeOrder: 1
        )
        let dinner = routeActivity(
            id: "00000000-0000-0000-0000-00000000C012",
            title: "晚饭",
            kind: .meal,
            startTime: "18:00",
            endTime: "19:00",
            routeOrder: 2
        )
        let lockedNode = Activity(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000C013")!,
            title: "固定交通：火车 19:30",
            kind: .transport,
            place: nil,
            startTime: "19:30",
            endTime: nil,
            notes: nil,
            estimatedCost: nil,
            routeOrder: nil,
            reminder: Reminder(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000D013")!,
                fireTime: "19:30",
                note: "固定时间节点"
            )
        )
        let day = TripDay(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000C020")!,
            dayNumber: 1,
            dateLabel: "Day 1",
            title: "伦敦",
            activities: [sight, dinner, lockedNode]
        )

        let rescheduledDay = DayScheduleRescheduler.reschedule(day)

        XCTAssertEqual(rescheduledDay.activities.map(\.title), ["伦敦塔", "晚饭", "固定交通：火车 19:30"])
        XCTAssertEqual(rescheduledDay.activities[0].startTime, "09:00")
        XCTAssertEqual(rescheduledDay.activities[1].startTime, "18:00")
        XCTAssertEqual(rescheduledDay.activities[2].startTime, "19:30")
    }

    func testAddsTravelTimeBeforeRouteActivity() {
        let sight = routeActivity(
            id: "00000000-0000-0000-0000-00000000C021",
            title: "卢浮宫",
            kind: .sight,
            startTime: "09:00",
            endTime: "10:30",
            routeOrder: 1
        )
        let lunch = routeActivity(
            id: "00000000-0000-0000-0000-00000000C022",
            title: "午饭",
            kind: .meal,
            startTime: "12:00",
            endTime: "13:00",
            routeOrder: 2
        )
        let day = TripDay(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000C030")!,
            dayNumber: 1,
            dateLabel: "Day 1",
            title: "巴黎",
            activities: [sight, lunch]
        )

        let rescheduledDay = DayScheduleRescheduler.reschedule(
            day,
            travelMinutesBeforeActivityID: [lunch.id: 105]
        )

        XCTAssertEqual(rescheduledDay.activities[0].startTime, "09:00")
        XCTAssertEqual(rescheduledDay.activities[0].endTime, "10:30")
        XCTAssertEqual(rescheduledDay.activities[1].startTime, "12:15")
        XCTAssertEqual(rescheduledDay.activities[1].endTime, "13:15")
    }

    func testReturnDayReservesPackingAndAirportTime() {
        let checkout = Activity(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000C031")!,
            title: "酒店退房：6月4日 酒店退房 11:00",
            kind: .hotel,
            place: nil,
            startTime: "11:00",
            endTime: nil,
            notes: nil,
            estimatedCost: nil,
            routeOrder: nil,
            reminder: Reminder(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000D031")!,
                fireTime: "11:00",
                note: nil
            )
        )
        let returnFlight = Activity(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000C032")!,
            title: "返程交通：6月4日 返程航班 19:30",
            kind: .transport,
            place: nil,
            startTime: "19:30",
            endTime: nil,
            notes: nil,
            estimatedCost: nil,
            routeOrder: nil,
            reminder: Reminder(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000D032")!,
                fireTime: "19:30",
                note: nil
            )
        )
        let sight = routeActivity(
            id: "00000000-0000-0000-0000-00000000C033",
            title: "最后逛街",
            kind: .shopping,
            startTime: "09:00",
            endTime: "10:30",
            routeOrder: 1
        )
        let lunch = routeActivity(
            id: "00000000-0000-0000-0000-00000000C034",
            title: "午饭",
            kind: .meal,
            startTime: "12:00",
            endTime: "13:00",
            routeOrder: 2
        )
        let dinner = routeActivity(
            id: "00000000-0000-0000-0000-00000000C035",
            title: "晚饭",
            kind: .meal,
            startTime: "18:00",
            endTime: "19:00",
            routeOrder: 3
        )
        let day = TripDay(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000C040")!,
            dayNumber: 3,
            dateLabel: "Day 3",
            title: "返程",
            activities: [sight, lunch, dinner, checkout, returnFlight]
        )

        let rescheduledDay = DayScheduleRescheduler.reschedule(day)
        let routeActivities = rescheduledDay.activities.filter { $0.routeOrder != nil }

        XCTAssertEqual(routeActivities.map(\.title), ["最后逛街", "午饭", "晚饭"])
        XCTAssertEqual(routeActivities.map(\.startTime), ["12:30", "14:00", "15:00"])
        XCTAssertEqual(routeActivities.map(\.endTime), ["14:00", "15:00", "16:00"])
    }

    func testReturnTransportBufferUsesTravelTimePlusDepartureBuffer() {
        let returnFlight = Activity(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000C041")!,
            title: "返程交通：6月4日 返程航班 19:30",
            kind: .transport,
            place: nil,
            startTime: "19:30",
            endTime: nil,
            notes: nil,
            estimatedCost: nil,
            routeOrder: nil,
            reminder: Reminder(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000D041")!,
                fireTime: "19:30",
                note: nil
            )
        )
        let dinner = routeActivity(
            id: "00000000-0000-0000-0000-00000000C042",
            title: "晚饭",
            kind: .meal,
            startTime: "18:00",
            endTime: "19:00",
            routeOrder: 1
        )
        let day = TripDay(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000C050")!,
            dayNumber: 3,
            dateLabel: "Day 3",
            title: "返程",
            activities: [dinner, returnFlight]
        )

        let rescheduledDay = DayScheduleRescheduler.reschedule(
            day,
            travelMinutesBeforeActivityID: [returnFlight.id: 45]
        )
        let routeActivities = rescheduledDay.activities.filter { $0.routeOrder != nil }

        XCTAssertEqual(routeActivities.map(\.startTime), ["15:00"])
        XCTAssertEqual(routeActivities.map(\.endTime), ["16:00"])
    }

    func testReturnTransportBufferMovesActivityEarlierWhenTravelTimeIsLong() {
        let returnFlight = Activity(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000C051")!,
            title: "返程交通：6月4日 返程航班 19:30",
            kind: .transport,
            place: nil,
            startTime: "19:30",
            endTime: nil,
            notes: nil,
            estimatedCost: nil,
            routeOrder: nil,
            reminder: Reminder(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000D051")!,
                fireTime: "19:30",
                note: nil
            )
        )
        let dinner = routeActivity(
            id: "00000000-0000-0000-0000-00000000C052",
            title: "晚饭",
            kind: .meal,
            startTime: "18:00",
            endTime: "19:00",
            routeOrder: 1
        )
        let day = TripDay(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000C060")!,
            dayNumber: 3,
            dateLabel: "Day 3",
            title: "返程",
            activities: [dinner, returnFlight]
        )

        let rescheduledDay = DayScheduleRescheduler.reschedule(
            day,
            travelMinutesBeforeActivityID: [returnFlight.id: 300]
        )
        let routeActivities = rescheduledDay.activities.filter { $0.routeOrder != nil }

        XCTAssertEqual(routeActivities.map(\.startTime), ["11:30"])
        XCTAssertEqual(routeActivities.map(\.endTime), ["12:30"])
    }

    private func routeActivity(
        id: String,
        title: String,
        kind: ActivityKind,
        startTime: String,
        endTime: String,
        routeOrder: Int
    ) -> Activity {
        Activity(
            id: UUID(uuidString: id)!,
            title: title,
            kind: kind,
            place: nil,
            startTime: startTime,
            endTime: endTime,
            notes: nil,
            estimatedCost: nil,
            routeOrder: routeOrder,
            reminder: nil
        )
    }
}
