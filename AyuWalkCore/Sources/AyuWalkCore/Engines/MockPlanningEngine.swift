import Foundation

public struct MockPlanningEngine: Sendable {
    public init() {}

    public func generateTrip(
        destination: String,
        dayCount: Int,
        purpose: [TravelPurpose],
        notes: String,
        importedSources: [ImportedSource] = [],
        destinationLocation: DestinationLocation? = nil,
        resolvedPlaces: [Place] = []
    ) -> Trip {
        let normalizedDayCount = TripPlanningLimits.normalizedDayCount(dayCount)
        var trip: Trip
        if !resolvedPlaces.isEmpty {
            trip = SampleTripFactory.trip(
                destination: destination,
                dayCount: normalizedDayCount,
                places: resolvedPlaces
            )
        } else if let destinationLocation {
            trip = SampleTripFactory.localizedTrip(
                destination: destination,
                dayCount: normalizedDayCount,
                location: destinationLocation
            )
        } else {
            trip = SampleTripFactory.trip(
                for: destination,
                dayCount: normalizedDayCount
            )
        }
        trip.title = "\(destination) \(normalizedDayCount) 日旅行"
        trip.destination = destination
        trip.duration = .dayCount(normalizedDayCount)
        trip.purpose = purpose
        trip.importedSources = importedSources.isEmpty ? [
            ImportedSource(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000701")!,
                kind: .pastedText,
                title: "用户想法",
                url: nil,
                extractedText: notes
            )
        ] : importedSources
        return trip
    }
}
