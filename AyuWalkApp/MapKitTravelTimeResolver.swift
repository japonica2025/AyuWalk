import AyuWalkCore
import CoreLocation
import Foundation
import MapKit

struct MapKitTravelTimeResolver {
    func travelMinutesBeforeActivityID(for day: TripDay) async -> [UUID: Int] {
        let routeActivities = DayRouteSequence.activities(in: day)

        guard routeActivities.count > 1 else {
            return [:]
        }

        var minutesByActivityID: [UUID: Int] = [:]
        for index in routeActivities.indices.dropFirst() {
            let previousActivity = routeActivities[index - 1]
            let activity = routeActivities[index]
            guard let previousCoordinate = coordinate(for: previousActivity),
                  let coordinate = coordinate(for: activity) else {
                continue
            }

            let minutes = await travelMinutes(
                from: previousCoordinate,
                to: coordinate
            )
            minutesByActivityID[activity.id] = minutes
        }

        return minutesByActivityID
    }

    private func travelMinutes(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async -> Int {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = transportType(from: source, to: destination)

        do {
            guard let response = try await calculate(request: request),
                  let route = response.routes.min(by: { $0.expectedTravelTime < $1.expectedTravelTime }) else {
                return fallbackTravelMinutes(from: source, to: destination)
            }

            return max(Int(ceil(route.expectedTravelTime / 60)), 5)
        } catch {
            return fallbackTravelMinutes(from: source, to: destination)
        }
    }

    private func calculate(request: MKDirections.Request) async throws -> MKDirections.Response? {
        try await withThrowingTaskGroup(of: MKDirections.Response?.self) { group in
            group.addTask {
                try await MKDirections(request: request).calculate()
            }
            group.addTask {
                try await Task.sleep(for: .seconds(5))
                return nil
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    private func transportType(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) -> MKDirectionsTransportType {
        let distance = CLLocation(latitude: source.latitude, longitude: source.longitude)
            .distance(from: CLLocation(latitude: destination.latitude, longitude: destination.longitude))
        return distance <= 1_800 ? .walking : .automobile
    }

    private func fallbackTravelMinutes(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) -> Int {
        let distance = CLLocation(latitude: source.latitude, longitude: source.longitude)
            .distance(from: CLLocation(latitude: destination.latitude, longitude: destination.longitude))
        let metersPerMinute = distance <= 1_800 ? 75.0 : 420.0
        return max(Int(ceil(distance / metersPerMinute)), 5)
    }

    private func coordinate(for activity: Activity) -> CLLocationCoordinate2D? {
        guard let latitude = activity.place?.latitude,
              let longitude = activity.place?.longitude else {
            return nil
        }

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
