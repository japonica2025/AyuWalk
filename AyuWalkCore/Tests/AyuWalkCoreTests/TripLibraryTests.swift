import XCTest
@testable import AyuWalkCore

final class TripLibraryTests: XCTestCase {
    func testLibraryKeepsIndependentWorkspaceStateWhenSwitchingTrips() throws {
        let first = makeWorkspace(title: "东京", completedCount: 1)
        let second = makeWorkspace(title: "大阪", completedCount: 0)
        var library = TripLibrary(activeTripID: first.id, workspaces: [first, second])

        XCTAssertEqual(library.activeWorkspace?.trip.title, "东京")
        XCTAssertEqual(library.activeWorkspace?.completedActivityIDs.count, 1)

        library.selectTrip(id: second.id)

        XCTAssertEqual(library.activeWorkspace?.trip.title, "大阪")
        XCTAssertEqual(library.activeWorkspace?.completedActivityIDs.count, 0)
    }

    func testLibraryRenamesArchivesAndDeletesTrips() {
        let first = makeWorkspace(title: "东京", completedCount: 0)
        let second = makeWorkspace(title: "大阪", completedCount: 0)
        var library = TripLibrary(activeTripID: first.id, workspaces: [first, second])

        library.renameTrip(id: second.id, title: "大阪春日旅行")
        library.setArchived(true, for: second.id)

        XCTAssertEqual(library.workspaces.first { $0.id == second.id }?.trip.title, "大阪春日旅行")
        XCTAssertEqual(library.workspaces.first { $0.id == second.id }?.isArchived, true)

        library.deleteTrip(id: first.id)

        XCTAssertEqual(library.workspaces.map(\.id), [second.id])
        XCTAssertEqual(library.activeTripID, second.id)
    }

    func testArchivingActiveTripSelectsAnotherUnarchivedTrip() {
        let first = makeWorkspace(title: "东京", completedCount: 0)
        let second = makeWorkspace(title: "大阪", completedCount: 0)
        var library = TripLibrary(activeTripID: first.id, workspaces: [first, second])

        library.setArchived(true, for: first.id)

        XCTAssertEqual(library.activeTripID, second.id)
    }

    func testAppendingNewWorkspaceRegeneratesIDsWithoutChangingTitle() {
        let source = makeWorkspace(title: "东京", completedCount: 0)
        var library = TripLibrary(activeTripID: source.id, workspaces: [source])

        let appendedID = library.appendNewWorkspace(source)

        XCTAssertNotEqual(appendedID, source.id)
        XCTAssertEqual(library.workspaces.count, 2)
        XCTAssertEqual(library.activeWorkspace?.trip.title, "东京")
        XCTAssertNotEqual(library.activeWorkspace?.trip.id, source.trip.id)
    }

    func testLibraryRepairsDuplicateWorkspaceIDsWhenLoading() {
        var source = makeWorkspace(title: "东京", completedCount: 0)
        source.isArchived = true
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        source.createdAt = createdAt
        source.updatedAt = createdAt

        let library = TripLibrary(activeTripID: source.id, workspaces: [source, source])

        XCTAssertEqual(library.workspaces.count, 2)
        XCTAssertEqual(Set(library.workspaces.map(\.id)).count, 2)
        XCTAssertEqual(library.workspaces.map(\.trip.title), ["东京", "东京"])
        XCTAssertTrue(library.workspaces.allSatisfy(\.isArchived))
        XCTAssertTrue(library.workspaces.allSatisfy { $0.createdAt == createdAt })
    }

    func testWorkspaceDecodesLegacyJSONWithoutArchiveMetadata() throws {
        let workspace = makeWorkspace(title: "东京", completedCount: 1)
        let encoded = try JSONEncoder().encode(workspace)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "isArchived")
        object.removeValue(forKey: "createdAt")
        object.removeValue(forKey: "updatedAt")
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(TripWorkspace.self, from: legacyData)

