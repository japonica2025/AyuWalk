import XCTest
@testable import AyuWalkCore

final class AyuWalkCoreTests: XCTestCase {
    func testPackageName() {
        XCTAssertEqual(AyuWalkCorePackage.name, "AyuWalkCore")
    }
}
