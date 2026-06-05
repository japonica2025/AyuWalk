import Foundation

public struct TripWorkspace: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID { trip.id }

    public var trip: Trip
    public var journalPages: [JournalPage]
    public var journalSelections: [UUID: JournalModuleSelection]
    public var stickerSelections: [UUID: StickerSelection]
    public var customStickers: [Sticker]
    public var completedActivityIDs: Set<UUID>
    public var travelMinutesBeforeActivityID: [UUID: Int]
    public var enabledReminderActivityIDs: Set<UUID>
    public var isArchived: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        trip: Trip,
        journalPages: [JournalPage],
        journalSelections: [UUID: JournalModuleSelection],
        stickerSelections: [UUID: StickerSelection],
        customStickers: [Sticker],
        completedActivityIDs: Set<UUID>,
        travelMinutesBeforeActivityID: [UUID: Int] = [:],
        enabledReminderActivityIDs: Set<UUID> = [],
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.trip = trip
        self.journalPages = journalPages
        self.journalSelections = journalSelections
        self.stickerSelections = stickerSelections
        self.customStickers = customStickers
        self.completedActivityIDs = completedActivityIDs
        self.travelMinutesBeforeActivityID = travelMinutesBeforeActivityID
        self.enabledReminderActivityIDs = enabledReminderActivityIDs
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case trip
        case journalPages
        case journalSelections
        case stickerSelections
        case customStickers
        case completedActivityIDs
        case travelMinutesBeforeActivityID
        case enabledReminderActivityIDs
        case isArchived
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trip = try container.decode(Trip.self, forKey: .trip)
        journalPages = try container.decodeIfPresent([JournalPage].self, forKey: .journalPages) ?? trip.journalPages
        journalSelections = try container.decodeIfPresent([UUID: JournalModuleSelection].self, forKey: .journalSelections) ?? [:]
        stickerSelections = try container.decodeIfPresent([UUID: StickerSelection].self, forKey: .stickerSelections) ?? [:]
        customStickers = try container.decodeIfPresent([Sticker].self, forKey: .customStickers) ?? []
        completedActivityIDs = try container.decodeIfPresent(Set<UUID>.self, forKey: .completedActivityIDs) ?? []
        travelMinutesBeforeActivityID = try container.decodeIfPresent([UUID: Int].self, forKey: .travelMinutesBeforeActivityID) ?? [:]
        enabledReminderActivityIDs = try container.decodeIfPresent(Set<UUID>.self, forKey: .enabledReminderActivityIDs) ?? []
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }
}

public struct TripLibrary: Codable, Equatable, Sendable {
    public var activeTripID: UUID?
    public private(set) var workspaces: [TripWorkspace]

    public var activeWorkspace: TripWorkspace? {
        guard let activeTripID else {
            return nil
        }
        return workspaces.first { $0.id == activeTripID }
    }

    public init(activeTripID: UUID?, workspaces: [TripWorkspace]) {
        var seenIDs: Set<UUID> = []
        let normalizedWorkspaces = workspaces.map { workspace in
            guard !seenIDs.insert(workspace.id).inserted else {
                return workspace
            }
            var duplicator = TripWorkspaceDuplicator(titleSuffix: "", preservesMetadata: true)
            let repairedWorkspace = duplicator.duplicate(workspace)
            seenIDs.insert(repairedWorkspace.id)
            return repairedWorkspace
        }

        self.workspaces = normalizedWorkspaces
        if let activeTripID, normalizedWorkspaces.contains(where: { $0.id == activeTripID }) {
            self.activeTripID = activeTripID
        } else {
            self.activeTripID = Self.preferredActiveWorkspace(in: normalizedWorkspaces)?.id
        }
    }

    public mutating func selectTrip(id: UUID) {
        guard workspaces.contains(where: { $0.id == id }) else {
            return
        }
        activeTripID = id
    }

    public mutating func append(_ workspace: TripWorkspace, select: Bool = true) {
        workspaces.append(workspace)
        if select {
            activeTripID = workspace.id
        }
    }

    @discardableResult
    public mutating func appendNewWorkspace(_ workspace: TripWorkspace) -> UUID {
        var duplicator = TripWorkspaceDuplicator(titleSuffix: "", preservesMetadata: false)
        let uniqueWorkspace = duplicator.duplicate(workspace)
        append(uniqueWorkspace)
        return uniqueWorkspace.id
    }

