import XCTest
@testable import AyuWalkCore

final class DestinationResolverTests: XCTestCase {
    func testMongoliaRequiresUserChoiceBecauseCountryAndProvinceLevelRegionAreBothLikely() {
        let result = DestinationResolver.resolve("蒙古")

        guard case let .ambiguous(options) = result else {
            return XCTFail("Expected Mongolia to require a user choice")
        }

        XCTAssertEqual(options.map(\.displayName), ["蒙古国", "中国内蒙古"])
        XCTAssertEqual(options.map(\.countryCode), ["MN", "CN"])
        XCTAssertEqual(options.map(\.currencyCode), ["MNT", "CNY"])
        XCTAssertEqual(options.map(\.administrativeLevel), [.country, .province])
    }

    func testLondonDefaultsToUnitedKingdomInsteadOfSameNamedSmallPlaces() {
        let result = DestinationResolver.resolve("伦敦")

        guard case let .resolved(destination) = result else {
            return XCTFail("Expected London to resolve directly")
        }

        XCTAssertEqual(destination.displayName, "London, United Kingdom")
        XCTAssertEqual(destination.countryCode, "GB")
        XCTAssertEqual(destination.currencyCode, "GBP")
        XCTAssertEqual(destination.administrativeLevel, .city)
        XCTAssertEqual(destination.latitude, 51.5072, accuracy: 0.0001)
        XCTAssertEqual(destination.longitude, -0.1276, accuracy: 0.0001)
    }

    func testParisDefaultsToFranceAndEuro() {
        let result = DestinationResolver.resolve("巴黎")

        guard case let .resolved(destination) = result else {
            return XCTFail("Expected Paris to resolve directly")
        }

        XCTAssertEqual(destination.displayName, "Paris, France")
        XCTAssertEqual(destination.countryCode, "FR")
        XCTAssertEqual(destination.currencyCode, "EUR")
    }

    func testCurrencyFallsBackToCNYOnlyWhenCountryIsUnknown() {
        XCTAssertEqual(DestinationResolver.currencyCode(forCountryCode: "JP"), "JPY")
        XCTAssertEqual(DestinationResolver.currencyCode(forCountryCode: "FR"), "EUR")
        XCTAssertEqual(DestinationResolver.currencyCode(forCountryCode: "GB"), "GBP")
        XCTAssertEqual(DestinationResolver.currencyCode(forCountryCode: "MN"), "MNT")
        XCTAssertEqual(DestinationResolver.currencyCode(forCountryCode: nil), "CNY")
    }
}