        XCTAssertFalse(decoded.isArchived)
        XCTAssertEqual(decoded.trip, workspace.trip)
        XCTAssertEqual(decoded.completedActivityIDs, workspace.completedActivityIDs)
    }

    func testLibraryDuplicatesWorkspaceWithIndependentIDsAndRemappedReferences() throws {
        var source = makeWorkspace(title: "东京", completedCount: 1)
        let participant = Participant(id: UUID(), name: "小鱼", role: nil)
        source.trip.participants = [participant]
        source.trip.budgetPlan = BudgetPlan(
            total: 2_000,
            currencyCode: "CNY",
            expenses: [
                BudgetExpense(
                    id: UUID(),
                    title: "晚餐",
                    amount: 300,
                    category: .food,
                    participantIDs: [participant.id],
                    payerID: participant.id,
                    splitMode: .custom,
                    customShares: [participant.id: 300],
                    notes: nil
                )
            ]
        )
        let customSticker = Sticker(id: UUID(), title: "票根", symbol: "ticket.fill")
        source.customStickers = [customSticker]
        let page = try XCTUnwrap(source.journalPages.first)
        let block = try XCTUnwrap(page.blocks.first)
        source.journalSelections[page.id] = JournalModuleSelection(selectedBlockIDs: [block.id])
        source.stickerSelections[page.id] = StickerSelection(
            selectedStickerIDs: [customSticker.id],
            placements: [
                JournalStickerPlacement(
                    id: UUID(),
                    stickerID: customSticker.id,
                    xRatio: 0.4,
                    yRatio: 0.6
                )
            ]
        )
        let activityID = try XCTUnwrap(source.trip.days.first?.activities.first?.id)
        source.travelMinutesBeforeActivityID[activityID] = 18
        source.enabledReminderActivityIDs = [activityID]
        var library = TripLibrary(activeTripID: source.id, workspaces: [source])

        let duplicateID = try XCTUnwrap(library.duplicateTrip(id: source.id))
        let duplicate = try XCTUnwrap(library.workspaces.first { $0.id == duplicateID })

        XCTAssertEqual(duplicate.trip.title, "东京 副本")
        XCTAssertNotEqual(duplicate.id, source.id)
        XCTAssertTrue(Set(duplicate.trip.days.map(\.id)).isDisjoint(with: source.trip.days.map(\.id)))
        XCTAssertTrue(Set(duplicate.trip.days.flatMap(\.activities).map(\.id)).isDisjoint(with: source.trip.days.flatMap(\.activities).map(\.id)))
        XCTAssertTrue(Set(duplicate.journalPages.map(\.id)).isDisjoint(with: source.journalPages.map(\.id)))
        XCTAssertTrue(Set(duplicate.customStickers.map(\.id)).isDisjoint(with: source.customStickers.map(\.id)))

        let duplicateParticipantID = try XCTUnwrap(duplicate.trip.participants.first?.id)
        XCTAssertEqual(duplicate.trip.budgetPlan?.expenses.first?.participantIDs, [duplicateParticipantID])
        XCTAssertEqual(duplicate.trip.budgetPlan?.expenses.first?.payerID, duplicateParticipantID)
        XCTAssertEqual(duplicate.trip.budgetPlan?.expenses.first?.customShares, [duplicateParticipantID: 300])
        let duplicatePage = try XCTUnwrap(duplicate.journalPages.first)
        let duplicateBlock = try XCTUnwrap(duplicatePage.blocks.first)
        XCTAssertEqual(duplicate.journalSelections[duplicatePage.id]?.selectedBlockIDs, [duplicateBlock.id])
        XCTAssertEqual(
            duplicate.stickerSelections[duplicatePage.id]?.placements.first?.stickerID,
            duplicate.customStickers.first?.id
        )
        let duplicateActivityID = try XCTUnwrap(duplicate.trip.days.first?.activities.first?.id)
        XCTAssertEqual(duplicate.travelMinutesBeforeActivityID[duplicateActivityID], 18)
        XCTAssertTrue(duplicate.enabledReminderActivityIDs.isEmpty)
        XCTAssertEqual(library.activeTripID, duplicate.id)
    }

    private func makeWorkspace(title: String, completedCount: Int) -> TripWorkspace {
        let sample = SampleTripFactory.tokyoFiveDayTrip()
        let trip = Trip(
            id: UUID(),
            title: title,
            englishProductName: sample.englishProductName,
            destination: sample.destination,
            purpose: sample.purpose,
            duration: sample.duration,
            days: sample.days,
            participants: sample.participants,
            importedSources: sample.importedSources,
            budgetPlan: sample.budgetPlan,
            packingList: sample.packingList,
            journalPages: sample.journalPages,
            planningScripts: sample.planningScripts
        )
        let pages = MockJournalEngine().generatePages(for: trip)
        let completedIDs = Set(trip.days.flatMap(\.activities).prefix(completedCount).map(\.id))
        return TripWorkspace(
            trip: trip,
            journalPages: pages,
            journalSelections: [:],
            stickerSelections: [:],
            customStickers: [],
            completedActivityIDs: completedIDs
        )
    }
}