    public mutating func updateActiveWorkspace(_ update: (inout TripWorkspace) -> Void) {
        guard let activeTripID,
              let index = workspaces.firstIndex(where: { $0.id == activeTripID }) else {
            return
        }
        update(&workspaces[index])
        workspaces[index].updatedAt = Date()
    }

    public mutating func renameTrip(id: UUID, title: String) {
        guard let index = workspaces.firstIndex(where: { $0.id == id }) else {
            return
        }
        workspaces[index].trip.title = title
        workspaces[index].updatedAt = Date()
    }

    public mutating func setArchived(_ isArchived: Bool, for id: UUID) {
        guard let index = workspaces.firstIndex(where: { $0.id == id }) else {
            return
        }
        workspaces[index].isArchived = isArchived
        workspaces[index].updatedAt = Date()
        if isArchived, activeTripID == id {
            activeTripID = Self.preferredActiveWorkspace(in: workspaces.filter { !$0.isArchived })?.id ?? id
        }
    }

    public mutating func deleteTrip(id: UUID) {
        workspaces.removeAll { $0.id == id }
        if activeTripID == id {
            activeTripID = Self.preferredActiveWorkspace(in: workspaces)?.id
        }
    }

    @discardableResult
    public mutating func duplicateTrip(id: UUID) -> UUID? {
        guard let source = workspaces.first(where: { $0.id == id }) else {
            return nil
        }
        var duplicator = TripWorkspaceDuplicator(titleSuffix: " 副本", preservesMetadata: false)
        let duplicate = duplicator.duplicate(source)
        append(duplicate)
        return duplicate.id
    }

    private static func preferredActiveWorkspace(in workspaces: [TripWorkspace]) -> TripWorkspace? {
        workspaces.first(where: { !$0.isArchived }) ?? workspaces.first
    }
}

private struct TripWorkspaceDuplicator {
    let titleSuffix: String
    let preservesMetadata: Bool
    private var ids: [UUID: UUID] = [:]
    private var customStickerIDs: [UUID: UUID] = [:]

    init(titleSuffix: String, preservesMetadata: Bool) {
        self.titleSuffix = titleSuffix
        self.preservesMetadata = preservesMetadata
    }

    mutating func duplicate(_ source: TripWorkspace) -> TripWorkspace {
        let customStickers = source.customStickers.map { sticker in
            let id = remap(sticker.id)
            customStickerIDs[sticker.id] = id
            return Sticker(id: id, title: sticker.title, symbol: sticker.symbol, imageDataBase64: sticker.imageDataBase64)
        }
        let journalPages = duplicatePages(source.journalPages)
        let trip = duplicateTrip(source.trip)
        let now = Date()

        return TripWorkspace(
            trip: trip,
            journalPages: journalPages,
            journalSelections: duplicateJournalSelections(source.journalSelections),
            stickerSelections: duplicateStickerSelections(source.stickerSelections),
            customStickers: customStickers,
            completedActivityIDs: Set(source.completedActivityIDs.compactMap { ids[$0] }),
            travelMinutesBeforeActivityID: Dictionary(
                uniqueKeysWithValues: source.travelMinutesBeforeActivityID.compactMap { key, value in
                    ids[key].map { ($0, value) }
                }
            ),
            enabledReminderActivityIDs: preservesMetadata
                ? Set(source.enabledReminderActivityIDs.compactMap { ids[$0] })
                : [],
            isArchived: preservesMetadata ? source.isArchived : false,
            createdAt: preservesMetadata ? source.createdAt : now,
            updatedAt: preservesMetadata ? source.updatedAt : now
        )
    }

