import AyuWalkCore
import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class AppState {
    var trip: Trip
    var journalPages: [JournalPage]
    var journalSelections: [UUID: JournalModuleSelection]
    var stickerSelections: [UUID: StickerSelection]
    var customStickers: [Sticker]
    var isGeneratingTrip: Bool
    var aiPlanningMessage: String?
    var travelMinutesBeforeActivityID: [UUID: Int]
    var enabledReminderActivityIDs: Set<UUID>
    var completedActivityIDs: Set<UUID>

    @ObservationIgnored private let planningEngine: MockPlanningEngine
    @ObservationIgnored private let journalEngine: MockJournalEngine
    @ObservationIgnored private let localStore: LocalAppStore
    @ObservationIgnored private let destinationGeocoder: DestinationGeocoder
    @ObservationIgnored private let aiPlanner: MiniMaxItineraryPlanner
    @ObservationIgnored private let placeResolver: MapKitPlaceResolver
    @ObservationIgnored private let travelTimeResolver: MapKitTravelTimeResolver
    @ObservationIgnored private let fixedNodePlaceResolver: MapKitFixedNodePlaceResolver
    @ObservationIgnored private static let customStickerCategoryID = UUID(
        uuidString: "00000000-0000-0000-0000-000000000706"
    )!

    init(
        planningEngine: MockPlanningEngine = MockPlanningEngine(),
        journalEngine: MockJournalEngine = MockJournalEngine(),
        localStore: LocalAppStore = .live(),
        destinationGeocoder: DestinationGeocoder = DestinationGeocoder(),
        aiPlanner: MiniMaxItineraryPlanner = MiniMaxItineraryPlanner(runtime: .live),
        placeResolver: MapKitPlaceResolver = MapKitPlaceResolver(),
        travelTimeResolver: MapKitTravelTimeResolver = MapKitTravelTimeResolver(),
        fixedNodePlaceResolver: MapKitFixedNodePlaceResolver = MapKitFixedNodePlaceResolver()
    ) {
        self.planningEngine = planningEngine
        self.journalEngine = journalEngine
        self.localStore = localStore
        self.destinationGeocoder = destinationGeocoder
        self.aiPlanner = aiPlanner
        self.placeResolver = placeResolver
        self.travelTimeResolver = travelTimeResolver
        self.fixedNodePlaceResolver = fixedNodePlaceResolver
        self.isGeneratingTrip = false
        self.aiPlanningMessage = nil
        self.travelMinutesBeforeActivityID = [:]
        self.enabledReminderActivityIDs = []
        self.completedActivityIDs = []

        if let snapshot = localStore.load() {
            if Self.needsRouteRepair(snapshot.trip) {
                let repairedTrip = planningEngine.generateTrip(
                    destination: snapshot.trip.destination,
                    dayCount: Self.dayCount(from: snapshot.trip.duration),
                    purpose: snapshot.trip.purpose,
                    notes: snapshot.trip.importedSources.first?.extractedText ?? "",
                    importedSources: snapshot.trip.importedSources
                )
                let pages = journalEngine.generatePages(for: repairedTrip)
                self.trip = repairedTrip
                self.journalPages = pages
                self.journalSelections = Self.defaultSelections(for: pages)
                self.stickerSelections = [:]
                self.customStickers = []
                self.travelMinutesBeforeActivityID = [:]
                self.enabledReminderActivityIDs = []
                self.completedActivityIDs = []
                persist()
                return
            }

            self.trip = snapshot.trip
            self.journalPages = snapshot.journalPages
            self.journalSelections = snapshot.journalSelections
            self.stickerSelections = snapshot.stickerSelections
            self.customStickers = snapshot.customStickers
            self.travelMinutesBeforeActivityID = [:]
            self.enabledReminderActivityIDs = []
            self.completedActivityIDs = snapshot.completedActivityIDs
            return
        }

        let trip = planningEngine.generateTrip(
            destination: "东京",
            dayCount: 5,
            purpose: [.cityWalk, .food],
            notes: "想要轻松一点，适合发小红书"
        )
        self.trip = trip
        let pages = journalEngine.generatePages(for: trip)
        self.journalPages = pages
        self.journalSelections = Self.defaultSelections(for: pages)
        self.stickerSelections = [:]
        self.customStickers = []
        self.travelMinutesBeforeActivityID = [:]
        self.enabledReminderActivityIDs = []
        self.completedActivityIDs = []
        persist()
    }

    private var availableStickers: [Sticker] {
        StickerLibrary.default.categories.flatMap(\.stickers) + customStickers
    }

    func generateTrip(
        destination: String,
        confirmedDestinationLocation: DestinationLocation? = nil,
        dayCount: Int,
        duration: TripDuration? = nil,
        purpose: [TravelPurpose],
        notes: String,
        importedSource: ImportedSource? = nil
    ) async {
        isGeneratingTrip = true
        aiPlanningMessage = "正在定位目的地并生成 AI 候选地点。"
        defer {
            isGeneratingTrip = false
        }

        let destinationLocation: DestinationLocation?
        if let confirmedDestinationLocation {
            destinationLocation = confirmedDestinationLocation
        } else {
            destinationLocation = await destinationGeocoder.resolve(destination)
        }
        let effectivePurpose = purpose.isEmpty ? [.cityWalk] : purpose
        let destinationSearchContext = destinationLocation?.displayName ?? destination
        let effectiveDuration = Self.normalizedDuration(duration ?? .dayCount(dayCount))
        let normalizedDayCount = Self.dayCount(from: effectiveDuration)
        let aiResult = await aiPlanner.suggestPlaces(
            destination: destinationSearchContext,
            dayCount: normalizedDayCount,
            purpose: effectivePurpose,
            notes: notes,
            importedSource: importedSource
        )
        let resolvedPlaces = await placeResolver.resolvePlaces(
            suggestions: aiResult.suggestions,
            destination: destinationSearchContext,
            destinationLocation: destinationLocation,
            minimumPlaceCount: normalizedDayCount
        )

        let generatedTrip = planningEngine.generateTrip(
            destination: destination,
            dayCount: normalizedDayCount,
            purpose: effectivePurpose,
            notes: notes,
            importedSources: importedSource.map { [$0] } ?? [],
            destinationLocation: destinationLocation,
            resolvedPlaces: resolvedPlaces.count >= 2 ? resolvedPlaces : []
        )
        var scheduledTrip = generatedTrip
        Self.applyDuration(effectiveDuration, to: &scheduledTrip)
        let importedFixedCount = Self.insertImportedFixedNodes(
            importedSource: importedSource,
            into: &scheduledTrip
        )
        await resolveFixedNodePlaces(
            in: &scheduledTrip,
            destination: destinationSearchContext,
            destinationLocation: destinationLocation
        )

        trip = scheduledTrip
        let pages = journalEngine.generatePages(for: scheduledTrip)
        journalPages = pages
        journalSelections = Self.defaultSelections(for: pages)
        stickerSelections = [:]
        travelMinutesBeforeActivityID = [:]
        completedActivityIDs = []
        let fixedNodeMessage = importedFixedCount > 0 ? " 已识别 \(importedFixedCount) 个固定时间节点。" : ""
        if resolvedPlaces.count >= 2 {
            aiPlanningMessage = "\(aiResult.statusMessage) 已匹配 \(resolvedPlaces.count) 个真实坐标。\(fixedNodeMessage)"
        } else if aiResult.suggestions.isEmpty {
            aiPlanningMessage = aiResult.statusMessage + fixedNodeMessage
        } else {
            aiPlanningMessage = "MiniMax 已生成 \(aiResult.suggestions.count) 个候选地点，但 MapKit 未匹配到足够近的坐标，已使用目的地定位生成路线。\(fixedNodeMessage)"
        }
        persist()
    }

    func toggleActivityCompletion(activityID: UUID) {
        if completedActivityIDs.contains(activityID) {
            completedActivityIDs.remove(activityID)
        } else {
            completedActivityIDs.insert(activityID)
        }
        persist()
    }

    func adjustBudget(by amount: Decimal) {
        var budget = trip.budgetPlan ?? BudgetPlan(total: 0, currencyCode: DestinationResolver.currencyCode(forCountryCode: nil))
        let nextTotal = budget.total + amount
        budget.total = nextTotal < 0 ? 0 : nextTotal
        trip.budgetPlan = budget
        persist()
    }

    func updateBudgetTotal(_ total: Decimal) {
        var budget = trip.budgetPlan ?? BudgetPlan(total: 0, currencyCode: DestinationResolver.currencyCode(forCountryCode: nil))
        budget.total = total < 0 ? 0 : total
        trip.budgetPlan = budget
        persist()
    }

    func addBudgetExpense(title: String, amount: Decimal, category: BudgetCategory, notes: String?) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, amount > 0 else {
            return
        }

        var budget = trip.budgetPlan ?? BudgetPlan(total: 0, currencyCode: DestinationResolver.currencyCode(forCountryCode: nil))
        let trimmedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        budget.expenses.insert(
            BudgetExpense(
                id: UUID(),
                title: trimmedTitle,
                amount: amount,
                category: category,
                participantIDs: trip.participants.map(\.id),
                notes: trimmedNotes?.isEmpty == false ? trimmedNotes : nil
            ),
            at: 0
        )
        trip.budgetPlan = budget
        persist()
    }

    func updateBudgetExpense(
        id: UUID,
        title: String,
        amount: Decimal,
        category: BudgetCategory,
        notes: String?
    ) {
        guard var budget = trip.budgetPlan,
              let index = budget.expenses.firstIndex(where: { $0.id == id }) else {
            return
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        budget.expenses[index].title = trimmedTitle.isEmpty ? "未命名支出" : trimmedTitle
        budget.expenses[index].amount = amount < 0 ? 0 : amount
        budget.expenses[index].category = category
        budget.expenses[index].notes = trimmedNotes?.isEmpty == false ? trimmedNotes : nil
        trip.budgetPlan = budget
        persist()
    }

    func deleteBudgetExpense(id: UUID) {
        guard var budget = trip.budgetPlan else {
            return
        }

        budget.expenses.removeAll { $0.id == id }
        trip.budgetPlan = budget
        persist()
    }

    func toggleBudgetExpenseParticipant(expenseID: UUID, participantID: UUID) {
        guard var budget = trip.budgetPlan,
              let index = budget.expenses.firstIndex(where: { $0.id == expenseID }) else {
            return
        }

        if budget.expenses[index].participantIDs.contains(participantID) {
            budget.expenses[index].participantIDs.removeAll { $0 == participantID }
        } else {
            budget.expenses[index].participantIDs.append(participantID)
        }
        trip.budgetPlan = budget
        persist()
    }

    func addParticipant(name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return
        }

        trip.participants.append(Participant(id: UUID(), name: trimmedName, role: nil))
        persist()
    }

    func updateParticipant(id: UUID, name: String) {
        guard let index = trip.participants.firstIndex(where: { $0.id == id }) else {
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        trip.participants[index].name = trimmedName.isEmpty ? "未命名" : trimmedName
        persist()
    }

    func deleteParticipant(id: UUID) {
        trip.participants.removeAll { $0.id == id }
        if var budget = trip.budgetPlan {
            for index in budget.expenses.indices {
                budget.expenses[index].participantIDs.removeAll { $0 == id }
            }
            trip.budgetPlan = budget
        }
        persist()
    }

    func togglePackingItem(id: UUID) {
        guard var packingList = trip.packingList,
              let index = packingList.items.firstIndex(where: { $0.id == id }) else {
            return
        }

        packingList.items[index].isPacked.toggle()
        trip.packingList = packingList
        persist()
    }

    func addPackingItem(title: String, notes: String?) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return
        }

        var packingList = trip.packingList ?? PackingList(items: [])
        let normalizedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        packingList.items.append(
            PackingItem(
                id: UUID(),
                title: trimmedTitle,
                isPacked: false,
                notes: normalizedNotes?.isEmpty == false ? normalizedNotes : nil
            )
        )
        trip.packingList = packingList
        persist()
    }

    func updatePackingItem(id: UUID, title: String, notes: String?) {
        guard var packingList = trip.packingList,
              let index = packingList.items.firstIndex(where: { $0.id == id }) else {
            return
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        packingList.items[index].title = trimmedTitle.isEmpty ? "未命名物品" : trimmedTitle
        packingList.items[index].notes = trimmedNotes?.isEmpty == false ? trimmedNotes : nil
        trip.packingList = packingList
        persist()
    }

    func deletePackingItem(id: UUID) {
        deletePackingItems(ids: [id])
    }

    func deletePackingItems(ids: Set<UUID>) {
        guard var packingList = trip.packingList else {
            return
        }

        packingList.items.removeAll { ids.contains($0.id) }
        trip.packingList = packingList
        persist()
    }

    func applyPackingTemplate(_ template: PackingTemplate) {
        applyPackingTemplates([template])
    }

    func applyPackingTemplates(_ templates: [PackingTemplate]) {
        let packingList = trip.packingList ?? PackingList(items: [])
        trip.packingList = PackingTemplateLibrary.applying(templates, to: packingList)
        persist()
    }

    func updateActivity(
        dayID: UUID,
        activityID: UUID,
        title: String,
        startTime: String?,
        endTime: String?,
        notes: String?,
        reminder: Reminder?
    ) {
        guard let dayIndex = trip.days.firstIndex(where: { $0.id == dayID }),
              let activityIndex = trip.days[dayIndex].activities.firstIndex(where: { $0.id == activityID }) else {
            return
        }

        let previousReminder = trip.days[dayIndex].activities[activityIndex].reminder
        trip.days[dayIndex].activities[activityIndex].title = title
        trip.days[dayIndex].activities[activityIndex].startTime = startTime
        trip.days[dayIndex].activities[activityIndex].endTime = endTime
        trip.days[dayIndex].activities[activityIndex].notes = notes
        trip.days[dayIndex].activities[activityIndex].reminder = reminder
        persist()

        if let previousReminder, previousReminder.id != reminder?.id {
            Self.cancelScheduledReminder(previousReminder)
            enabledReminderActivityIDs.remove(activityID)
        }
    }

    func enableReminder(dayID: UUID, activityID: UUID) async {
        guard let day = trip.days.first(where: { $0.id == dayID }),
              let activity = day.activities.first(where: { $0.id == activityID }) else {
            return
        }

        let isScheduled = await Self.syncScheduledReminder(
            activity: activity,
            day: day,
            duration: trip.duration
        )
        if isScheduled {
            enabledReminderActivityIDs.insert(activityID)
            aiPlanningMessage = "已开启固定时间提醒。"
        } else {
            enabledReminderActivityIDs.remove(activityID)
            aiPlanningMessage = "当前节点无法开启系统提醒，请确认行程日期和时间。"
        }
    }

    private func resolveFixedNodePlaces(
        in trip: inout Trip,
        destination: String,
        destinationLocation: DestinationLocation?
    ) async {
        for dayIndex in trip.days.indices {
            for activityIndex in trip.days[dayIndex].activities.indices {
                let activity = trip.days[dayIndex].activities[activityIndex]
                guard ScheduleConflictDetector.isLockedFixedNode(activity),
                      activity.place == nil,
                      let place = await fixedNodePlaceResolver.resolvePlace(
                        for: activity,
                        destination: destination,
                        destinationLocation: destinationLocation
                      ) else {
                    continue
                }

                trip.days[dayIndex].activities[activityIndex].place = place
            }
        }
    }

    func reorderRouteActivities(activityIDs: [UUID]) {
        let routeOrderByActivityID = Dictionary(
            uniqueKeysWithValues: activityIDs.enumerated().map { index, activityID in
                (activityID, index + 1)
            }
        )

        for dayIndex in trip.days.indices {
            for activityIndex in trip.days[dayIndex].activities.indices {
                let activityID = trip.days[dayIndex].activities[activityIndex].id
                guard let routeOrder = routeOrderByActivityID[activityID] else {
                    continue
                }

                trip.days[dayIndex].activities[activityIndex].routeOrder = routeOrder
            }
        }

        persist()
        travelMinutesBeforeActivityID = [:]
    }

    func reorderRouteActivitiesAndReschedule(activityIDs: [UUID]) async {
        let affectedDayIDs = Set(activityIDs.compactMap { activityID in
            trip.days.first { day in
                day.activities.contains { $0.id == activityID }
            }?.id
        })

        reorderRouteActivities(activityIDs: activityIDs)

        for dayID in affectedDayIDs {
            await rescheduleDay(dayID: dayID)
        }
    }

    func rescheduleDay(dayID: UUID) async {
        guard let dayIndex = trip.days.firstIndex(where: { $0.id == dayID }) else {
            return
        }

        aiPlanningMessage = "正在计算点位之间的移动时间。"
        let travelMinutes = await travelTimeResolver.travelMinutesBeforeActivityID(for: trip.days[dayIndex])
        guard let latestDayIndex = trip.days.firstIndex(where: { $0.id == dayID }) else {
            return
        }

        travelMinutesBeforeActivityID.merge(travelMinutes) { _, new in new }
        trip.days[latestDayIndex] = DayScheduleRescheduler.reschedule(
            trip.days[latestDayIndex],
            travelMinutesBeforeActivityID: travelMinutes
        )
        let routeCount = travelMinutes.count
        aiPlanningMessage = routeCount > 0
            ? "已结合 MapKit 预计移动时间重排当天路线。"
            : "已根据固定时间节点重排当天路线。"
        persist()
    }

    func selectedBlocks(for page: JournalPage) -> [JournalBlock] {
        let selection = journalSelections[page.id] ?? .defaults(for: page)
        return page.blocks
            .map { journalBlock($0, for: page) }
            .filter { selection.contains($0.id) }
    }

    func toggleJournalBlock(pageID: UUID, blockID: UUID) {
        guard let page = journalPages.first(where: { $0.id == pageID }) else {
            return
        }

        var selection = journalSelections[pageID] ?? .defaults(for: page)
        selection.toggle(blockID)
        journalSelections[pageID] = selection
        persist()
    }

    func isJournalBlockSelected(pageID: UUID, blockID: UUID) -> Bool {
        guard let page = journalPages.first(where: { $0.id == pageID }) else {
            return false
        }

        return (journalSelections[pageID] ?? .defaults(for: page)).contains(blockID)
    }

    func selectedStickers(for page: JournalPage) -> [Sticker] {
        let selection = stickerSelections[page.id] ?? StickerSelection(selectedStickerIDs: [])
        return availableStickers
            .filter { selection.contains($0.id) }
    }

    func placedStickers(for page: JournalPage) -> [PlacedJournalSticker] {
        let selection = stickerSelections[page.id] ?? StickerSelection(selectedStickerIDs: [])
        let stickersByID = Dictionary(
            uniqueKeysWithValues: availableStickers
                .map { ($0.id, $0) }
        )

        return selection.placements.compactMap { placement in
            guard let sticker = stickersByID[placement.stickerID] else {
                return nil
            }

            return PlacedJournalSticker(placement: placement, sticker: sticker)
        }
    }

    var customStickerCategory: StickerCategory? {
        guard !customStickers.isEmpty else {
            return nil
        }

        return StickerCategory(
            id: Self.customStickerCategoryID,
            title: "我的",
            stickers: customStickers
        )
    }

    func addCustomSticker(title: String, imageData: Data) {
        customStickers.append(
            Sticker(
                id: UUID(),
                title: title,
                symbol: "photo.fill",
                imageDataBase64: imageData.base64EncodedString()
            )
        )
        persist()
    }

    func toggleSticker(pageID: UUID, stickerID: UUID) {
        var selection = stickerSelections[pageID] ?? StickerSelection(selectedStickerIDs: [])
        selection.toggle(stickerID)
        stickerSelections[pageID] = selection
        persist()
    }

    func addStickerPlacement(pageID: UUID, stickerID: UUID, xRatio: Double, yRatio: Double) {
        var selection = stickerSelections[pageID] ?? StickerSelection(selectedStickerIDs: [])
        selection.addPlacement(stickerID: stickerID, xRatio: xRatio, yRatio: yRatio)
        stickerSelections[pageID] = selection
        persist()
    }

    func removeStickerPlacement(pageID: UUID, placementID: UUID) {
        var selection = stickerSelections[pageID] ?? StickerSelection(selectedStickerIDs: [])
        selection.removePlacement(id: placementID)
        stickerSelections[pageID] = selection
        persist()
    }

    func updateStickerPlacement(pageID: UUID, placementID: UUID, xRatio: Double, yRatio: Double) {
        var selection = stickerSelections[pageID] ?? StickerSelection(selectedStickerIDs: [])
        selection.updatePlacement(id: placementID, xRatio: xRatio, yRatio: yRatio)
        stickerSelections[pageID] = selection
        persist()
    }

    func updateStickerTransform(pageID: UUID, placementID: UUID, scale: Double, rotationDegrees: Double) {
        var selection = stickerSelections[pageID] ?? StickerSelection(selectedStickerIDs: [])
        selection.updatePlacementTransform(id: placementID, scale: scale, rotationDegrees: rotationDegrees)
        stickerSelections[pageID] = selection
        persist()
    }

    func isStickerSelected(pageID: UUID, stickerID: UUID) -> Bool {
        (stickerSelections[pageID] ?? StickerSelection(selectedStickerIDs: [])).contains(stickerID)
    }

    private func journalBlock(_ block: JournalBlock, for page: JournalPage) -> JournalBlock {
        guard page.kind == .day,
              let dayID = page.dayID,
              let day = trip.days.first(where: { $0.id == dayID }) else {
            return block
        }

        var nextBlock = block
        switch block.kind {
        case .dateLocation:
            nextBlock.text = completedLocationSummary(for: day)
        case .timeline:
            nextBlock.text = completedTimelineSummary(for: day)
        case .mapSnapshot, .routeSummary, .placeHighlights:
            nextBlock.text = completedMapSummary(for: day)
        default:
            break
        }
        return nextBlock
    }

    private func completedActivities(in day: TripDay) -> [Activity] {
        day.activities
            .filter { completedActivityIDs.contains($0.id) }
            .sorted { lhs, rhs in
                switch (lhs.routeOrder, rhs.routeOrder) {
                case let (lhsOrder?, rhsOrder?):
                    return lhsOrder < rhsOrder
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return (lhs.startTime ?? lhs.title) < (rhs.startTime ?? rhs.title)
                }
            }
    }

    private func completedLocationSummary(for day: TripDay) -> String {
        let places = completedActivities(in: day)
            .compactMap(\.place?.name)
        guard !places.isEmpty else {
            return "\(day.dateLabel) · 尚未勾选已完成行程"
        }
        return "\(day.dateLabel) · \(places.joined(separator: "、"))"
    }

    private func completedTimelineSummary(for day: TripDay) -> String {
        let entries = completedActivities(in: day).map { activity in
            let times = [activity.startTime, activity.endTime].compactMap { $0 }
            let timeText = times.isEmpty ? nil : times.joined(separator: "-")
            return [timeText, activity.title].compactMap { $0 }.joined(separator: " ")
        }

        return entries.isEmpty ? "当天还没有勾选完成的行程。" : entries.joined(separator: "\n")
    }

    private func completedMapSummary(for day: TripDay) -> String {
        let places = completedActivities(in: day)
            .compactMap(\.place?.name)
        return places.isEmpty ? "当天还没有可放入手帐的已完成地点。" : places.joined(separator: " → ")
    }

    private static func defaultSelections(for pages: [JournalPage]) -> [UUID: JournalModuleSelection] {
        Dictionary(uniqueKeysWithValues: pages.map { page in
            (page.id, JournalModuleSelection.defaults(for: page))
        })
    }

    private static func dayCount(from duration: TripDuration) -> Int {
        switch duration {
        case let .dayCount(dayCount):
            return TripPlanningLimits.normalizedDayCount(dayCount)
        case let .dateRange(start, end):
            let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
            return TripPlanningLimits.normalizedDayCount(days + 1)
        }
    }

    private static func normalizedDuration(_ duration: TripDuration) -> TripDuration {
        switch duration {
        case let .dayCount(dayCount):
            return .dayCount(TripPlanningLimits.normalizedDayCount(dayCount))
        case let .dateRange(start, end):
            let calendar = Calendar.current
            let normalizedStart = calendar.startOfDay(for: start)
            let requestedEnd = calendar.startOfDay(for: end)
            let minimumEnd = max(requestedEnd, normalizedStart)
            let maximumEnd = calendar.date(
                byAdding: .day,
                value: TripPlanningLimits.maximumDayCount - 1,
                to: normalizedStart
            ) ?? normalizedStart
            return .dateRange(start: normalizedStart, end: min(minimumEnd, maximumEnd))
        }
    }

    private static func applyDuration(_ duration: TripDuration, to trip: inout Trip) {
        trip.duration = duration

        guard case let .dateRange(start, _) = duration else {
            return
        }

        for dayIndex in trip.days.indices {
            let dayNumber = trip.days[dayIndex].dayNumber
            guard let date = Calendar.current.date(byAdding: .day, value: dayNumber - 1, to: start) else {
                continue
            }

            trip.days[dayIndex].dateLabel = Self.dateLabel(for: date, dayNumber: dayNumber)
        }
    }

    private static func dateLabel(for date: Date, dayNumber: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "M月d日"
        return "\(formatter.string(from: date)) · Day \(dayNumber)"
    }

    private static func insertImportedFixedNodes(
        importedSource: ImportedSource?,
        into trip: inout Trip
    ) -> Int {
        guard let text = importedSource?.extractedText else {
            return 0
        }

        let candidates = importedFixedNodeCandidates(from: text, duration: trip.duration)
        guard !candidates.isEmpty else {
            return 0
        }

        var insertedCount = 0
        for candidate in candidates {
            guard let dayIndex = trip.days.firstIndex(where: { $0.dayNumber == candidate.dayNumber }) else {
                continue
            }

            trip.days[dayIndex].activities.insert(candidate.activity, at: 0)
            trip.days[dayIndex].activities.sort { lhs, rhs in
                let lhsTime = lhs.startTime ?? "99:99"
                let rhsTime = rhs.startTime ?? "99:99"
                if lhsTime == rhsTime {
                    return lhs.title < rhs.title
                }
                return lhsTime < rhsTime
            }
            insertedCount += 1
        }

        return insertedCount
    }

    private static func importedFixedNodeCandidates(
        from text: String,
        duration: TripDuration
    ) -> [(dayNumber: Int, activity: Activity)] {
        text
            .split(whereSeparator: \.isNewline)
            .compactMap { rawLine -> (dayNumber: Int, activity: Activity)? in
                let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !line.isEmpty,
                      let kind = fixedActivityKind(for: line),
                      let time = firstTime(in: line) else {
                    return nil
                }

                let dayNumber = fixedNodeDayNumber(for: line, duration: duration)
                let title = fixedNodeTitle(for: line, kind: kind)
                return (
                    dayNumber,
                    Activity(
                        id: deterministicUUID(namespace: "imported-fixed-activity", value: "\(dayNumber)-\(line)"),
                        title: title,
                        kind: kind,
                        place: nil,
                        startTime: time,
                        endTime: nil,
                        notes: "从导入资料识别的固定时间节点",
                        estimatedCost: nil,
                        routeOrder: nil,
                        reminder: Reminder(
                            id: deterministicUUID(namespace: "imported-fixed-reminder", value: "\(dayNumber)-\(line)-\(time)"),
                            fireTime: time,
                            note: "导入资料固定时间提醒"
                        )
                    )
                )
            }
    }

    private static func fixedActivityKind(for line: String) -> ActivityKind? {
        let lowercased = line.lowercased()
        if lowercased.contains("酒店")
            || lowercased.contains("入住")
            || lowercased.contains("check-in")
            || lowercased.contains("check in")
            || lowercased.contains("退房")
            || lowercased.contains("离店")
            || lowercased.contains("checkout")
            || lowercased.contains("check-out")
            || lowercased.contains("check out") {
            return .hotel
        }

        if lowercased.contains("航班")
            || lowercased.contains("机票")
            || lowercased.contains("飞机")
            || lowercased.contains("返程")
            || lowercased.contains("回程")
            || lowercased.contains("返航")
            || lowercased.contains("离境")
            || lowercased.contains("出发机场")
            || lowercased.contains("机场")
            || lowercased.contains("flight")
            || lowercased.contains("火车")
            || lowercased.contains("高铁")
            || lowercased.contains("新干线")
            || lowercased.contains("train") {
            return .transport
        }

        if lowercased.contains("演唱会")
            || lowercased.contains("concert") {
            return .concert
        }

        return nil
    }

    private static func firstTime(in line: String) -> String? {
        let pattern = #"([01]?\d|2[0-3])[:：]([0-5]\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let hourRange = Range(match.range(at: 1), in: line),
              let minuteRange = Range(match.range(at: 2), in: line) else {
            return nil
        }

        let hour = String(line[hourRange])
        let minute = String(line[minuteRange])
        return "\(hour.count == 1 ? "0\(hour)" : hour):\(minute)"
    }

    private static func fixedNodeDayNumber(for line: String, duration: TripDuration) -> Int {
        guard case let .dateRange(start, _) = duration,
              let date = monthDayDate(in: line, referenceDate: start) else {
            return 1
        }

        let startDay = Calendar.current.startOfDay(for: start)
        let targetDay = Calendar.current.startOfDay(for: date)
        let offset = Calendar.current.dateComponents([.day], from: startDay, to: targetDay).day ?? 0
        return TripPlanningLimits.normalizedDayCount(offset + 1)
    }

    private static func monthDayDate(in line: String, referenceDate: Date) -> Date? {
        let pattern = #"(\d{1,2})\s*月\s*(\d{1,2})\s*[日号]?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let monthRange = Range(match.range(at: 1), in: line),
              let dayRange = Range(match.range(at: 2), in: line),
              let month = Int(line[monthRange]),
              let day = Int(line[dayRange]) else {
            return nil
        }

        let year = Calendar.current.component(.year, from: referenceDate)
        return Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
    }

    private static func fixedNodeTitle(for line: String, kind: ActivityKind) -> String {
        let compactLine = line.count > 28 ? "\(line.prefix(28))..." : line
        switch kind {
        case .transport:
            if isReturnTransportLine(line) {
                return "返程交通：\(compactLine)"
            }
            return "到达交通：\(compactLine)"
        case .hotel:
            if isCheckoutLine(line) {
                return "酒店退房：\(compactLine)"
            }
            return "酒店入住：\(compactLine)"
        case .concert:
            return "固定活动：\(compactLine)"
        default:
            return "固定节点：\(compactLine)"
        }
    }

    private static func isReturnTransportLine(_ line: String) -> Bool {
        let lowercased = line.lowercased()
        return lowercased.contains("返程")
            || lowercased.contains("回程")
            || lowercased.contains("返航")
            || lowercased.contains("离境")
            || lowercased.contains("出发机场")
            || lowercased.contains("departure")
            || lowercased.contains("depart")
    }

    private static func isCheckoutLine(_ line: String) -> Bool {
        let lowercased = line.lowercased()
        return lowercased.contains("退房")
            || lowercased.contains("离店")
            || lowercased.contains("checkout")
            || lowercased.contains("check-out")
            || lowercased.contains("check out")
    }

    private static func deterministicUUID(namespace: String, value: String) -> UUID {
        let scalars = "\(namespace)-\(value)".unicodeScalars.map(\.value)
        let hash = scalars.reduce(UInt64(14_695_981_039_346_656_037)) { partial, scalar in
            (partial ^ UInt64(scalar)).multipliedReportingOverflow(by: 1_099_511_628_211).partialValue
        }
        let hex = String(format: "%012llx", hash)
        return UUID(uuidString: "00000000-0000-0000-0000-\(String(hex.suffix(12)))")!
    }

    private static func needsRouteRepair(_ trip: Trip) -> Bool {
        let destination = trip.destination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !destination.isEmpty else {
            return false
        }

        let places = trip.days.flatMap(\.activities).compactMap(\.place)
        guard !places.isEmpty else {
            return false
        }

        if destination.localizedStandardContains("大阪")
            || destination.localizedCaseInsensitiveContains("osaka") {
            return places.contains { place in
                place.name == "涩谷"
                    || place.name == "原宿"
                    || place.address?.localizedCaseInsensitiveContains("Tokyo") == true
            }
        }

        if !(destination.localizedStandardContains("东京")
            || destination.localizedStandardContains("東京")
            || destination.localizedCaseInsensitiveContains("tokyo")) {
            return places.contains { place in
                place.address?.localizedCaseInsensitiveContains("Tokyo") == true
                    || place.address?.localizedCaseInsensitiveContains("Osaka") == true
            }
        }

        return false
    }

    private func persist() {
        localStore.save(
            AppPersistenceSnapshot(
                trip: trip,
                journalPages: journalPages,
                journalSelections: journalSelections,
                stickerSelections: stickerSelections,
                customStickers: customStickers,
                completedActivityIDs: completedActivityIDs
            )
        )
    }

    private static func syncScheduledReminder(
        activity: Activity,
        day: TripDay,
        duration: TripDuration
    ) async -> Bool {
        guard let reminder = activity.reminder else {
            return false
        }

        guard let targetDate = notificationTargetDate(
            day: day,
            duration: duration,
            timeText: activity.startTime ?? reminder.fireTime
        ), targetDate > Date() else {
            cancelScheduledReminder(reminder)
            return false
        }

        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                cancelScheduledReminder(reminder)
                return false
            }

            center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier(for: reminder)])

            let content = UNMutableNotificationContent()
            content.title = "织步记固定时间提醒"
            content.body = "\(day.dateLabel) · \(activity.title)"
            content.sound = .default

            let triggerDate = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: targetDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(
                identifier: notificationIdentifier(for: reminder),
                content: content,
                trigger: trigger
            )
            try await center.add(request)
            return true
        } catch {
            cancelScheduledReminder(reminder)
            return false
        }
    }

    private static func cancelScheduledReminder(_ reminder: Reminder) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationIdentifier(for: reminder)]
        )
    }

    private static func notificationIdentifier(for reminder: Reminder) -> String {
        "ayuwalk.reminder.\(reminder.id.uuidString)"
    }

    private static func notificationTargetDate(
        day: TripDay,
        duration: TripDuration,
        timeText: String
    ) -> Date? {
        guard case let .dateRange(start, _) = duration else {
            return nil
        }

        let timeParts = timeText.split(separator: ":")
        guard timeParts.count == 2,
              let hour = Int(timeParts[0]),
              let minute = Int(timeParts[1]) else {
            return nil
        }

        let calendar = Calendar.current
        guard let dayDate = calendar.date(byAdding: .day, value: day.dayNumber - 1, to: start) else {
            return nil
        }

        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: dayDate
        )
    }
}

struct PlacedJournalSticker: Identifiable, Equatable {
    let placement: JournalStickerPlacement
    let sticker: Sticker

    var id: UUID {
        placement.id
    }
}
