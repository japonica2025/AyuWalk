import AyuWalkCore
import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class AppState {
    var tripLibrary: TripLibrary
    var trip: Trip
    var journalPages: [JournalPage]
    var journalSelections: [UUID: JournalModuleSelection]
    var stickerSelections: [UUID: StickerSelection]
    var customStickers: [Sticker]
    var isGeneratingTrip: Bool
    var aiPlanningMessage: String?
    var latestAIPlanningProposal: AIPlanningProposal?
    var travelMinutesBeforeActivityID: [UUID: Int]
    var enabledReminderActivityIDs: Set<UUID>
    var completedActivityIDs: Set<UUID>
    var itineraryUndoMessage: String?

    @ObservationIgnored private let planningEngine: MockPlanningEngine
    @ObservationIgnored private let journalEngine: MockJournalEngine
    @ObservationIgnored private let localStore: LocalAppStore
    @ObservationIgnored private let destinationGeocoder: DestinationGeocoder
    @ObservationIgnored private let aiPlanner: MiniMaxItineraryPlanner
    @ObservationIgnored private let placeResolver: MapKitPlaceResolver
    @ObservationIgnored private let travelTimeResolver: MapKitTravelTimeResolver
    @ObservationIgnored private let fixedNodePlaceResolver: MapKitFixedNodePlaceResolver
    @ObservationIgnored private var itineraryUndoSnapshot: ItineraryMutationSnapshot?
    @ObservationIgnored private var itineraryMutationRevision: UInt = 0
    @ObservationIgnored private var packingReminderRevision: UInt = 0
    @ObservationIgnored private var reminderActivityIDsInFlight: Set<UUID> = []
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
        self.latestAIPlanningProposal = nil
        self.travelMinutesBeforeActivityID = [:]
        self.enabledReminderActivityIDs = []
        self.completedActivityIDs = []
        self.itineraryUndoMessage = nil
        self.itineraryUndoSnapshot = nil

        if let snapshot = localStore.load() {
            var library = snapshot.tripLibrary
            if let activeWorkspace = library.activeWorkspace,
               Self.needsRouteRepair(activeWorkspace.trip) {
                let repairedTrip = planningEngine.generateTrip(
                    destination: activeWorkspace.trip.destination,
                    dayCount: Self.dayCount(from: activeWorkspace.trip.duration),
                    purpose: activeWorkspace.trip.purpose,
                    notes: activeWorkspace.trip.importedSources.first?.extractedText ?? "",
                    importedSources: activeWorkspace.trip.importedSources
                )
                let pages = journalEngine.generatePages(for: repairedTrip)
                library.deleteTrip(id: activeWorkspace.id)
                let repairedWorkspaceID = library.appendNewWorkspace(
                    TripWorkspace(
                        trip: repairedTrip,
                        journalPages: pages,
                        journalSelections: Self.defaultSelections(for: pages),
                        stickerSelections: [:],
                        customStickers: [],
                        completedActivityIDs: []
                    )
                )
                let repairedWorkspace = library.workspaces.first { $0.id == repairedWorkspaceID }!
                self.tripLibrary = library
                self.trip = repairedWorkspace.trip
                self.journalPages = repairedWorkspace.journalPages
                self.journalSelections = repairedWorkspace.journalSelections
                self.stickerSelections = repairedWorkspace.stickerSelections
                self.customStickers = repairedWorkspace.customStickers
                self.completedActivityIDs = repairedWorkspace.completedActivityIDs
                persist()
                return
            }

            if let activeWorkspace = library.activeWorkspace {
                self.tripLibrary = library
                self.trip = activeWorkspace.trip
                self.journalPages = activeWorkspace.journalPages
                self.journalSelections = activeWorkspace.journalSelections
                self.stickerSelections = activeWorkspace.stickerSelections
                self.customStickers = activeWorkspace.customStickers
                self.completedActivityIDs = activeWorkspace.completedActivityIDs
                self.travelMinutesBeforeActivityID = activeWorkspace.travelMinutesBeforeActivityID
                self.enabledReminderActivityIDs = activeWorkspace.enabledReminderActivityIDs
                return
            }
        }

        let trip = planningEngine.generateTrip(
            destination: "东京",
            dayCount: 5,
            purpose: [.cityWalk, .food],
            notes: "想要轻松一点，适合发小红书"
        )
        self.trip = trip
        let pages = journalEngine.generatePages(for: trip)
        let selections = Self.defaultSelections(for: pages)
        self.journalPages = pages
        self.journalSelections = selections
        self.stickerSelections = [:]
        self.customStickers = []
        self.completedActivityIDs = []
        let workspace = TripWorkspace(
            trip: trip,
            journalPages: pages,
            journalSelections: selections,
            stickerSelections: [:],
            customStickers: [],
            completedActivityIDs: []
        )
        self.tripLibrary = TripLibrary(activeTripID: workspace.id, workspaces: [workspace])
        persist()
    }

    private var availableStickers: [Sticker] {
        StickerLibrary.default.categories.flatMap(\.stickers) + customStickers
    }

    var tripWorkspaces: [TripWorkspace] {
        tripLibrary.workspaces
    }

    func selectTrip(id: UUID) {
        guard id != tripLibrary.activeTripID else {
            return
        }
        syncActiveWorkspace()
        tripLibrary.selectTrip(id: id)
        guard let workspace = tripLibrary.activeWorkspace else {
            return
        }
        load(workspace)
        clearItineraryUndo()
        persist()
    }

    @discardableResult
    func duplicateTrip(id: UUID) -> UUID? {
        syncActiveWorkspace()
        guard let duplicateID = tripLibrary.duplicateTrip(id: id),
              let workspace = tripLibrary.activeWorkspace else {
            return nil
        }
        load(workspace)
        clearItineraryUndo()
        persist()
        syncActivePackingReminderAfterTripChange()
        return duplicateID
    }

    func renameTrip(id: UUID, title: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return
        }
        syncActiveWorkspace()
        tripLibrary.renameTrip(id: id, title: trimmedTitle)
        if id == tripLibrary.activeTripID, let workspace = tripLibrary.activeWorkspace {
            load(workspace)
        }
        persist()
    }

    func setTripArchived(_ isArchived: Bool, id: UUID) {
        syncActiveWorkspace()
        tripLibrary.setArchived(isArchived, for: id)
        if let workspace = tripLibrary.activeWorkspace {
            load(workspace)
        }
        persist()
    }

    func deleteTrip(id: UUID) {
        guard tripLibrary.workspaces.count > 1 else {
            return
        }
        syncActiveWorkspace()
        if let workspace = tripLibrary.workspaces.first(where: { $0.id == id }) {
            Self.cancelScheduledReminders(in: workspace.trip)
        }
        tripLibrary.deleteTrip(id: id)
        if let workspace = tripLibrary.activeWorkspace {
            load(workspace)
        }
        persist()
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
        var scheduledTrip = aiResult.proposal.map {
            AITripProposalApplier.apply($0, to: generatedTrip, resolvedPlaces: resolvedPlaces)
        } ?? generatedTrip
        latestAIPlanningProposal = aiResult.proposal
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
        let generatedTravelMinutes = await travelMinutesBeforeActivityID(for: Array(scheduledTrip.days.prefix(1)))

        let pages = journalEngine.generatePages(for: scheduledTrip)
        syncActiveWorkspace()
        let workspace = TripWorkspace(
            trip: scheduledTrip,
            journalPages: pages,
            journalSelections: Self.defaultSelections(for: pages),
            stickerSelections: [:],
            customStickers: [],
            completedActivityIDs: [],
            travelMinutesBeforeActivityID: generatedTravelMinutes
        )
        let workspaceID = tripLibrary.appendNewWorkspace(workspace)
        if let workspace = tripLibrary.workspaces.first(where: { $0.id == workspaceID }) {
            load(workspace)
        }
        travelMinutesBeforeActivityID = generatedTravelMinutes
        let fixedNodeMessage = importedFixedCount > 0 ? " 已识别 \(importedFixedCount) 个固定时间节点。" : ""
        if resolvedPlaces.count >= 2 {
            let confidenceMessage = aiResult.proposal.map {
                " 规划置信度 \(Int($0.confidence * 100))%。"
            } ?? ""
            aiPlanningMessage = "\(aiResult.statusMessage) 已匹配 \(resolvedPlaces.count) 个真实坐标。\(confidenceMessage)\(fixedNodeMessage)"
        } else if aiResult.suggestions.isEmpty {
            aiPlanningMessage = aiResult.statusMessage + fixedNodeMessage
        } else {
            aiPlanningMessage = "MiniMax 已生成 \(aiResult.suggestions.count) 个候选地点，但 MapKit 未匹配到足够近的坐标，已使用目的地定位生成路线。\(fixedNodeMessage)"
        }
        persist()
    }

    func adjustCurrentTrip(with request: String) async {
        let trimmedRequest = request.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRequest.isEmpty, !isGeneratingTrip else {
            return
        }

        let targetTripID = trip.id
        isGeneratingTrip = true
        aiPlanningMessage = "正在根据你的要求调整现有行程。"
        defer {
            isGeneratingTrip = false
        }

        let dayCount = Self.dayCount(from: trip.duration)
        let result = await aiPlanner.suggestPlaces(
            destination: trip.destination,
            dayCount: dayCount,
            purpose: trip.purpose,
            notes: Self.adjustmentPrompt(userRequest: trimmedRequest, trip: trip),
            importedSource: trip.importedSources.first
        )
        guard trip.id == targetTripID else {
            return
        }

        guard let proposal = result.proposal else {
            aiPlanningMessage = "远程 AI 暂不可用，已保留当前行程，稍后可再次尝试调整。"
            return
        }

        let adjustedTrip = AITripProposalApplier.apply(
            proposal,
            to: trip,
            mode: .preserveExistingOrdinaryActivities
        )
        let previousIDs = Set(trip.days.flatMap(\.activities).map(\.id))
        let adjustedIDs = Set(adjustedTrip.days.flatMap(\.activities).map(\.id))
        applyItineraryEdit(
            ItineraryEdit(
                previousDays: trip.days,
                days: adjustedTrip.days,
                affectedActivityIDs: previousIDs.union(adjustedIDs)
            ),
            undoMessage: "已应用 AI 行程调整"
        )
        latestAIPlanningProposal = proposal
        aiPlanningMessage = "\(proposal.adjustmentReason ?? trimmedRequest) · 置信度 \(Int(proposal.confidence * 100))%"
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

    func updateBudgetTotal(_ total: Decimal, currencyCode: String? = nil) {
        var budget = trip.budgetPlan ?? BudgetPlan(total: 0, currencyCode: DestinationResolver.currencyCode(forCountryCode: nil))
        budget.updateTotal(total, currencyCode: currencyCode)
        trip.budgetPlan = budget
        persist()
    }

    func updateCategoryBudget(category: BudgetCategory, amount: Decimal) {
        var budget = trip.budgetPlan ?? BudgetPlan(total: 0, currencyCode: DestinationResolver.currencyCode(forCountryCode: nil))
        let normalizedAmount = max(amount, 0)
        if normalizedAmount == 0 {
            budget.categoryBudgets.removeValue(forKey: category)
        } else {
            budget.categoryBudgets[category] = normalizedAmount
        }
        trip.budgetPlan = budget
        persist()
    }

    func updateExchangeRate(currencyCode: String, rate: Decimal) {
        let normalizedCurrencyCode = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalizedCurrencyCode.isEmpty else {
            return
        }
        var budget = trip.budgetPlan ?? BudgetPlan(total: 0, currencyCode: DestinationResolver.currencyCode(forCountryCode: nil))
        let trimmedBudgetCurrencyCode = budget.currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let budgetCurrencyCode = trimmedBudgetCurrencyCode.isEmpty ? "CNY" : trimmedBudgetCurrencyCode
        if normalizedCurrencyCode == budgetCurrencyCode {
            budget.exchangeRates.removeValue(forKey: normalizedCurrencyCode)
        } else if rate > 0 {
            budget.exchangeRates[normalizedCurrencyCode] = rate
        } else {
            budget.exchangeRates.removeValue(forKey: normalizedCurrencyCode)
        }
        trip.budgetPlan = budget
        persist()
    }

    func addBudgetExpense(
        title: String,
        amount: Decimal,
        category: BudgetCategory,
        currencyCode: String,
        payerID: UUID?,
        notes: String?
    ) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, amount > 0 else {
            return
        }

        var budget = trip.budgetPlan ?? BudgetPlan(total: 0, currencyCode: DestinationResolver.currencyCode(forCountryCode: nil))
        let trimmedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        let participantIDs = trip.participants.map(\.id)
        budget.expenses.insert(
            BudgetExpense(
                id: UUID(),
                title: trimmedTitle,
                amount: amount,
                category: category,
                participantIDs: participantIDs,
                payerID: payerID ?? participantIDs.first,
                currencyCode: currencyCode,
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
        currencyCode: String,
        payerID: UUID?,
        splitMode: BudgetSplitMode,
        customShares: [UUID: Decimal],
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
        budget.expenses[index].currencyCode = currencyCode
        let participantIDSet = Set(budget.expenses[index].participantIDs)
        let resolvedPayerID = payerID.flatMap { participantIDSet.contains($0) ? $0 : budget.expenses[index].participantIDs.first }
        budget.expenses[index].payerID = resolvedPayerID
        budget.expenses[index].splitMode = splitMode
        budget.expenses[index].customShares = customShares
            .filter { participantIDSet.contains($0.key) }
            .mapValues { max($0, 0) }
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
            budget.expenses[index].customShares.removeValue(forKey: participantID)
            if budget.expenses[index].payerID == participantID {
                budget.expenses[index].payerID = budget.expenses[index].participantIDs.first
            }
        } else {
            budget.expenses[index].participantIDs.append(participantID)
            if budget.expenses[index].payerID == nil {
                budget.expenses[index].payerID = participantID
            }
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
                budget.expenses[index].customShares.removeValue(forKey: id)
                if budget.expenses[index].payerID == id {
                    budget.expenses[index].payerID = budget.expenses[index].participantIDs.first
                }
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

    func updatePackingReminder(_ reminder: PackingReminder?) {
        packingReminderRevision &+= 1
        let revision = packingReminderRevision
        let targetTripID = trip.id
        Task {
            await applyPackingReminderUpdate(reminder, targetTripID: targetTripID, revision: revision)
        }
    }

    private func applyPackingReminderUpdate(
        _ reminder: PackingReminder?,
        targetTripID: UUID,
        revision: UInt
    ) async {
        guard trip.id == targetTripID, packingReminderRevision == revision else {
            return
        }

        let previousReminder = trip.packingList?.reminder
        var packingList = trip.packingList ?? PackingList(items: [])

        guard var updatedReminder = reminder else {
            previousReminder.map(Self.cancelScheduledReminder)
            packingList.reminder = nil
            trip.packingList = packingList
            persist()
            return
        }

        if let previousReminder, previousReminder.id != updatedReminder.id {
            Self.cancelScheduledReminder(previousReminder)
        }

        if updatedReminder.isEnabled {
            let schedulingTrip = trip
            let isScheduled = await Self.syncScheduledPackingReminder(
                updatedReminder,
                trip: schedulingTrip
            )
            guard trip.id == schedulingTrip.id, packingReminderRevision == revision else {
                if isScheduled {
                    Self.cancelScheduledReminder(updatedReminder)
                }
                return
            }

            if isScheduled {
                aiPlanningMessage = "已开启打包提醒。"
            } else {
                updatedReminder.isEnabled = false
                aiPlanningMessage = "当前行程日期待定或提醒时间已过，已保存提醒计划。"
            }
        } else {
            previousReminder.map(Self.cancelScheduledReminder)
            aiPlanningMessage = "已关闭打包提醒。"
        }

        packingList = trip.packingList ?? PackingList(items: [])
        packingList.reminder = updatedReminder
        trip.packingList = packingList
        persist()
    }

    private func syncActivePackingReminderAfterTripChange() {
        guard let reminder = trip.packingList?.reminder, reminder.isEnabled else {
            return
        }

        packingReminderRevision &+= 1
        let revision = packingReminderRevision
        let targetTripID = trip.id
        Task {
            await applyPackingReminderUpdate(reminder, targetTripID: targetTripID, revision: revision)
        }
    }

    func updateActivity(
        dayID: UUID,
        activityID: UUID,
        targetDayID: UUID,
        title: String,
        kind: ActivityKind,
        place: Place?,
        startTime: String?,
        endTime: String?,
        notes: String?,
        reminder: Reminder?,
        isFixedNode: Bool,
        includeInRoute: Bool,
        enableReminder: Bool
    ) {
        guard let dayIndex = trip.days.firstIndex(where: { $0.id == dayID }),
              let activityIndex = trip.days[dayIndex].activities.firstIndex(where: { $0.id == activityID }) else {
            return
        }

        let previousActivity = trip.days[dayIndex].activities[activityIndex]
        let updatedActivity = Activity(
            id: activityID,
            title: title,
            kind: kind,
            place: place,
            startTime: startTime,
            endTime: endTime,
            notes: notes,
            estimatedCost: previousActivity.estimatedCost,
            routeOrder: previousActivity.routeOrder,
            reminder: reminder,
            isFixedNode: isFixedNode
        )
        guard let edit = ItineraryEditor.updating(
            activityID: activityID,
            from: dayID,
            to: targetDayID,
            with: updatedActivity,
            includeInRoute: includeInRoute,
            in: trip.days
        ) else {
            return
        }
        applyItineraryEdit(
            edit,
            undoMessage: "已更新 \(title)",
            reminderEnabledOverrides: [activityID: enableReminder && reminder != nil]
        )
    }

    func searchPlaces(query: String) async -> [Place] {
        await placeResolver.searchPlaces(query: query, destination: trip.destination)
    }

    func addActivity(
        _ activity: Activity,
        to dayID: UUID,
        includeInRoute: Bool,
        enableReminder: Bool
    ) {
        guard let edit = ItineraryEditor.adding(
            activity,
            to: dayID,
            includeInRoute: includeInRoute,
            in: trip.days
        ) else {
            return
        }
        applyItineraryEdit(
            edit,
            undoMessage: "已新增 \(activity.title)",
            reminderEnabledOverrides: [activity.id: enableReminder && activity.reminder != nil]
        )
    }

    func deleteActivity(dayID: UUID, activityID: UUID) {
        guard let activity = activity(dayID: dayID, activityID: activityID),
              let edit = ItineraryEditor.deleting(activityID: activityID, from: dayID, in: trip.days) else {
            return
        }
        applyItineraryEdit(edit, undoMessage: "已删除 \(activity.title)")
    }

    func duplicateActivity(dayID: UUID, activityID: UUID) {
        guard let activity = activity(dayID: dayID, activityID: activityID),
              let edit = ItineraryEditor.duplicating(activityID: activityID, in: dayID, days: trip.days) else {
            return
        }
        applyItineraryEdit(edit, undoMessage: "已复制 \(activity.title)")
    }

    func moveActivity(activityID: UUID, from sourceDayID: UUID, to destinationDayID: UUID) {
        guard let activity = activity(dayID: sourceDayID, activityID: activityID),
              let edit = ItineraryEditor.moving(
                activityID: activityID,
                from: sourceDayID,
                to: destinationDayID,
                in: trip.days
              ) else {
            return
        }
        applyItineraryEdit(edit, undoMessage: "已移动 \(activity.title)")
    }

    func setActivityRouteInclusion(dayID: UUID, activityID: UUID, isIncluded: Bool) {
        guard let activity = activity(dayID: dayID, activityID: activityID),
              !activity.isFixedNode,
              let edit = ItineraryEditor.settingRouteInclusion(
                isIncluded,
                activityID: activityID,
                dayID: dayID,
                in: trip.days
              ) else {
            return
        }
        applyItineraryEdit(
            edit,
            undoMessage: isIncluded ? "已加入路线" : "已移出路线"
        )
    }

    func undoLastItineraryEdit() {
        guard let snapshot = itineraryUndoSnapshot else {
            return
        }

        Self.cancelScheduledReminders(in: trip)
        trip.days = snapshot.days
        completedActivityIDs = snapshot.completedActivityIDs
        travelMinutesBeforeActivityID = snapshot.travelMinutesBeforeActivityID
        enabledReminderActivityIDs = snapshot.enabledReminderActivityIDs
        clearItineraryUndo()
        persist()
        let restoredTripID = trip.id
        itineraryMutationRevision &+= 1
        let restoredRevision = itineraryMutationRevision
        Task {
            await syncEnabledReminders(
                activityIDs: enabledReminderActivityIDs,
                for: restoredTripID,
                revision: restoredRevision
            )
        }
    }

    func toggleReminder(dayID: UUID, activityID: UUID) async {
        guard let day = trip.days.first(where: { $0.id == dayID }),
              let activity = day.activities.first(where: { $0.id == activityID }) else {
            return
        }

        itineraryMutationRevision &+= 1
        let initiatingRevision = itineraryMutationRevision
        if enabledReminderActivityIDs.contains(activityID) {
            if let reminder = activity.reminder {
                Self.cancelScheduledReminder(reminder)
            }
            enabledReminderActivityIDs.remove(activityID)
            aiPlanningMessage = "已关闭固定时间提醒。"
            persist()
            return
        }

        guard reminderActivityIDsInFlight.insert(activityID).inserted else {
            return
        }
        defer {
            reminderActivityIDsInFlight.remove(activityID)
        }

        let initiatingTripID = trip.id
        let isScheduled = await Self.syncScheduledReminder(
            activity: activity,
            day: day,
            duration: trip.duration
        )
        guard trip.id == initiatingTripID, itineraryMutationRevision == initiatingRevision else {
            if isScheduled, let reminder = activity.reminder {
                Self.cancelScheduledReminder(reminder)
            }
            if trip.id == initiatingTripID, enabledReminderActivityIDs.contains(activityID) {
                await syncEnabledReminders(
                    activityIDs: [activityID],
                    for: initiatingTripID,
                    revision: itineraryMutationRevision
                )
            }
            return
        }
        if isScheduled {
            enabledReminderActivityIDs.insert(activityID)
            aiPlanningMessage = "已开启固定时间提醒。"
        } else {
            enabledReminderActivityIDs.remove(activityID)
            aiPlanningMessage = "当前节点无法开启系统提醒，请确认行程日期和时间。"
        }
        persist()
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

        travelMinutesBeforeActivityID = [:]
        persist()
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

        let dayActivityIDs = Set(trip.days[latestDayIndex].activities.map(\.id))
        travelMinutesBeforeActivityID = travelMinutesBeforeActivityID.filter {
            !dayActivityIDs.contains($0.key)
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

    private func load(_ workspace: TripWorkspace) {
        trip = workspace.trip
        journalPages = workspace.journalPages
        journalSelections = workspace.journalSelections
        stickerSelections = workspace.stickerSelections
        customStickers = workspace.customStickers
        completedActivityIDs = workspace.completedActivityIDs
        travelMinutesBeforeActivityID = workspace.travelMinutesBeforeActivityID
        enabledReminderActivityIDs = workspace.enabledReminderActivityIDs
        clearItineraryUndo()
    }

    private func applyItineraryEdit(
        _ edit: ItineraryEdit,
        undoMessage: String,
        reminderEnabledOverrides: [UUID: Bool] = [:]
    ) {
        itineraryUndoSnapshot = ItineraryMutationSnapshot(
            days: trip.days,
            completedActivityIDs: completedActivityIDs,
            travelMinutesBeforeActivityID: travelMinutesBeforeActivityID,
            enabledReminderActivityIDs: enabledReminderActivityIDs
        )
        itineraryUndoMessage = undoMessage
        itineraryMutationRevision &+= 1

        let previousActivities = trip.days.flatMap(\.activities)
        previousActivities
            .filter { edit.affectedActivityIDs.contains($0.id) }
            .compactMap(\.reminder)
            .forEach(Self.cancelScheduledReminder)

        trip.days = edit.days
        let validActivityIDs = Set(trip.days.flatMap(\.activities).map(\.id))
        completedActivityIDs.formIntersection(validActivityIDs)
        enabledReminderActivityIDs.formIntersection(validActivityIDs)
        for (activityID, isEnabled) in reminderEnabledOverrides {
            if isEnabled {
                enabledReminderActivityIDs.insert(activityID)
            } else {
                enabledReminderActivityIDs.remove(activityID)
            }
        }
        travelMinutesBeforeActivityID = travelMinutesBeforeActivityID.filter {
            validActivityIDs.contains($0.key) && !edit.affectedActivityIDs.contains($0.key)
        }
        persist(preservingItineraryUndo: true)

        let remindersToRestore = enabledReminderActivityIDs.intersection(edit.affectedActivityIDs)
        let editedTripID = trip.id
        let editedRevision = itineraryMutationRevision
        Task {
            await syncEnabledReminders(
                activityIDs: remindersToRestore,
                for: editedTripID,
                revision: editedRevision
            )
        }
    }

    private func syncEnabledReminders(activityIDs: Set<UUID>, for tripID: UUID, revision: UInt) async {
        var expectedRevision = revision
        for activityID in activityIDs {
            while trip.id == tripID {
                if expectedRevision != itineraryMutationRevision {
                    expectedRevision = itineraryMutationRevision
                }
                guard enabledReminderActivityIDs.contains(activityID) else {
                    if let reminder = activity(dayIDForActivity: activityID)?.reminder {
                        Self.cancelScheduledReminder(reminder)
                    }
                    break
                }
                guard let day = trip.days.first(where: { day in
                    day.activities.contains(where: { $0.id == activityID })
                }),
                      let activity = day.activities.first(where: { $0.id == activityID }) else {
                    enabledReminderActivityIDs.remove(activityID)
                    break
                }

                let isScheduled = await Self.syncScheduledReminder(
                    activity: activity,
                    day: day,
                    duration: trip.duration
                )
                guard trip.id == tripID else {
                    if let reminder = activity.reminder {
                        Self.cancelScheduledReminder(reminder)
                    }
                    return
                }
                guard expectedRevision == itineraryMutationRevision else {
                    if let reminder = activity.reminder {
                        Self.cancelScheduledReminder(reminder)
                    }
                    continue
                }
                if !isScheduled {
                    enabledReminderActivityIDs.remove(activityID)
                }
                break
            }
        }
        if trip.id == tripID {
            persist(preservingItineraryUndo: true)
        }
    }

    private func activity(dayID: UUID, activityID: UUID) -> Activity? {
        trip.days
            .first(where: { $0.id == dayID })?
            .activities
            .first(where: { $0.id == activityID })
    }

    private func activity(dayIDForActivity activityID: UUID) -> Activity? {
        trip.days
            .lazy
            .flatMap(\.activities)
            .first(where: { $0.id == activityID })
    }

    private func clearItineraryUndo() {
        itineraryUndoSnapshot = nil
        itineraryUndoMessage = nil
    }

    private static func adjustmentPrompt(userRequest: String, trip: Trip) -> String {
        let days = trip.days.map { day in
            let activities = day.activities.map { activity in
                let fixedMarker = activity.isFixedNode ? " 固定节点" : ""
                let time = [activity.startTime, activity.endTime]
                    .compactMap { $0 }
                    .joined(separator: "-")
                let timeText = time.isEmpty ? "" : " \(time)"
                return "- \(activity.title)\(timeText)\(fixedMarker)"
            }
            .joined(separator: "\n")
            return "Day \(day.dayNumber) \(day.title):\n\(activities)"
        }
        .joined(separator: "\n")

        return """
        用户调整要求：
        \(userRequest)

        当前行程，请在保留用户已编辑内容和固定节点的前提下提出增量调整：
        \(days)
        """
    }

    private func travelMinutesBeforeActivityID(for days: [TripDay]) async -> [UUID: Int] {
        var result: [UUID: Int] = [:]
        for day in days {
            let travelMinutes = await travelTimeResolver.travelMinutesBeforeActivityID(for: day)
            result.merge(travelMinutes) { _, new in new }
        }
        return result
    }

    private func syncActiveWorkspace() {
        tripLibrary.updateActiveWorkspace { workspace in
            workspace.trip = trip
            workspace.journalPages = journalPages
            workspace.journalSelections = journalSelections
            workspace.stickerSelections = stickerSelections
            workspace.customStickers = customStickers
            workspace.completedActivityIDs = completedActivityIDs
            workspace.travelMinutesBeforeActivityID = travelMinutesBeforeActivityID
            workspace.enabledReminderActivityIDs = enabledReminderActivityIDs
        }
    }

    private func persist(preservingItineraryUndo: Bool = false) {
        if !preservingItineraryUndo {
            clearItineraryUndo()
        }
        syncActiveWorkspace()
        localStore.save(AppPersistenceSnapshot(tripLibrary: tripLibrary))
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

    private static func syncScheduledPackingReminder(_ reminder: PackingReminder, trip: Trip) async -> Bool {
        guard reminder.isEnabled else {
            cancelScheduledReminder(reminder)
            return false
        }

        guard let targetDate = packingNotificationTargetDate(reminder: reminder, duration: trip.duration),
              targetDate > Date() else {
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
            content.title = "织步记打包提醒"
            content.body = "\(trip.title) · \(reminder.note ?? "检查行李清单")"
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

    private static func cancelScheduledReminder(_ reminder: PackingReminder) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationIdentifier(for: reminder)]
        )
    }

    private static func cancelScheduledReminders(in trip: Trip) {
        var identifiers = trip.days
            .flatMap(\.activities)
            .compactMap(\.reminder)
            .map(notificationIdentifier)
        if let packingReminder = trip.packingList?.reminder {
            identifiers.append(notificationIdentifier(for: packingReminder))
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func notificationIdentifier(for reminder: Reminder) -> String {
        "ayuwalk.reminder.\(reminder.id.uuidString)"
    }

    private static func notificationIdentifier(for reminder: PackingReminder) -> String {
        "ayuwalk.packing-reminder.\(reminder.id.uuidString)"
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

    private static func packingNotificationTargetDate(
        reminder: PackingReminder,
        duration: TripDuration
    ) -> Date? {
        guard case let .dateRange(start, _) = duration else {
            return nil
        }

        let timeParts = reminder.fireTime.split(separator: ":")
        guard timeParts.count == 2,
              let hour = Int(timeParts[0]),
              let minute = Int(timeParts[1]) else {
            return nil
        }

        let calendar = Calendar.current
        let startOfTrip = calendar.startOfDay(for: start)
        guard let reminderDate = calendar.date(
            byAdding: .day,
            value: -reminder.dayOffsetBeforeTrip,
            to: startOfTrip
        ) else {
            return nil
        }

        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: reminderDate
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

private struct ItineraryMutationSnapshot {
    let days: [TripDay]
    let completedActivityIDs: Set<UUID>
    let travelMinutesBeforeActivityID: [UUID: Int]
    let enabledReminderActivityIDs: Set<UUID>
}
