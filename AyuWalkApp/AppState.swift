import AyuWalkCore
import Foundation
import Observation

@Observable
final class AppState {
    var trip: Trip
    var journalPages: [JournalPage]

    init(
        planningEngine: MockPlanningEngine = MockPlanningEngine(),
        journalEngine: MockJournalEngine = MockJournalEngine()
    ) {
        let trip = planningEngine.generateTrip(
            destination: "东京",
            dayCount: 5,
            purpose: [.cityWalk, .food],
            notes: "想要轻松一点，适合发小红书"
        )
        self.trip = trip
        self.journalPages = journalEngine.generatePages(for: trip)
    }
}
