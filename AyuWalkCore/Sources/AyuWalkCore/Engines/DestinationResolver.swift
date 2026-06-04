import Foundation

public enum DestinationResolution: Equatable, Sendable {
    case resolved(DestinationLocation)
    case ambiguous([DestinationLocation])
    case unresolved(String)
}

public enum DestinationResolver {
    public static func resolve(_ rawInput: String) -> DestinationResolution {
        let query = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return .unresolved(rawInput)
        }

        let normalized = normalize(query)

        if normalized == "蒙古" || normalized == "mongolia" || normalized == "menggu" {
            return .ambiguous([
                DestinationLocation(
                    latitude: 47.9184,
                    longitude: 106.9177,
                    displayName: "蒙古国",
                    countryCode: "MN",
                    currencyCode: currencyCode(forCountryCode: "MN"),
                    administrativeLevel: .country
                ),
                DestinationLocation(
                    latitude: 40.8175,
                    longitude: 111.7656,
                    displayName: "中国内蒙古",
                    countryCode: "CN",
                    currencyCode: currencyCode(forCountryCode: "CN"),
                    administrativeLevel: .province
                )
            ])
        }

        if normalized.contains("paris") || normalized.contains("巴黎") {
            return .resolved(
                DestinationLocation(
                    latitude: 48.8566,
                    longitude: 2.3522,
                    displayName: "Paris, France",
                    countryCode: "FR",
                    currencyCode: currencyCode(forCountryCode: "FR"),
                    administrativeLevel: .city
                )
            )
        }

        if normalized.contains("london") || normalized.contains("伦敦") {
            return .resolved(
                DestinationLocation(
                    latitude: 51.5072,
                    longitude: -0.1276,
                    displayName: "London, United Kingdom",
                    countryCode: "GB",
                    currencyCode: currencyCode(forCountryCode: "GB"),
                    administrativeLevel: .city
                )
            )
        }

        if normalized.contains("osaka") || normalized.contains("大阪") {
            return .resolved(
                DestinationLocation(
                    latitude: 34.6937,
                    longitude: 135.5023,
                    displayName: "Osaka, Japan",
                    countryCode: "JP",
                    currencyCode: currencyCode(forCountryCode: "JP"),
                    administrativeLevel: .city
                )
            )
        }

        if normalized.contains("tokyo") || normalized.contains("东京") || normalized.contains("東京") {
            return .resolved(
                DestinationLocation(
                    latitude: 35.6764,
                    longitude: 139.6500,
                    displayName: "Tokyo, Japan",
                    countryCode: "JP",
                    currencyCode: currencyCode(forCountryCode: "JP"),
                    administrativeLevel: .city
                )
            )
        }

        return .unresolved(query)
    }

    public static func currencyCode(forCountryCode countryCode: String?) -> String {
        guard let countryCode = countryCode?.uppercased() else {
            return "CNY"
        }

        switch countryCode {
        case "JP":
            return "JPY"
        case "FR", "DE", "IT", "ES", "NL", "BE", "AT", "PT", "IE", "FI", "GR":
            return "EUR"
        case "GB":
            return "GBP"
        case "US":
            return "USD"
        case "CN":
            return "CNY"
        case "MN":
            return "MNT"
        default:
            return "CNY"
        }
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
