import XCTest
@testable import AyuWalkCore

final class JournalEngineTests: XCTestCase {
    func testJournalEngineGeneratesCoverOverviewAndDailyPage() {
        let trip = SampleTripFactory.tokyoFiveDayTrip()
        let pages = MockJournalEngine().generatePages(for: trip)

        XCTAssertEqual(pages.map(\.kind), [.cover, .overview, .day])
        XCTAssertEqual(pages.first?.title, "东京 5 日旅行")
    }

    func testDailyPageDefaultsRequiredModulesSelected() throws {
        let trip = SampleTripFactory.tokyoFiveDayTrip()
        let pages = MockJournalEngine().generatePages(for: trip)
        let dailyPage = try XCTUnwrap(pages.first { $0.kind == .day })

        let defaultKinds = dailyPage.blocks
            .filter(\.isDefaultSelected)
            .map(\.kind)

        XCTAssertEqual(defaultKinds, [.title, .dateLocation, .photo, .text])
    }

    func testGeneratingPagesTwiceForSameTripProducesEqualPages() {
        let trip = SampleTripFactory.tokyoFiveDayTrip()
        let engine = MockJournalEngine()

        XCTAssertEqual(
            engine.generatePages(for: trip),
            engine.generatePages(for: trip)
        )
    }

    func testCoverPageIDsDifferForDifferentTripIDs() throws {
        let firstTrip = SampleTripFactory.tokyoFiveDayTrip()
        var secondTrip = SampleTripFactory.tokyoFiveDayTrip()
        secondTrip = Trip(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            title: secondTrip.title,
            englishProductName: secondTrip.englishProductName,
            destination: secondTrip.destination,
            purpose: secondTrip.purpose,
            duration: secondTrip.duration,
            days: secondTrip.days,
            participants: secondTrip.participants,
            importedSources: secondTrip.importedSources,
            budgetPlan: secondTrip.budgetPlan,
            packingList: secondTrip.packingList,
            journalPages: secondTrip.journalPages,
            planningScripts: secondTrip.planningScripts
        )

        let firstCover = try XCTUnwrap(MockJournalEngine().generatePages(for: firstTrip).first { $0.kind == .cover })
        let secondCover = try XCTUnwrap(MockJournalEngine().generatePages(for: secondTrip).first { $0.kind == .cover })

        XCTAssertNotEqual(firstCover.id, secondCover.id)
    }

    func testDailyPageIDIsBasedOnDayIDNotArrayPosition() throws {
        let firstDay = TripDay(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000211")!,
            dayNumber: 1,
            dateLabel: "Day 1",
            title: "第一天",
            activities: []
        )
        let secondDay = TripDay(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000212")!,
            dayNumber: 2,
            dateLabel: "Day 2",
            title: "第二天",
            activities: []
        )
        let trip = Trip(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
            title: "测试旅行",
            englishProductName: "Ayu Walk",
            destination: "东京",
            purpose: [.cityWalk],
            duration: .dayCount(2),
            days: [firstDay, secondDay],
            participants: [],
            importedSources: [],
            budgetPlan: nil,
            packingList: nil,
            journalPages: [],
            planningScripts: []
        )
        let reversedTrip = Trip(
            id: trip.id,
            title: trip.title,
            englishProductName: trip.englishProductName,
            destination: trip.destination,
            purpose: trip.purpose,
            duration: trip.duration,
            days: Array(trip.days.reversed()),
            participants: trip.participants,
            importedSources: trip.importedSources,
            budgetPlan: trip.budgetPlan,
            packingList: trip.packingList,
            journalPages: trip.journalPages,
            planningScripts: trip.planningScripts
        )

        let originalPage = try XCTUnwrap(MockJournalEngine().generatePages(for: trip).first { $0.dayID == secondDay.id })
        let reversedPage = try XCTUnwrap(MockJournalEngine().generatePages(for: reversedTrip).first { $0.dayID == secondDay.id })

        XCTAssertEqual(originalPage.id, reversedPage.id)
    }
}
