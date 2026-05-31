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
}