    private mutating func duplicateTrip(_ source: Trip) -> Trip {
        let participants = source.participants.map {
            Participant(id: remap($0.id), name: $0.name, role: $0.role)
        }
        let days = source.days.map { day in
            TripDay(
                id: remap(day.id),
                dayNumber: day.dayNumber,
                dateLabel: day.dateLabel,
                title: day.title,
                activities: day.activities.map { duplicateActivity($0) }
            )
        }
        let budgetPlan = source.budgetPlan.map { budget in
            BudgetPlan(
                total: budget.total,
                currencyCode: budget.currencyCode,
                expenses: budget.expenses.map { expense in
                    BudgetExpense(
                        id: remap(expense.id),
                        title: expense.title,
                        amount: expense.amount,
                        category: expense.category,
                        participantIDs: expense.participantIDs.compactMap { ids[$0] },
                        notes: expense.notes
                    )
                }
            )
        }
        let packingList = source.packingList.map { list in
            PackingList(items: list.items.map {
                PackingItem(id: remap($0.id), title: $0.title, isPacked: $0.isPacked, notes: $0.notes)
            })
        }

        return Trip(
            id: remap(source.id),
            title: source.title + titleSuffix,
            englishProductName: source.englishProductName,
            destination: source.destination,
            purpose: source.purpose,
            duration: source.duration,
            days: days,
            participants: participants,
            importedSources: source.importedSources.map {
                ImportedSource(
                    id: remap($0.id),
                    kind: $0.kind,
                    title: $0.title,
                    url: $0.url,
                    extractedText: $0.extractedText
                )
            },
            budgetPlan: budgetPlan,
            packingList: packingList,
            journalPages: duplicatePages(source.journalPages),
            planningScripts: source.planningScripts.map {
                PlanningScript(id: remap($0.id), name: $0.name, summary: $0.summary)
            }
        )
    }

    private mutating func duplicateActivity(_ source: Activity) -> Activity {
        Activity(
            id: remap(source.id),
            title: source.title,
            kind: source.kind,
            place: source.place.map {
                Place(
                    id: remap($0.id),
                    name: $0.name,
                    address: $0.address,
                    latitude: $0.latitude,
                    longitude: $0.longitude,
                    providerIDs: $0.providerIDs
                )
            },
            startTime: source.startTime,
            endTime: source.endTime,
            notes: source.notes,
            estimatedCost: source.estimatedCost,
            routeOrder: source.routeOrder,
            reminder: source.reminder.map {
                Reminder(id: remap($0.id), fireTime: $0.fireTime, note: $0.note)
            },
            isFixedNode: source.isFixedNode
        )
    }

    private mutating func duplicatePages(_ source: [JournalPage]) -> [JournalPage] {
        source.map { page in
            JournalPage(
                id: remap(page.id),
                kind: page.kind,
                title: page.title,
                dayID: page.dayID.map { remap($0) },
                blocks: page.blocks.map {
                    JournalBlock(
                        id: remap($0.id),
                        kind: $0.kind,
                        title: $0.title,
                        text: $0.text,
                        assetReference: $0.assetReference,
                        isDefaultSelected: $0.isDefaultSelected
                    )
                }
            )
        }
    }

    private mutating func duplicateJournalSelections(
        _ source: [UUID: JournalModuleSelection]
    ) -> [UUID: JournalModuleSelection] {
        var result: [UUID: JournalModuleSelection] = [:]
        for (pageID, selection) in source {
            result[remap(pageID)] = JournalModuleSelection(
                selectedBlockIDs: Set(selection.selectedBlockIDs.map { remap($0) })
            )
        }
        return result
    }

    private mutating func duplicateStickerSelections(
        _ source: [UUID: StickerSelection]
    ) -> [UUID: StickerSelection] {
        var result: [UUID: StickerSelection] = [:]
        for (pageID, selection) in source {
            let selectedStickerIDs = Set(selection.selectedStickerIDs.map { remapSticker($0) })
            let placements = selection.placements.map {
                JournalStickerPlacement(
                    id: remap($0.id),
                    stickerID: remapSticker($0.stickerID),
                    xRatio: $0.xRatio,
                    yRatio: $0.yRatio,
                    scale: $0.scale,
                    rotationDegrees: $0.rotationDegrees
                )
            }
            result[remap(pageID)] = StickerSelection(
                selectedStickerIDs: selectedStickerIDs,
                placements: placements
            )
        }
        return result
    }

    private mutating func remapSticker(_ id: UUID) -> UUID {
        customStickerIDs[id] ?? id
    }

    private mutating func remap(_ id: UUID) -> UUID {
        if let mappedID = ids[id] {
            return mappedID
        }
        let mappedID = UUID()
        ids[id] = mappedID
        return mappedID
    }
}
