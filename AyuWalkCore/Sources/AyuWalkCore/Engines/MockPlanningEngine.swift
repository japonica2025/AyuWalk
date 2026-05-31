import Foundation

public struct MockPlanningEngine: Sendable {
    public init() {}

    public func generateTrip(
        destination: String,
        dayCount: Int,
        purpose: [TravelPurpose],
        notes: String
    ) -> Trip {
        var trip = SampleTripFactory.tokyoFiveDayTrip()
        trip.destination = destination
        trip.duration = .dayCount(dayCount)
        trip.purpose = purpose
        trip.importedSources = [
            ImportedSource(
                id: UUID(),
                kind: .pastedText,
                title: "用户想法",
                url: nil,
                rawText: notes
            )
        ]
        return trip
    }
}
