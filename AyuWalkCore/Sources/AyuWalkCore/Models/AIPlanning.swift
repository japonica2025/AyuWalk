import Foundation

public struct AIPlanningRequest: Codable, Equatable, Sendable {
    public var destination: String
    public var dayCount: Int
    public var purpose: [TravelPurpose]
    public var notes: String
    public var importedText: String?
    public var adjustmentRequest: String?

    public init(
        destination: String,
        dayCount: Int,
        purpose: [TravelPurpose],
        notes: String,
        importedText: String?,
        adjustmentRequest: String?
    ) {
        self.destination = destination
        self.dayCount = dayCount
        self.purpose = purpose
        self.notes = notes
        self.importedText = importedText
        self.adjustmentRequest = adjustmentRequest
    }
}

public struct AIPlanningQuestion: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var prompt: String
    public var options: [String]
    public var isRequired: Bool

    public init(id: String, prompt: String, options: [String], isRequired: Bool) {
        self.id = id
        self.prompt = prompt
        self.options = options
        self.isRequired = isRequired
    }
}

public struct AIPlanningAssumption: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var text: String

    public init(id: String, text: String) {
        self.id = id
        self.text = text
    }
}

public enum AIPlanningSource: String, Codable, Equatable, Sendable {
    case remoteAI
    case fallback
}

public struct AIPlannedPlace: Codable, Equatable, Sendable {
    public var name: String
    public var address: String?
    public var latitude: Double?
    public var longitude: Double?

