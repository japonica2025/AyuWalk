import XCTest
@testable import AyuWalkCore

final class JournalTemplateLibraryTests: XCTestCase {
    func testDefaultLibraryProvidesMinimalJournalAndTravelPlanCardTemplates() throws {
        let templateIDs = Set(JournalTemplateLibrary.default.map(\.id))

        XCTAssertTrue(templateIDs.contains(.minimalJournal))
        XCTAssertTrue(templateIDs.contains(.travelPlanCard))
        XCTAssertEqual(JournalTemplateLibrary.defaultTemplateID, .minimalJournal)
    }

    func testMinimalJournalSelectsDiaryFocusedBlocksForDailyPages() throws {
        let trip = SampleTripFactory.tokyoFiveDayTrip()
        let page = try XCTUnwrap(MockJournalEngine().generatePages(for: trip).first { $0.kind == .day })
        let template = try XCTUnwrap(JournalTemplateLibrary.template(id: .minimalJournal))

        let selection = JournalTemplateLibrary.selection(for: page, using: template)
        let selectedKinds = selectedBlockKinds(in: page, selection: selection)

        XCTAssertEqual(selectedKinds, [.title, .dateLocation, .photo, .text])
    }

    func testTravelPlanCardSelectsPlanningFocusedBlocksAcrossPages() throws {
        let trip = SampleTripFactory.tokyoFiveDayTrip()
        let pages = MockJournalEngine().generatePages(for: trip)
        let overview = try XCTUnwrap(pages.first { $0.kind == .overview })
        let day = try XCTUnwrap(pages.first { $0.kind == .day })
        let template = try XCTUnwrap(JournalTemplateLibrary.template(id: .travelPlanCard))

        let overviewKinds = selectedBlockKinds(
            in: overview,
            selection: JournalTemplateLibrary.selection(for: overview, using: template)
        )
        let dayKinds = selectedBlockKinds(
            in: day,
            selection: JournalTemplateLibrary.selection(for: day, using: template)
        )

        XCTAssertEqual(overviewKinds, [.routeSummary, .budgetSummary, .packingSummary])
        XCTAssertEqual(dayKinds, [.title, .dateLocation, .timeline, .mapSnapshot])
    }

    func testTemplateSelectionOnlyIncludesBlocksPresentOnThePage() {
        let page = JournalPage(
            id: UUID(),
            kind: .day,
            title: "Sparse Day",
            dayID: UUID(),
            blocks: [
                JournalBlock(
                    id: UUID(),
                    kind: .title,
                    title: "Sparse Day",
                    text: nil,
                    assetReference: nil,
                    isDefaultSelected: false
                )
            ]
        )
        let template = JournalTemplate(
            id: .travelPlanCard,
            name: "Travel Plan Card",
            description: "Planning-focused layout",
            coverStyle: .paper,
            pageStyle: .planCard,
            exportStyle: .planCardImage,
            preferredBlockKindsByPageKind: [
                .day: [.title, .timeline, .mapSnapshot]
            ]
        )

        let selection = JournalTemplateLibrary.selection(for: page, using: template)

        XCTAssertEqual(selection.selectedBlockIDs, [page.blocks[0].id])
    }

    private func selectedBlockKinds(in page: JournalPage, selection: JournalModuleSelection) -> [JournalBlockKind] {
        page.blocks
            .filter { selection.contains($0.id) }
            .map(\.kind)
    }
}
