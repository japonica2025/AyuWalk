import AyuWalkCore
import CoreLocation
import Foundation

struct DestinationGeocoder {
    func resolve(_ destination: String) async -> DestinationLocation? {
        let query = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return nil
        }

        switch DestinationResolver.resolve(query) {
        case let .resolved(location):
            return location
        case .ambiguous:
            return nil
        case .unresolved:
            break
        }

        do {
            let placemarks = try await CLGeocoder().geocodeAddressString(query)
            guard let placemark = placemarks.first,
                  let coordinate = placemark.location?.coordinate else {
                return nil
            }

            return DestinationLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                displayName: displayName(for: placemark, fallback: query),
                countryCode: placemark.isoCountryCode,
                currencyCode: DestinationResolver.currencyCode(forCountryCode: placemark.isoCountryCode),
                administrativeLevel: .city
            )
        } catch {
            return nil
        }
    }

    private func displayName(for placemark: CLPlacemark, fallback: String) -> String {
        [
            placemark.name,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country
        ]
        .compactMap { value in
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed?.isEmpty == false ? trimmed : nil
        }
        .reduce(into: [String]()) { uniqueParts, part in
            if !uniqueParts.contains(part) {
                uniqueParts.append(part)
            }
        }
        .joined(separator: ", ")
        .nilIfEmpty ?? fallback
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