    public init(name: String, address: String?, latitude: Double?, longitude: Double?) {
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct AIPlannedActivity: Codable, Equatable, Sendable {
    public var title: String
    public var kind: ActivityKind
    public var place: AIPlannedPlace?
    public var startTime: String?
    public var endTime: String?
    public var notes: String?
    public var estimatedCost: Decimal?
    public var isFixedNode: Bool

    public init(
        title: String,
        kind: ActivityKind,
        place: AIPlannedPlace?,
        startTime: String?,
        endTime: String?,
        notes: String?,
        estimatedCost: Decimal?,
        isFixedNode: Bool
    ) {
        self.title = title
        self.kind = kind
        self.place = place
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
        self.estimatedCost = estimatedCost
        self.isFixedNode = isFixedNode
    }
}

public struct AIPlannedDay: Codable, Equatable, Sendable {
    public var dayNumber: Int
    public var title: String
    public var activities: [AIPlannedActivity]

    public init(dayNumber: Int, title: String, activities: [AIPlannedActivity]) {
        self.dayNumber = dayNumber
        self.title = title
        self.activities = activities
    }
}

public struct AIPlanningProposal: Codable, Equatable, Sendable {
    public var confidence: Double
    public var questions: [AIPlanningQuestion]
    public var assumptions: [AIPlanningAssumption]
    public var adjustmentReason: String?
    public var days: [AIPlannedDay]
    public var source: AIPlanningSource

    public init(
        confidence: Double,
        questions: [AIPlanningQuestion],
        assumptions: [AIPlanningAssumption],
        adjustmentReason: String?,
        days: [AIPlannedDay],
        source: AIPlanningSource
    ) {
        self.confidence = confidence
        self.questions = questions
        self.assumptions = assumptions
        self.adjustmentReason = adjustmentReason
        self.days = days
        self.source = source
    }
}

public enum AIPlanningProposalNormalizer {
    public static func normalize(_ proposal: AIPlanningProposal, dayCount: Int) -> AIPlanningProposal {
        let normalizedDayCount = TripPlanningLimits.normalizedDayCount(dayCount)
        let questions = proposal.questions.compactMap { question -> AIPlanningQuestion? in
            let prompt = trimmed(question.prompt)
            guard !prompt.isEmpty else {
                return nil
            }
            return AIPlanningQuestion(
                id: trimmed(question.id),
                prompt: prompt,
                options: question.options.map(trimmed).filter { !$0.isEmpty },
                isRequired: question.isRequired
            )
        }
        let assumptions = proposal.assumptions.compactMap { assumption -> AIPlanningAssumption? in
            let text = trimmed(assumption.text)
            guard !text.isEmpty else {
                return nil
            }
            return AIPlanningAssumption(id: trimmed(assumption.id), text: text)
        }
        let days = proposal.days.compactMap { day -> AIPlannedDay? in
            let dayNumber = min(max(day.dayNumber, 1), normalizedDayCount)
            let activities = day.activities.compactMap(normalize)
            guard !activities.isEmpty else {
                return nil
            }
            let title = trimmed(day.title)
            return AIPlannedDay(
                dayNumber: dayNumber,
                title: title.isEmpty ? "Day \(dayNumber)" : title,
                activities: activities
            )
        }

        return AIPlanningProposal(
            confidence: min(max(proposal.confidence, 0), 1),
            questions: questions,
            assumptions: assumptions,
            adjustmentReason: optionalTrimmed(proposal.adjustmentReason),
            days: days,
            source: proposal.source
        )
    }

    private static func normalize(_ activity: AIPlannedActivity) -> AIPlannedActivity? {
        let title = trimmed(activity.title)
        guard !title.isEmpty else {
            return nil
        }
        return AIPlannedActivity(
            title: title,
            kind: activity.kind,
            place: activity.place,
            startTime: optionalTrimmed(activity.startTime),
            endTime: optionalTrimmed(activity.endTime),
            notes: optionalTrimmed(activity.notes),
            estimatedCost: activity.estimatedCost,
            isFixedNode: activity.isFixedNode
        )
    }

    private static func optionalTrimmed(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let result = trimmed(value)
        return result.isEmpty ? nil : result
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public enum AIPlanningClarificationPolicy {
    public static func questions(for request: AIPlanningRequest) -> [AIPlanningQuestion] {
        var questions: [AIPlanningQuestion] = []
        if request.purpose.isEmpty {
            questions.append(
                AIPlanningQuestion(
                    id: "purpose",
                    prompt: "这次旅行最想优先安排什么？",
                    options: ["城市散步", "美食", "购物", "亲友同行"],
                    isRequired: true
                )
            )
        }

        let details = [request.notes, request.importedText, request.adjustmentRequest]
            .compactMap { $0 }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if details.count < 20 {
            questions.append(
                AIPlanningQuestion(
                    id: "pace",
                    prompt: "希望行程节奏如何？",
                    options: ["轻松", "均衡", "充实"],
                    isRequired: false
                )
            )
        }
        return questions
    }
}

public enum AITripProposalApplicationMode: Sendable {
    case replaceOrdinaryActivities
    case preserveExistingOrdinaryActivities
}

public enum AITripProposalApplier {
    public static func apply(
        _ proposal: AIPlanningProposal,
        to trip: Trip,
        resolvedPlaces: [Place] = [],
        mode: AITripProposalApplicationMode = .replaceOrdinaryActivities
    ) -> Trip {
        var result = trip
        let normalized = AIPlanningProposalNormalizer.normalize(proposal, dayCount: trip.days.count)
        for plannedDay in normalized.days {
            guard let dayIndex = result.days.firstIndex(where: { $0.dayNumber == plannedDay.dayNumber }) else {
                continue
            }
            let existingActivities = result.days[dayIndex].activities
            let fixedNodes = result.days[dayIndex].activities.filter(\.isFixedNode)
            let plannedActivities = plannedDay.activities
                .filter { !$0.isFixedNode }
                .enumerated()
                .map { index, activity in
                Activity(
                    id: UUID(),
                    title: activity.title,
                    kind: activity.kind,
                    place: place(for: activity, resolvedPlaces: resolvedPlaces),
                    startTime: activity.startTime,
                    endTime: activity.endTime,
                    notes: activity.notes,
                    estimatedCost: activity.estimatedCost,
                    routeOrder: index + 1,
                    reminder: nil,
                    isFixedNode: false
                )
            }
            result.days[dayIndex].title = plannedDay.title
            switch mode {
            case .replaceOrdinaryActivities:
                result.days[dayIndex].activities = plannedActivities + fixedNodes
            case .preserveExistingOrdinaryActivities:
                let newActivities = plannedActivities.filter { plannedActivity in
                    !existingActivities.contains { existingActivity in
                        normalizedTitle(existingActivity.title) == normalizedTitle(plannedActivity.title)
                    }
                }
                let nextRouteOrder = (existingActivities.compactMap(\.routeOrder).max() ?? 0) + 1
                let appendedActivities = newActivities.enumerated().map { index, activity in
                    var result = activity
                    result.routeOrder = nextRouteOrder + index
                    return result
                }
                result.days[dayIndex].activities = existingActivities + appendedActivities
            }
        }
        return result
    }

    private static func place(for activity: AIPlannedActivity, resolvedPlaces: [Place]) -> Place? {
        guard let plannedPlace = activity.place else {
            return nil
        }
        if let resolvedPlace = resolvedPlaces.first(where: { isLikelySamePlace($0, plannedPlace: plannedPlace, activityTitle: activity.title) }) {
            return resolvedPlace
        }

        if !resolvedPlaces.isEmpty {
            return Place(
                id: UUID(),
                name: plannedPlace.name,
                address: plannedPlace.address,
                latitude: nil,
                longitude: nil,
                providerIDs: [:]
            )
        }

        return Place(
            id: UUID(),
            name: plannedPlace.name,
            address: plannedPlace.address,
            latitude: plannedPlace.latitude,
            longitude: plannedPlace.longitude,
            providerIDs: [:]
        )
    }

    private static func isLikelySamePlace(_ place: Place, plannedPlace: AIPlannedPlace, activityTitle: String) -> Bool {
        let placeName = normalizedTitle(place.name)
        return placeName == normalizedTitle(plannedPlace.name)
            || placeName == normalizedTitle(activityTitle)
            || normalizedTitle(plannedPlace.name).contains(placeName)
            || placeName.contains(normalizedTitle(plannedPlace.name))
    }

    private static func normalizedTitle(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
    }
}

public enum AIPlanningResponseDecoder {
    public enum DecodeError: Error {
        case missingJSONObject
    }

    public static func decode(
        _ text: String,
        source: AIPlanningSource,
        dayCount: Int
    ) throws -> AIPlanningProposal {
        guard let json = extractJSONObject(from: text),
              let data = json.data(using: .utf8) else {
            throw DecodeError.missingJSONObject
        }
        let response = try JSONDecoder().decode(Response.self, from: data)
        let proposal = AIPlanningProposal(
            confidence: response.confidence,
            questions: response.questions,
            assumptions: response.assumptions,
            adjustmentReason: response.adjustmentReason,
            days: response.days.map { day in
                AIPlannedDay(
                    dayNumber: day.dayNumber,
                    title: day.title,
                    activities: day.activities.map { activity in
                        AIPlannedActivity(
                            title: activity.title,
                            kind: ActivityKind(rawValue: activity.kind) ?? .note,
                            place: activity.place,
                            startTime: activity.startTime,
                            endTime: activity.endTime,
                            notes: activity.notes,
                            estimatedCost: activity.estimatedCost,
                            isFixedNode: activity.isFixedNode
                        )
                    }
                )
            },
            source: source
        )
        return AIPlanningProposalNormalizer.normalize(proposal, dayCount: dayCount)
    }

    private static func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start <= end else {
            return nil
        }
        return String(text[start...end])
    }

    private struct Response: Decodable {
        var confidence: Double
        var questions: [AIPlanningQuestion]
        var assumptions: [AIPlanningAssumption]
        var adjustmentReason: String?
        var days: [Day]

        private enum CodingKeys: String, CodingKey {
            case confidence
            case questions
            case assumptions
            case adjustmentReason
            case days
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0.5
            questions = try container.decodeIfPresent([AIPlanningQuestion].self, forKey: .questions) ?? []
            assumptions = try container.decodeIfPresent([AIPlanningAssumption].self, forKey: .assumptions) ?? []
            adjustmentReason = try container.decodeIfPresent(String.self, forKey: .adjustmentReason)
            days = try container.decodeIfPresent([Day].self, forKey: .days) ?? []
        }
    }

    private struct Day: Decodable {
        var dayNumber: Int
        var title: String
        var activities: [ActivityResponse]

        private enum CodingKeys: String, CodingKey {
            case dayNumber
            case title
            case activities
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            dayNumber = try container.decodeIfPresent(Int.self, forKey: .dayNumber) ?? 1
            title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
            activities = try container.decodeIfPresent([ActivityResponse].self, forKey: .activities) ?? []
        }
    }

    private struct ActivityResponse: Decodable {
        var title: String
        var kind: String
        var place: AIPlannedPlace?
        var startTime: String?
        var endTime: String?
        var notes: String?
        var estimatedCost: Decimal?
        var isFixedNode: Bool

        private enum CodingKeys: String, CodingKey {
            case title
            case kind
            case place
            case startTime
            case endTime
            case notes
            case estimatedCost
            case isFixedNode
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
            kind = try container.decodeIfPresent(String.self, forKey: .kind) ?? ActivityKind.note.rawValue
            place = try container.decodeIfPresent(AIPlannedPlace.self, forKey: .place)
            startTime = try container.decodeIfPresent(String.self, forKey: .startTime)
            endTime = try container.decodeIfPresent(String.self, forKey: .endTime)
            notes = try container.decodeIfPresent(String.self, forKey: .notes)
            estimatedCost = try container.decodeIfPresent(Decimal.self, forKey: .estimatedCost)
            isFixedNode = try container.decodeIfPresent(Bool.self, forKey: .isFixedNode) ?? false
        }
    }
}
