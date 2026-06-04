import XCTest
@testable import AyuWalkCore

final class JournalModuleSelectionTests: XCTestCase {
    func testDefaultSelectionIncludesDefaultBlocksOnly() {
        let page = MockJournalEngine()
            .generatePages(for: SampleTripFactory.tokyoFiveDayTrip())
            .first { $0.kind == .day }!

        let selection = JournalModuleSelection.defaults(for: page)

        XCTAssertTrue(page.blocks.filter(\.isDefaultSelected).allSatisfy { selection.contains($0.id) })
        XCTAssertTrue(page.blocks.filter { !$0.isDefaultSelected }.allSatisfy { !selection.contains($0.id) })
    }

    func testToggleAddsAndRemovesBlockID() {
        let blockID = UUID()
        var selection = JournalModuleSelection(selectedBlockIDs: [])

        selection.toggle(blockID)
        XCTAssertTrue(selection.contains(blockID))

        selection.toggle(blockID)
        XCTAssertFalse(selection.contains(blockID))
    }
}
