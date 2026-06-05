import XCTest
@testable import AyuWalkCore

final class PersistenceCodingTests: XCTestCase {
    func testTripRoundTripsThroughJSON() throws {
        let trip = SampleTripFactory.tokyoFiveDayTrip()

        let data = try JSONEncoder().encode(trip)
        let decoded = try JSONDecoder().decode(Trip.self, from: data)

        XCTAssertEqual(decoded, trip)
    }

    func testJournalAndStickerSelectionsRoundTripThroughJSON() throws {
        let pageID = UUID()
        let blockID = UUID()
        let stickerID = UUID()

        let journalSelection = JournalModuleSelection(selectedBlockIDs: [blockID])
        let stickerSelection = StickerSelection(selectedStickerIDs: [stickerID])

        let data = try JSONEncoder().encode([pageID: journalSelection])
        let decodedJournal = try JSONDecoder().decode([UUID: JournalModuleSelection].self, from: data)

        let stickerData = try JSONEncoder().encode([pageID: stickerSelection])
        let decodedSticker = try JSONDecoder().decode([UUID: StickerSelection].self, from: stickerData)

        XCTAssertEqual(decodedJournal[pageID], journalSelection)
        XCTAssertEqual(decodedSticker[pageID], stickerSelection)
    }

    func testBudgetPlanDecodesLegacyJSONWithoutExpenses() throws {
        let json = #"{"total":12000,"currencyCode":"JPY"}"#
        let data = try XCTUnwrap(json.data(using: .utf8))

        let budget = try JSONDecoder().decode(BudgetPlan.self, from: data)

        XCTAssertEqual(budget.total, 12000)
        XCTAssertEqual(budget.currencyCode, "JPY")
        XCTAssertEqual(budget.expenses, [])
    }
}
