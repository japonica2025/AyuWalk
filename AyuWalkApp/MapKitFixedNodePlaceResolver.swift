import AyuWalkCore
import CoreLocation
import Foundation
import MapKit

struct MapKitFixedNodePlaceResolver {
    func resolvePlace(
        for activity: Activity,
        destination: String,
        destinationLocation: DestinationLocation?
    ) async -> Place? {
        let query = searchQuery(for: activity, destination: destination)
        guard !query.isEmpty else {
            return nil
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.pointOfInterest, .address]
        if let destinationLocation {
            request.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: destinationLocation.latitude,
                    longitude: destinationLocation.longitude
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.8, longitudeDelta: 0.8)
            )
        }

        do {
            guard let response = try await search(request: request),
                  let item = response.mapItems.first,
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
                providerIDs: [.mapKit: "fixed-node-\(name)"]
            )
        } catch {
            return nil
        }
    }

    private func searchQuery(for activity: Activity, destination: String) -> String {
        let title = activity.title
            .replacingOccurrences(of: "固定交通：", with: "")
            .replacingOccurrences(of: "固定住宿：", with: "")
            .replacingOccurrences(of: "固定活动：", with: "")
            .replacingOccurrences(of: "固定节点：", with: "")
        let withoutTime = title.replacingOccurrences(
            of: #"([01]?\d|2[0-3])[:：][0-5]\d"#,
            with: "",
            options: .regularExpression
        )
        return "\(withoutTime) \(destination)"
            .trimmingCharacters(in: .whitespacesAndNewlines)
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

    private func formattedAddress(for placemark: MKPlacemark) -> String? {
        [
            placemark.subThoroughfare,
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: ", ")
    }
}
