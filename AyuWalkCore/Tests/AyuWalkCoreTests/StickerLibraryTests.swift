import XCTest
@testable import AyuWalkCore

final class StickerLibraryTests: XCTestCase {
    func testDefaultStickerLibraryExcludesFlightAndTravelCategories() {
        let categories = StickerLibrary.default.categories.map(\.title)

        XCTAssertFalse(categories.contains("航班"))
        XCTAssertFalse(categories.contains("旅行标签"))
    }

    func testDefaultStickerLibraryHasEnoughStickersForMVPTray() {
        for category in StickerLibrary.default.categories {
            XCTAssertGreaterThanOrEqual(category.stickers.count, 6)
        }
    }

    func testStickerDecodesLegacyDataWithoutImageField() throws {
        let stickerID = UUID()
        let json = """
        {
            "id": "\(stickerID.uuidString)",
            "title": "晴天",
            "symbol": "sun.max.fill"
        }
        """.data(using: .utf8)!

        let sticker = try JSONDecoder().decode(Sticker.self, from: json)

        XCTAssertNil(sticker.imageDataBase64)
    }

    func testStickerSelectionTogglesStickerIDs() {
        let stickerID = StickerLibrary.default.categories[0].stickers[0].id
        var selection = StickerSelection(selectedStickerIDs: [])

        selection.toggle(stickerID)
        XCTAssertTrue(selection.contains(stickerID))

        selection.toggle(stickerID)
        XCTAssertFalse(selection.contains(stickerID))
    }

    func testStickerPlacementCanBeMovedAndClampsToPageBounds() throws {
        let stickerID = StickerLibrary.default.categories[0].stickers[0].id
        let placementID = UUID()
        var selection = StickerSelection(selectedStickerIDs: [])

        selection.addPlacement(stickerID: stickerID, xRatio: 0.3, yRatio: 0.4, id: placementID)
        selection.updatePlacement(id: placementID, xRatio: 1.5, yRatio: -0.2)

        let placement = try XCTUnwrap(selection.placements.first)
        XCTAssertEqual(placement.xRatio, 1)
        XCTAssertEqual(placement.yRatio, 0)
    }

    func testStickerPlacementTransformCanBeUpdatedAndScaleClamps() throws {
        let stickerID = StickerLibrary.default.categories[0].stickers[0].id
        let placementID = UUID()
        var selection = StickerSelection(selectedStickerIDs: [])

        selection.addPlacement(stickerID: stickerID, xRatio: 0.3, yRatio: 0.4, id: placementID)
        selection.updatePlacementTransform(id: placementID, scale: 3, rotationDegrees: 27)

        let placement = try XCTUnwrap(selection.placements.first)
        XCTAssertEqual(placement.scale, 2.2)
        XCTAssertEqual(placement.rotationDegrees, 27)
    }

    func testStickerPlacementDecodesLegacyDataWithoutTransformFields() throws {
        let placementID = UUID()
        let stickerID = StickerLibrary.default.categories[0].stickers[0].id
        let json = """
        {
            "id": "\(placementID.uuidString)",
            "stickerID": "\(stickerID.uuidString)",
            "xRatio": 0.25,
            "yRatio": 0.5
        }
        """.data(using: .utf8)!

        let placement = try JSONDecoder().decode(JournalStickerPlacement.self, from: json)

        XCTAssertEqual(placement.scale, 1)
        XCTAssertEqual(placement.rotationDegrees, 0)
    }
}
