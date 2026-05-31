import Foundation

public struct Trip: Equatable, Identifiable, Sendable {
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

public enum TravelPurpose: Equatable, Sendable {
    case cityWalk
    case food
    case culture
    case nature
    case shopping
    case family
    case relaxation
    case business
    case photography
    case other(String)
}

public enum TripDuration: Equatable, Sendable {
    case dayCount(Int)
    case dateRange(startDate: String, endDate: String)
    case openEnded
}

public struct TripDay: Equatable, Identifiable, Sendable {
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

public struct Activity: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var kind: ActivityKind
    public var place: Place?
    public var startTime: String?
    public var endTime: String?
    public var notes: String?
    public var estimatedCost: Decimal?
    public var routeOrder: Int
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
        routeOrder: Int,
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

public enum ActivityKind: Equatable, Sendable {
    case sight
    case meal
    case transport
    case hotel
    case shopping
    case experience
    case rest
    case custom(String)
}

public struct Place: Equatable, Identifiable, Sendable {
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

public enum MapProviderKind: Equatable, Hashable, Sendable {
    case mapKit
    case googleMaps
    case amap
    case custom(String)
}

public struct Participant: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var role: String?

    public init(id: UUID, name: String, role: String?) {
        self.id = id
        self.name = name
        self.role = role
    }
}

public struct ImportedSource: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var kind: ImportedSourceKind
    public var title: String
    public var url: URL?
    public var rawText: String?

    public init(
        id: UUID,
        kind: ImportedSourceKind,
        title: String,
        url: URL?,
        rawText: String?
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.url = url
        self.rawText = rawText
    }
}

public enum ImportedSourceKind: Equatable, Sendable {
    case url
    case document
    case image
    case note
    case custom(String)
}

public struct BudgetPlan: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var currencyCode: String
    public var totalBudget: Decimal?
    public var categoryBudgets: [String: Decimal]

    public init(
        id: UUID,
        currencyCode: String,
        totalBudget: Decimal?,
        categoryBudgets: [String: Decimal]
    ) {
        self.id = id
        self.currencyCode = currencyCode
        self.totalBudget = totalBudget
        self.categoryBudgets = categoryBudgets
    }
}

public struct PackingList: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var items: [PackingItem]

    public init(id: UUID, title: String, items: [PackingItem]) {
        self.id = id
        self.title = title
        self.items = items
    }
}

public struct PackingItem: Equatable, Identifiable, Sendable {
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

public struct JournalPage: Equatable, Identifiable, Sendable {
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

public enum JournalPageKind: Equatable, Sendable {
    case cover
    case daily
    case summary
    case custom(String)
}

public struct JournalBlock: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var kind: JournalBlockKind
    public var title: String?
    public var text: String?
    public var assetReference: String?

    public init(
        id: UUID,
        kind: JournalBlockKind,
        title: String?,
        text: String?,
        assetReference: String?
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.text = text
        self.assetReference = assetReference
    }
}

public enum JournalBlockKind: Equatable, Sendable {
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
    case custom(String)
}

public struct Reminder: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var fireTime: String
    public var note: String?

    public init(id: UUID, fireTime: String, note: String?) {
        self.id = id
        self.fireTime = fireTime
        self.note = note
    }
}

public struct PlanningScript: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var prompt: String
    public var output: String?

    public init(id: UUID, title: String, prompt: String, output: String?) {
        self.id = id
        self.title = title
        self.prompt = prompt
        self.output = output
    }
}
