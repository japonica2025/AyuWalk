import XCTest
@testable import AyuWalkCore

final class TravelTimeFormatterTests: XCTestCase {
    func testFormatsMinutesOnly() {
        XCTAssertEqual(TravelTimeFormatter.routeSegmentText(minutes: 8), "移动约 8 分钟")
    }

    func testFormatsHoursAndMinutes() {
        XCTAssertEqual(TravelTimeFormatter.routeSegmentText(minutes: 75), "移动约 1 小时 15 分钟")
    }
}
