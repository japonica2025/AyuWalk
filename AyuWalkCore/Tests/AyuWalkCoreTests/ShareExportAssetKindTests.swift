import XCTest
@testable import AyuWalkCore

final class ShareExportAssetKindTests: XCTestCase {
    func testOnlyImageExportsAreRasterImages() {
        XCTAssertFalse(ShareExportAssetKind.socialCopy.isRasterImage)
        XCTAssertFalse(ShareExportAssetKind.markdown.isRasterImage)
        XCTAssertFalse(ShareExportAssetKind.pdf.isRasterImage)
        XCTAssertTrue(ShareExportAssetKind.summaryCardImage.isRasterImage)
        XCTAssertTrue(ShareExportAssetKind.longDocumentImage.isRasterImage)
    }
}
