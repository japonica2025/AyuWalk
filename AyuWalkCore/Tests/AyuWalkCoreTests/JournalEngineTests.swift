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
}
