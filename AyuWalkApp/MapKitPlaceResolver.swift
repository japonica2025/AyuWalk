import AyuWalkCore
import CoreLocation
import Foundation
import MapKit

struct MapKitPlaceResolver {
    func searchPlaces(query: String, destination: String, limit: Int = 8) async -> [Place] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(trimmedQuery) \(destination)"
        request.resultTypes = [.pointOfInterest, .address]

        guard let response = try? await search(request: request) else {
            return []
        }

        var seenNames: Set<String> = []
        return response.mapItems.compactMap { item in
            guard let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty,
                  seenNames.insert(name.localizedLowercase).inserted else {
                return nil
            }
            let coordinate = item.placemark.coordinate
            return Place(
                id: UUID(),
                name: name,
                address: formattedAddress(for: item.placemark),
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                providerIDs: [.mapKit: "mapkit-\(name)"]
            )
        }
        .prefix(limit)
        .map { $0 }
    }

    func resolvePlaces(
        suggestions: [MiniMaxPlaceSuggestion],
        destination: String,
        destinationLocation: DestinationLocation?,
        minimumPlaceCount: Int = 6
    ) async -> [Place] {
        var resolvedPlaces: [Place] = []
        let countryCode = destinationLocation?.countryCode ?? expectedCountryCode(for: destination)
        let targetPlaceCount = max(minimumPlaceCount, 2)
        let searchLimit = max(targetPlaceCount * 3, 12)

        for suggestion in suggestions.prefix(searchLimit) {
            guard let place = await resolvePlace(
                suggestion: suggestion,
                destination: destination,
                destinationLocation: destinationLocation,
                expectedCountryCode: countryCode
            ) else {
                continue
            }

            if !resolvedPlaces.contains(where: { $0.name == place.name }) {
                resolvedPlaces.append(place)
            }

            if resolvedPlaces.count >= searchLimit {
                break
            }
        }

        if let knownPlaces = Self.knownPlaces(for: destination) {
            appendUnique(knownPlaces, to: &resolvedPlaces, limit: targetPlaceCount)
        }

        if resolvedPlaces.count < targetPlaceCount,
           let destinationLocation {
            let supplementaryPlaces = await supplementaryPlaces(
                destination: destination,
                destinationLocation: destinationLocation,
                expectedCountryCode: countryCode,
                existingPlaces: resolvedPlaces,
                targetPlaceCount: targetPlaceCount
            )
            appendUnique(supplementaryPlaces, to: &resolvedPlaces, limit: targetPlaceCount)
        }

        if resolvedPlaces.count < targetPlaceCount,
           let destinationLocation {
            let placeholders = coordinateFallbackPlaces(
                destination: destination,
                destinationLocation: destinationLocation,
                existingCount: resolvedPlaces.count,
                targetPlaceCount: targetPlaceCount
            )
            appendUnique(placeholders, to: &resolvedPlaces, limit: targetPlaceCount)
        }

        return resolvedPlaces
    }

    private func resolvePlace(
        suggestion: MiniMaxPlaceSuggestion,
        destination: String,
        destinationLocation: DestinationLocation?,
        expectedCountryCode: String?
    ) async -> Place? {
        if let place = coordinateBackedPlace(
            from: suggestion,
            destinationLocation: destinationLocation,
            expectedCountryCode: expectedCountryCode
        ) {
            return place
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(suggestion.name) \(destination)"
        request.resultTypes = [.pointOfInterest, .address]

        if let destinationLocation {
            request.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: destinationLocation.latitude,
                    longitude: destinationLocation.longitude
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
            )
        }

        do {
            guard let response = try await search(request: request) else {
                return nil
            }
            guard let item = bestMapItem(
                from: response.mapItems,
                destinationLocation: destinationLocation,
                expectedCountryCode: expectedCountryCode
            ),
                  let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else {
                return nil
            }

            let coordinate = item.placemark.coordinate
            return Place(
                id: UUID(),
                name: name,
                address: formattedAddress(for: item.placemark),
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                providerIDs: [.mapKit: "mapkit-\(name)"]
            )
        } catch {
            return nil
        }
    }

    private func coordinateBackedPlace(
        from suggestion: MiniMaxPlaceSuggestion,
        destinationLocation: DestinationLocation?,
        expectedCountryCode: String?
    ) -> Place? {
        guard let latitude = suggestion.latitude,
              let longitude = suggestion.longitude,
              (-90...90).contains(latitude),
              (-180...180).contains(longitude) else {
            return nil
        }

        if let expectedCountryCode,
           let suggestionCountryCode = suggestion.countryCode?.uppercased(),
           suggestionCountryCode != expectedCountryCode {
            return nil
        }

        if let destinationLocation {
            let destination = CLLocation(
                latitude: destinationLocation.latitude,
                longitude: destinationLocation.longitude
            )
            let coordinate = CLLocation(latitude: latitude, longitude: longitude)
            guard destination.distance(from: coordinate) <= 80_000 else {
                return nil
            }
        }

        let name = suggestion.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return nil
        }

        return Place(
            id: UUID(),
            name: name,
            address: suggestion.address,
            latitude: latitude,
            longitude: longitude,
            providerIDs: [.mapKit: "ai-coordinate-\(name)"]
        )
    }

    private func search(request: MKLocalSearch.Request) async throws -> MKLocalSearch.Response? {
        try await withThrowingTaskGroup(of: MKLocalSearch.Response?.self) { group in
            group.addTask {
                try await MKLocalSearch(request: request).start()
            }
            group.addTask {
                try await Task.sleep(for: .seconds(4))
                return nil
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    private func supplementaryPlaces(
        destination: String,
        destinationLocation: DestinationLocation,
        expectedCountryCode: String?,
        existingPlaces: [Place],
        targetPlaceCount: Int
    ) async -> [Place] {
        let queries = [
            "landmark",
            "museum",
            "park",
            "market",
            "shopping",
            "restaurant",
            "cafe",
            "viewpoint",
            "garden",
            "historic site",
            "gallery",
            "neighborhood"
        ]
        var places: [Place] = []

        for query in queries {
            guard existingPlaces.count + places.count < targetPlaceCount else {
                break
            }

            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = "\(query) \(destination)"
            request.resultTypes = [.pointOfInterest]
            request.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: destinationLocation.latitude,
                    longitude: destinationLocation.longitude
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.45, longitudeDelta: 0.45)
            )

            guard let response = try? await search(request: request) else {
                continue
            }

            let candidates = response.mapItems.compactMap { item -> Place? in
                guard countryMatches(item.placemark, expectedCountryCode: expectedCountryCode),
                      let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !name.isEmpty else {
                    return nil
                }

                let coordinate = item.placemark.coordinate
                return Place(
                    id: UUID(),
                    name: name,
                    address: formattedAddress(for: item.placemark),
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    providerIDs: [.mapKit: "supplement-\(query)-\(name)"]
                )
            }

            appendUnique(candidates, to: &places, limit: targetPlaceCount - existingPlaces.count)
        }

        return places
    }

    private func coordinateFallbackPlaces(
        destination: String,
        destinationLocation: DestinationLocation,
        existingCount: Int,
        targetPlaceCount: Int
    ) -> [Place] {
        guard existingCount < targetPlaceCount else {
            return []
        }

        return ((existingCount + 1)...targetPlaceCount).map { index in
            let angle = Double(index) * 0.85
            let radius = 0.006 + Double(index % 4) * 0.002
            let latitude = destinationLocation.latitude + cos(angle) * radius
            let longitude = destinationLocation.longitude + sin(angle) * radius
            return Place(
                id: UUID(),
                name: "\(destination) Day \(index) 探索点",
                address: destinationLocation.displayName,
                latitude: latitude,
                longitude: longitude,
                providerIDs: [.mapKit: "coordinate-fallback-\(destination)-\(index)"]
            )
        }
    }

    private func appendUnique(_ places: [Place], to resolvedPlaces: inout [Place], limit: Int) {
        for place in places {
            guard resolvedPlaces.count < limit else {
                return
            }

            let normalizedName = place.name
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                .lowercased()
            let isDuplicate = resolvedPlaces.contains { existingPlace in
                existingPlace.name
                    .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                    .lowercased() == normalizedName
            }

            if !isDuplicate {
                resolvedPlaces.append(place)
            }
        }
    }

    private func bestMapItem(
        from items: [MKMapItem],
        destinationLocation: DestinationLocation?,
        expectedCountryCode: String?
    ) -> MKMapItem? {
        guard let destinationLocation else {
            return items.first { item in
                countryMatches(item.placemark, expectedCountryCode: expectedCountryCode)
            } ?? items.first
        }

        let destination = CLLocation(
            latitude: destinationLocation.latitude,
            longitude: destinationLocation.longitude
        )

        return items
            .map { item in
                (
                    item,
                    destination.distance(
                        from: CLLocation(
                            latitude: item.placemark.coordinate.latitude,
                            longitude: item.placemark.coordinate.longitude
                        )
                    )
                )
            }
            .filter { _, distance in
                distance <= 80_000
            }
            .filter { item, _ in
                countryMatches(item.placemark, expectedCountryCode: expectedCountryCode)
            }
            .sorted { lhs, rhs in
                lhs.1 < rhs.1
            }
            .first?
            .0
    }

    private func countryMatches(_ placemark: MKPlacemark, expectedCountryCode: String?) -> Bool {
        guard let expectedCountryCode else {
            return true
        }

        guard let countryCode = placemark.countryCode?.uppercased(), !countryCode.isEmpty else {
            return true
        }

        return countryCode == expectedCountryCode
    }

    private func expectedCountryCode(for destination: String) -> String? {
        let normalized = destination
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        if normalized.contains("france") || normalized.contains("paris") || normalized.contains("法国") || normalized.contains("巴黎") {
            return "FR"
        }

        if normalized.contains("united kingdom") || normalized.contains("uk") || normalized.contains("london") || normalized.contains("英国") || normalized.contains("伦敦") {
            return "GB"
        }

        if normalized.contains("japan") || normalized.contains("osaka") || normalized.contains("tokyo") || normalized.contains("日本") || normalized.contains("大阪") || normalized.contains("东京") || normalized.contains("東京") {
            return "JP"
        }

        return nil
    }

    private static func knownPlaces(for destination: String) -> [Place]? {
        let normalized = destination
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        if normalized.contains("paris") || normalized.contains("巴黎") {
            return [
                place(name: "Place des Vosges", address: "Paris, France", latitude: 48.8556, longitude: 2.3655),
                place(name: "Le Marais", address: "Paris, France", latitude: 48.8575, longitude: 2.3583),
                place(name: "Canal Saint-Martin", address: "Paris, France", latitude: 48.8707, longitude: 2.3650),
                place(name: "Galeries Lafayette Haussmann", address: "Paris, France", latitude: 48.8738, longitude: 2.3320),
                place(name: "Marché d'Aligre", address: "Paris, France", latitude: 48.8497, longitude: 2.3789),
                place(name: "Musée d'Orsay", address: "Paris, France", latitude: 48.8600, longitude: 2.3266),
                place(name: "Jardin du Luxembourg", address: "Paris, France", latitude: 48.8462, longitude: 2.3372),
                place(name: "Montmartre", address: "Paris, France", latitude: 48.8867, longitude: 2.3431),
                place(name: "Opéra Garnier", address: "Paris, France", latitude: 48.8719, longitude: 2.3316),
                place(name: "Centre Pompidou", address: "Paris, France", latitude: 48.8606, longitude: 2.3522),
                place(name: "Coulée Verte René-Dumont", address: "Paris, France", latitude: 48.8464, longitude: 2.3716),
                place(name: "Rue des Martyrs", address: "Paris, France", latitude: 48.8797, longitude: 2.3375)
            ]
        }

        if normalized.contains("london") || normalized.contains("伦敦") {
            return [
                place(name: "Covent Garden", address: "London, United Kingdom", latitude: 51.5117, longitude: -0.1240),
                place(name: "Neal's Yard", address: "London, United Kingdom", latitude: 51.5144, longitude: -0.1268),
                place(name: "British Museum", address: "London, United Kingdom", latitude: 51.5194, longitude: -0.1270),
                place(name: "South Bank", address: "London, United Kingdom", latitude: 51.5067, longitude: -0.1163),
                place(name: "Borough Market", address: "London, United Kingdom", latitude: 51.5055, longitude: -0.0910),
                place(name: "Tate Modern", address: "London, United Kingdom", latitude: 51.5076, longitude: -0.0994),
                place(name: "Hyde Park", address: "London, United Kingdom", latitude: 51.5073, longitude: -0.1657),
                place(name: "Kensington Palace", address: "London, United Kingdom", latitude: 51.5050, longitude: -0.1877),
                place(name: "Harrods", address: "London, United Kingdom", latitude: 51.4994, longitude: -0.1632),
                place(name: "Camden Market", address: "London, United Kingdom", latitude: 51.5416, longitude: -0.1469),
                place(name: "Regent's Park", address: "London, United Kingdom", latitude: 51.5313, longitude: -0.1569),
                place(name: "Primrose Hill", address: "London, United Kingdom", latitude: 51.5390, longitude: -0.1607)
            ]
        }

        if normalized.contains("osaka") || normalized.contains("大阪") {
            return [
                place(name: "Osaka Castle", address: "Osaka, Japan", latitude: 34.6873, longitude: 135.5262),
                place(name: "Kuromon Market", address: "Osaka, Japan", latitude: 34.6647, longitude: 135.5065),
                place(name: "Dotonbori", address: "Osaka, Japan", latitude: 34.6687, longitude: 135.5013),
                place(name: "Shinsaibashi Shopping Arcade", address: "Osaka, Japan", latitude: 34.6740, longitude: 135.5011),
                place(name: "Nakanoshima Park", address: "Osaka, Japan", latitude: 34.6937, longitude: 135.5034),
                place(name: "Umeda Sky Building", address: "Osaka, Japan", latitude: 34.7053, longitude: 135.4896),
                place(name: "Shinsekai", address: "Osaka, Japan", latitude: 34.6525, longitude: 135.5063),
                place(name: "Tsutenkaku", address: "Osaka, Japan", latitude: 34.6525, longitude: 135.5063),
                place(name: "Tennoji Park", address: "Osaka, Japan", latitude: 34.6500, longitude: 135.5110),
                place(name: "America-mura", address: "Osaka, Japan", latitude: 34.6723, longitude: 135.4972),
                place(name: "Hozenji Yokocho", address: "Osaka, Japan", latitude: 34.6678, longitude: 135.5032)
            ]
        }

        return nil
    }

    private static func place(
        name: String,
        address: String,
        latitude: Double,
        longitude: Double
    ) -> Place {
        Place(
            id: UUID(),
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
            providerIDs: [.mapKit: "seed-\(name)"]
        )
    }

    private func formattedAddress(for placemark: MKPlacemark) -> String? {
        [
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country
        ]
        .compactMap { value in
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed?.isEmpty == false ? trimmed : nil
        }
        .joined(separator: ", ")
        .nilIfEmpty
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
