import XCTest
@testable import AyuWalkCore

final class PlanningEngineTests: XCTestCase {
    func testTripStoresDaysActivitiesPlacesAndJournalReadiness() {
        let place = Place(
            id: UUID(),
            name: "涩谷 Scramble Crossing",
            address: "Shibuya City, Tokyo",
            latitude: 35.6595,
            longitude: 139.7005,
            providerIDs: [.mapKit: "mock-shibuya"]
        )

        let activity = Activity(
            id: UUID(),
            title: "涩谷 City Walk",
            kind: .sight,
            place: place,
            startTime: "10:00",
            endTime: "11:30",
            notes: "适合作为第一天轻松开始",
            estimatedCost: 0,
            routeOrder: 1,
            reminder: nil
        )

        let day = TripDay(
            id: UUID(),
            dayNumber: 1,
            dateLabel: "Day 1",
            title: "涩谷 - 原宿",
            activities: [activity]
        )

        let trip = Trip(
            id: UUID(),
            title: "东京 5 日旅行",
            englishProductName: "Ayu Walk",
            destination: "东京",
            purpose: [.cityWalk],
            duration: .dayCount(5),
            days: [day],
            participants: [],
            importedSources: [],
            budgetPlan: nil,
            packingList: nil,
            journalPages: [],
            planningScripts: []
        )

        XCTAssertEqual(trip.destination, "东京")
        XCTAssertEqual(trip.days.first?.activities.first?.routeOrder, 1)
        XCTAssertEqual(trip.days.first?.activities.first?.place?.providerIDs[.mapKit], "mock-shibuya")
    }

    func testCoreEnumsExposeStableRawValues() {
        XCTAssertEqual(TravelPurpose.cityWalk.rawValue, "cityWalk")
        XCTAssertEqual(ActivityKind.freeTime.rawValue, "freeTime")
        XCTAssertEqual(MapProviderKind.mapKit.rawValue, "mapKit")
        XCTAssertEqual(JournalBlockKind.dateLocation.rawValue, "dateLocation")
    }

    func testTripDurationDateRangeStoresDates() {
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 86400)
        let duration = TripDuration.dateRange(start: start, end: end)

        guard case let .dateRange(actualStart, actualEnd) = duration else {
            return XCTFail("Expected date range duration")
        }

        XCTAssertEqual(actualStart, start)
        XCTAssertEqual(actualEnd, end)
    }

    func testBudgetPackingAndPlanningExposeStableFieldNames() {
        let budgetPlan = BudgetPlan(total: 12000, currencyCode: "CNY")
        let packingList = PackingList(items: [
            PackingItem(id: UUID(), title: "护照", isPacked: false, notes: nil)
        ])
        let planningScript = PlanningScript(
            id: UUID(),
            name: "Day planner",
            summary: "Builds a simple daily outline"
        )

        XCTAssertEqual(budgetPlan.total, 12000)
        XCTAssertEqual(budgetPlan.currencyCode, "CNY")
        XCTAssertEqual(packingList.items.count, 1)
        XCTAssertEqual(planningScript.name, "Day planner")
        XCTAssertEqual(planningScript.summary, "Builds a simple daily outline")
    }

    func testSampleTripHasOrderedMapReadyActivities() {
        let trip = SampleTripFactory.tokyoFiveDayTrip()

        let routeOrders = trip.days.flatMap { day in
            day.activities.compactMap(\.routeOrder)
        }

        XCTAssertEqual(trip.englishProductName, "Ayu Walk")
        XCTAssertFalse(routeOrders.isEmpty)
        XCTAssertEqual(routeOrders.min(), 1)
        XCTAssertTrue(trip.days.allSatisfy { !$0.activities.isEmpty })
    }

    func testMockPlanningEngineBuildsStructuredTripFromPrompt() {
        let engine = MockPlanningEngine()
        let trip = engine.generateTrip(
            destination: "东京",
            dayCount: 5,
            purpose: [.cityWalk, .food],
            notes: "想要轻松一点，适合发小红书"
        )

        XCTAssertEqual(trip.destination, "东京")
        XCTAssertEqual(trip.duration, .dayCount(5))
        XCTAssertEqual(trip.purpose, [.cityWalk, .food])
        XCTAssertEqual(trip.days.first?.activities.first?.routeOrder, 1)
        XCTAssertTrue(trip.planningScripts.contains { $0.name == "编号路线点" })
        XCTAssertEqual(trip.importedSources.count, 1)
        XCTAssertEqual(trip.importedSources.first?.kind, .pastedText)
        XCTAssertEqual(trip.importedSources.first?.title, "用户想法")
        XCTAssertEqual(trip.importedSources.first?.extractedText, "想要轻松一点，适合发小红书")
    }
}
