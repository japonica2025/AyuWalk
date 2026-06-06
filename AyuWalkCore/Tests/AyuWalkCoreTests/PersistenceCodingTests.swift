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

    func testBudgetPlanDecodesLegacyExpensesWithBudgetCurrency() throws {
        let json = """
        {
          "total": 8000,
          "currencyCode": "EUR",
          "expenses": [{
            "id": "00000000-0000-0000-0000-000000001234",
            "title": "Dinner",
            "amount": 120,
            "category": "food",
            "participantIDs": []
          }]
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))

        let budget = try JSONDecoder().decode(BudgetPlan.self, from: data)

        XCTAssertEqual(budget.expenses.first?.currencyCode, "EUR")
        XCTAssertNil(budget.expenses.first?.payerID)
        XCTAssertEqual(budget.expenses.first?.splitMode, .equal)
        XCTAssertEqual(budget.expenses.first?.customShares, [:])
    }

    func testActivityDecodesLegacyFixedNodeState() throws {
        let json = """
        {
          "id": "00000000-0000-0000-0000-00000000C001",
          "title": "Fixed transport",
          "kind": "transport",
          "startTime": "09:00",
          "routeOrder": null,
          "reminder": {
            "id": "00000000-0000-0000-0000-00000000D001",
            "fireTime": "09:00"
          }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))

        let activity = try JSONDecoder().decode(Activity.self, from: data)

        XCTAssertTrue(activity.isFixedNode)
    }
}
