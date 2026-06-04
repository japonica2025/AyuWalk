import Foundation

public struct Trip: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var englishProductName: String
    public var destination: String
    public var purpose: [TravelPurpose]
    public var duration: TripDuration
    public var days: [TripDay]
    public var participants: [Participant]
    public var importedSources: [ImportedSource]
    public var budgetPlan: BudgetPlan?
    public var packingList: PackingList?
    public var journalPages: [JournalPage]
    public var planningScripts: [PlanningScript]

    public init(
        id: UUID,
        title: String,
        englishProductName: String,
        destination: String,
        purpose: [TravelPurpose],
        duration: TripDuration,
        days: [TripDay],
        participants: [Participant],
        importedSources: [ImportedSource],
        budgetPlan: BudgetPlan?,
        packingList: PackingList?,
        journalPages: [JournalPage],
        planningScripts: [PlanningScript]
    ) {
        self.id = id
        self.title = title
        self.englishProductName = englishProductName
        self.destination = destination
        self.purpose = purpose
        self.duration = duration
        self.days = days
        self.participants = participants
        self.importedSources = importedSources
        self.budgetPlan = budgetPlan
        self.packingList = packingList
        self.journalPages = journalPages
        self.planningScripts = planningScripts
    }
}

public enum TravelPurpose: String, CaseIterable, Codable, Equatable, Sendable {
    case concert
    case honeymoon
    case family
    case friends
    case cityWalk
    case shopping
    case food
}

public enum TripDuration: Codable, Equatable, Sendable {
    case dayCount(Int)
    case dateRange(start: Date, end: Date)
}

public enum TripPlanningLimits {
    public static let minimumDayCount = 1
    public static let maximumDayCount = 14

    public static func normalizedDayCount(_ dayCount: Int) -> Int {
        min(max(dayCount, minimumDayCount), maximumDayCount)
    }
}

public struct DestinationLocation: Codable, Equatable, Sendable {
    public var latitude: Double
    public var longitude: Double
    public var displayName: String
    public var countryCode: String?
    public var currencyCode: String
    public var administrativeLevel: DestinationAdministrativeLevel

    public init(
        latitude: Double,
        longitude: Double,
        displayName: String,
        countryCode: String? = nil,
        currencyCode: String = "CNY",
        administrativeLevel: DestinationAdministrativeLevel = .city
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.displayName = displayName
        self.countryCode = countryCode
        self.currencyCode = currencyCode
        self.administrativeLevel = administrativeLevel
    }
}

public enum DestinationAdministrativeLevel: String, Codable, Equatable, Sendable {
    case country
    case province
    case city
    case region
    case unknown
}

public struct TripDay: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var dayNumber: Int
    public var dateLabel: String
    public var title: String
    public var activities: [Activity]

    public init(
        id: UUID,
        dayNumber: Int,
        dateLabel: String,
        title: String,
        activities: [Activity]
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.dateLabel = dateLabel
        self.title = title
        self.activities = activities
    }
}

public struct Activity: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var kind: ActivityKind
    public var place: Place?
    public var startTime: String?
    public var endTime: String?
    public var notes: String?
    public var estimatedCost: Decimal?
    public var routeOrder: Int?
    public var reminder: Reminder?

    public init(
        id: UUID,
        title: String,
        kind: ActivityKind,
        place: Place?,
        startTime: String?,
        endTime: String?,
        notes: String?,
        estimatedCost: Decimal?,
        routeOrder: Int?,
        reminder: Reminder?
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.place = place
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
        self.estimatedCost = estimatedCost
        self.routeOrder = routeOrder
        self.reminder = reminder
    }
}

public enum ActivityKind: String, Codable, Equatable, Sendable {
    case sight
    case meal
    case hotel
    case transport
    case shopping
    case concert
    case freeTime
    case note
}

public struct Place: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var address: String?
    public var latitude: Double?
    public var longitude: Double?
    public var providerIDs: [MapProviderKind: String]

    public init(
        id: UUID,
        name: String,
        address: String?,
        latitude: Double?,
        longitude: Double?,
        providerIDs: [MapProviderKind: String]
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.providerIDs = providerIDs
    }
}

public enum MapProviderKind: String, Codable, Hashable, Sendable {
    case mapKit
    case google
    case mapbox
}

public struct Participant: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var role: String?

    public init(id: UUID, name: String, role: String?) {
        self.id = id
        self.name = name
        self.role = role
    }
}

public struct ImportedSource: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var kind: ImportedSourceKind
    public var title: String
    public var url: URL?
    public var extractedText: String?

    public init(
        id: UUID,
        kind: ImportedSourceKind,
        title: String,
        url: URL?,
        extractedText: String?
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.url = url
        self.extractedText = extractedText
    }
}

public enum ImportedSourceKind: String, Codable, Equatable, Sendable {
    case screenshot
    case pastedText
    case futureLink
}

public struct BudgetPlan: Codable, Equatable, Sendable {
    public var total: Decimal
    public var currencyCode: String

    public init(total: Decimal, currencyCode: String) {
        self.total = total
        self.currencyCode = currencyCode
    }
}

public struct PackingList: Codable, Equatable, Sendable {
    public var items: [PackingItem]

    public init(items: [PackingItem]) {
        self.items = items
    }
}

public struct PackingItem: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var isPacked: Bool
    public var notes: String?

    public init(id: UUID, title: String, isPacked: Bool, notes: String?) {
        self.id = id
        self.title = title
        self.isPacked = isPacked
        self.notes = notes
    }
}

public struct JournalPage: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var kind: JournalPageKind
    public var title: String
    public var dayID: UUID?
    public var blocks: [JournalBlock]

    public init(
        id: UUID,
        kind: JournalPageKind,
        title: String,
        dayID: UUID?,
        blocks: [JournalBlock]
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.dayID = dayID
        self.blocks = blocks
    }
}

public enum JournalPageKind: String, Codable, Equatable, Sendable {
    case cover
    case overview
    case day
    case summary
}

public struct JournalBlock: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var kind: JournalBlockKind
    public var title: String?
    public var text: String?
    public var assetReference: String?
    public var isDefaultSelected: Bool

    public init(
        id: UUID,
        kind: JournalBlockKind,
        title: String?,
        text: String?,
        assetReference: String?,
        isDefaultSelected: Bool
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.text = text
        self.assetReference = assetReference
        self.isDefaultSelected = isDefaultSelected
    }
}

public enum JournalBlockKind: String, Codable, Equatable, Sendable {
    case title
    case dateLocation
    case photo
    case text
    case mapSnapshot
    case routeSummary
    case timeline
    case placeHighlights
    case budgetSummary
    case packingSummary
    case mood
    case sticker
}

public struct Reminder: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var fireTime: String
    public var note: String?

    public init(id: UUID, fireTime: String, note: String?) {
        self.id = id
        self.fireTime = fireTime
        self.note = note
    }
}

public struct PlanningScript: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var summary: String

    public init(id: UUID, name: String, summary: String) {
        self.id = id
        self.name = name
        self.summary = summary
    }
}
