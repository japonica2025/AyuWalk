import AyuWalkCore
import SwiftUI

struct PlanHomeView: View {
    @Environment(AppState.self) private var appState
    @State private var activeSheet: PlanSheet?
    @State private var isShowingRouteMap = false
    @State private var highlightedActivityID: UUID?
    @State private var createsTripAfterSheetDismiss = false
    @State private var deleteActivityTarget: ActivityEditTarget?

    var onOpenJournal: () -> Void = {}
    var onCreateTrip: () -> Void = {}

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("织步记")
                            .font(AyuWalkTypography.custom(size: 40, relativeTo: .largeTitle).weight(.bold))
                            .foregroundStyle(AyuWalkTheme.ink)

                        tripCover(scrollProxy: scrollProxy)

                        AWSectionHeader(
                            title: "每日安排",
                            subtitle: "固定交通、酒店时间会锁定，普通点位可继续调整",
                            accessory: durationLabel
                        )

                        if let undoMessage = appState.itineraryUndoMessage {
                            AWCardChrome(background: AyuWalkTheme.elevated) {
                                HStack(spacing: AyuWalkSpacing.md) {
                                    Text(undoMessage)
                                        .font(AyuWalkTypography.bodyStrong)
                                        .foregroundStyle(AyuWalkTheme.ink)
                                    Spacer()
                                    Button("撤销") {
                                        appState.undoLastItineraryEdit()
                                    }
                                    .font(AyuWalkTypography.button)
                                    .foregroundStyle(AyuWalkTheme.accent)
                                }
                            }
                        }

                        ItineraryTimelineView(
                            days: appState.trip.days,
                            duration: appState.trip.duration,
                            currentDayNumber: currentDayNumber,
                            travelMinutesBeforeActivityID: appState.travelMinutesBeforeActivityID,
                            enabledReminderActivityIDs: appState.enabledReminderActivityIDs,
                            completedActivityIDs: appState.completedActivityIDs,
                            highlightedActivityID: highlightedActivityID,
                            onRescheduleDay: { day in
                                Task {
                                    await appState.rescheduleDay(dayID: day.id)
                                }
                            },
                            onEnableReminder: { day, activity in
                                Task {
                                    await appState.toggleReminder(dayID: day.id, activityID: activity.id)
                                }
                            },
                            onAddActivity: { day in
                                activeSheet = .activity(.new(day: day))
                            },
                            onEditActivity: { day, activity in
                                activeSheet = .activity(.existing(day: day, activity: activity))
                            },
                            onDuplicateActivity: { day, activity in
                                appState.duplicateActivity(dayID: day.id, activityID: activity.id)
                            },
                            onDeleteActivity: { day, activity in
                                deleteActivityTarget = .existing(day: day, activity: activity)
                            },
                            onMoveActivity: { sourceDay, activity, destinationDay in
                                appState.moveActivity(
                                    activityID: activity.id,
                                    from: sourceDay.id,
                                    to: destinationDay.id
                                )
                            },
                            onToggleRouteInclusion: { day, activity in
                                appState.setActivityRouteInclusion(
                                    dayID: day.id,
                                    activityID: activity.id,
                                    isIncluded: activity.routeOrder == nil
                                )
                            },
                            onToggleCompletion: { _, activity in
                                appState.toggleActivityCompletion(activityID: activity.id)
                            },
                            onReorderRouteActivities: { _, activityIDs in
                                Task {
                                    await appState.reorderRouteActivitiesAndReschedule(activityIDs: activityIDs)
                                }
                            }
                        )

                        PlanQuickActionsView(
                            trip: appState.trip,
                            onOpenBudget: {
                                activeSheet = .budget
                            },
                            onOpenPacking: {
                                activeSheet = .packing
                            },
                            onOpenJournal: onOpenJournal
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 84)
                    .padding(.bottom, 132)
                }
                .background(homePaperBackground)
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $isShowingRouteMap) {
                RouteMapDetailView(
                    days: appState.trip.days,
                    initialDayNumber: currentDayNumber,
                    travelMinutesBeforeActivityID: appState.travelMinutesBeforeActivityID,
                    onReorder: { activityIDs in
                        Task {
                            await appState.reorderRouteActivitiesAndReschedule(activityIDs: activityIDs)
                        }
                    }
                )
            }
            .sheet(item: $activeSheet, onDismiss: {
                guard createsTripAfterSheetDismiss else {
                    return
                }
                createsTripAfterSheetDismiss = false
                onCreateTrip()
            }) { sheet in
                switch sheet {
                case .trips:
                    TripLibrarySheetView(
                        workspaces: appState.tripWorkspaces,
                        activeTripID: appState.tripLibrary.activeTripID,
                        onCreateTrip: {
                            createsTripAfterSheetDismiss = true
                        },
                        onSelectTrip: appState.selectTrip,
                        onDuplicateTrip: { appState.duplicateTrip(id: $0) },
                        onRenameTrip: appState.renameTrip,
                        onSetArchived: appState.setTripArchived,
                        onDeleteTrip: appState.deleteTrip
                    )
                    .presentationDetents([.medium, .large])
                case .budget:
                    BudgetPlannerView(
                        trip: appState.trip,
                        onUpdateBudget: appState.updateBudgetTotal,
                        onUpdateCategoryBudget: appState.updateCategoryBudget,
                        onUpdateExchangeRate: appState.updateExchangeRate,
                        onAddParticipant: appState.addParticipant,
                        onUpdateParticipant: appState.updateParticipant,
                        onDeleteParticipant: appState.deleteParticipant,
                        onAddExpense: appState.addBudgetExpense,
                        onUpdateExpense: appState.updateBudgetExpense,
                        onDeleteExpense: appState.deleteBudgetExpense,
                        onToggleExpenseParticipant: appState.toggleBudgetExpenseParticipant
                    )
                    .presentationDetents([.medium, .large])
                case .packing:
                    PackingListView(
                        trip: appState.trip,
                        items: appState.trip.packingList?.items ?? [],
                        onToggleItem: appState.togglePackingItem,
                        onAddItem: appState.addPackingItem,
                        onUpdateItem: appState.updatePackingItem,
                        onDeleteItems: appState.deletePackingItems,
                        onApplyTemplates: appState.applyPackingTemplates,
                        onUpdateReminder: appState.updatePackingReminder
                    )
                    .presentationDetents([.medium, .large])
                case .aiAdjustment:
                    AIAdjustmentSheetView(
                        proposal: appState.latestAIPlanningProposal,
                        isWorking: appState.isGeneratingTrip
                    ) { request in
                        Task {
                            await appState.adjustCurrentTrip(with: request)
                        }
                    }
                    .presentationDetents([.medium, .large])
                case .activity(let target):
                    ActivityEditorView(
                        days: appState.trip.days,
                        day: target.day,
                        activity: target.activity,
                        isCreating: target.isCreating,
                        onSearchPlaces: appState.searchPlaces
                    ) { draft in
                        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
                        if target.isCreating {
                            let newActivity = Activity(
                                id: UUID(),
                                title: title,
                                kind: draft.kind,
                                place: draft.place,
                                startTime: draft.normalizedStartTime,
                                endTime: draft.normalizedEndTime,
                                notes: draft.normalizedNotes,
                                estimatedCost: nil,
                                routeOrder: nil,
                                reminder: draft.reminder,
                                isFixedNode: draft.isFixedNode
                            )
                            appState.addActivity(
                                newActivity,
                                to: draft.targetDayID,
                                includeInRoute: draft.isIncludedInRoute,
                                enableReminder: draft.isReminderEnabled
                            )
                        } else {
                            appState.updateActivity(
                                dayID: target.day.id,
                                activityID: target.activity.id,
                                targetDayID: draft.targetDayID,
                                title: title,
                                kind: draft.kind,
                                place: draft.place,
                                startTime: draft.normalizedStartTime,
                                endTime: draft.normalizedEndTime,
                                notes: draft.normalizedNotes,
                                reminder: draft.reminder,
                                isFixedNode: draft.isFixedNode,
                                includeInRoute: draft.isIncludedInRoute,
                                enableReminder: draft.isReminderEnabled
                            )
                        }
                    }
                    .presentationDetents([.medium, .large])
                }
            }
            .confirmationDialog(
                "确定删除“\(deleteActivityTarget?.activity.title ?? "")”吗？",
                isPresented: deleteActivityDialogBinding,
                titleVisibility: .visible
            ) {
                Button("删除项目", role: .destructive) {
                    guard let target = deleteActivityTarget else { return }
                    appState.deleteActivity(dayID: target.day.id, activityID: target.activity.id)
                    deleteActivityTarget = nil
                }
                Button("取消", role: .cancel) {
                    deleteActivityTarget = nil
                }
            } message: {
                Text("删除后可在行程页撤销一次。")
            }
        }
    }

    private var deleteActivityDialogBinding: Binding<Bool> {
        Binding(
            get: { deleteActivityTarget != nil },
            set: { if !$0 { deleteActivityTarget = nil } }
        )
    }

    private func tripCover(scrollProxy: ScrollViewProxy) -> some View {
        AWPanel(background: AyuWalkTheme.surface, showsPaperTexture: true) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("AYU WALK")
                            .font(AyuWalkTypography.brand)
                            .foregroundStyle(AyuWalkTheme.accent)
                        Text("织步记")
                            .font(AyuWalkTypography.captionStrong)
                            .foregroundStyle(AyuWalkTheme.mutedInk)
                    }

                    Spacer()

                    AWPlainIconButton(
                        systemImage: "rectangle.stack.fill",
                        label: "打开行程库",
                        tint: AyuWalkTheme.secondaryAccent
                    ) {
                        activeSheet = .trips
                    }

                    AWStatusPill(
                        text: appState.isGeneratingTrip ? "生成中" : "可编辑",
                        systemImage: appState.isGeneratingTrip ? "sparkles" : "checkmark.seal.fill",
                        tint: appState.isGeneratingTrip ? AyuWalkTheme.accent : AyuWalkTheme.secondaryAccent,
                        isFilled: appState.isGeneratingTrip
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(appState.trip.title)
                        .font(AyuWalkTypography.screenTitle)
                        .foregroundStyle(AyuWalkTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)

                    Text(headerMessage)
                        .font(AyuWalkTypography.body)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        AWStatusPill(text: appState.trip.destination, systemImage: "mappin.and.ellipse", tint: AyuWalkTheme.accent)
                        AWStatusPill(text: currentDateLabel, systemImage: "calendar", tint: AyuWalkTheme.secondaryAccent)
                        AWStatusPill(text: "Day \(currentDayNumber)", systemImage: "rectangle.stack.fill", tint: AyuWalkTheme.secondaryAccent)
                    }
                }

                AWActionCapsuleButton(
                    title: "AI 调整",
                    systemImage: "sparkles",
                    tint: AyuWalkTheme.accent,
                    isProminent: false
                ) {
                    activeSheet = .aiAdjustment
                }

                HStack(spacing: 10) {
                    Button {
                        activeSheet = .budget
                    } label: {
                        AWMetricTile(title: "预算规划", value: budgetSummary, tint: AyuWalkTheme.secondaryAccent)
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.plain)
                    .accessibilityLabel("打开预算规划")

                    Button {
                        activeSheet = .packing
                    } label: {
                        AWMetricTile(title: "行李清单", value: packingSummary, tint: AyuWalkTheme.accent)
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.plain)
                    .accessibilityLabel("打开行李清单")

                    Button {
                        guard let day = currentTripDay,
                              let activity = nextRouteActivity else { return }
                        highlightedActivityID = activity.id
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                            scrollProxy.scrollTo(day.id, anchor: .top)
                        }
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            if highlightedActivityID == activity.id {
                                highlightedActivityID = nil
                            }
                        }
                    } label: {
                        AWMetricTile(title: "下一站", value: nextRouteTitle, tint: AyuWalkTheme.ink)
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.plain)
                    .accessibilityLabel("跳到下一站")
                }

                Button {
                    isShowingRouteMap = true
                } label: {
                    RouteMapPreviewView(days: appState.trip.days, previewDayNumber: currentDayNumber)
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(alignment: .topLeading) {
            Image.awWashiTapeRose
                .resizable()
                .scaledToFit()
                .frame(width: 128)
                .rotationEffect(.degrees(-2))
                .offset(x: 30, y: -20)
                .shadow(color: AyuWalkTheme.ink.opacity(0.08), radius: 4, y: 2)
                .allowsHitTesting(false)
        }
    }

    private var homePaperBackground: some View {
        AWPaperBackground()
    }

    private var routeActivities: [Activity] {
        appState.trip.days.flatMap(\.activities).filter { $0.routeOrder != nil }
    }

    private var lockedActivities: [Activity] {
        appState.trip.days
            .flatMap(\.activities)
            .filter(ScheduleConflictDetector.isLockedFixedNode)
    }

    private var todayRouteCount: Int {
        appState.trip.days
            .first { $0.dayNumber == currentDayNumber }?
            .activities
            .filter { $0.routeOrder != nil }
            .count ?? 0
    }

    private var currentTripDay: TripDay? {
        appState.trip.days.first { $0.dayNumber == currentDayNumber }
    }

    private var nextRouteActivity: Activity? {
        guard let currentTripDay else {
            return nil
        }

        let availableActivities = currentTripDay.activities
            .filter { activity in
                activity.routeOrder != nil && !appState.completedActivityIDs.contains(activity.id)
            }
            .sorted(by: routeActivityPrecedes)

        guard isCurrentTravelDate(currentTripDay) else {
            return availableActivities.first
        }

        let currentMinute = Calendar.current.component(.hour, from: Date()) * 60
            + Calendar.current.component(.minute, from: Date())
        return availableActivities.first { activity in
            guard let startMinute = minuteValue(activity.startTime) else {
                return true
            }
            return startMinute >= currentMinute
        } ?? availableActivities.first
    }

    private var nextRouteTitle: String {
        nextRouteActivity?.title ?? "待定"
    }

    private func routeActivityPrecedes(_ lhs: Activity, _ rhs: Activity) -> Bool {
        switch (lhs.routeOrder, rhs.routeOrder) {
        case let (.some(lhsOrder), .some(rhsOrder)):
            return lhsOrder < rhsOrder
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }

    private func isCurrentTravelDate(_ day: TripDay) -> Bool {
        guard case let .dateRange(start, _) = appState.trip.duration,
              let dayDate = Calendar.current.date(byAdding: .day, value: day.dayNumber - 1, to: start) else {
            return false
        }

        return Calendar.current.isDate(dayDate, inSameDayAs: Date())
    }

    private func minuteValue(_ timeText: String?) -> Int? {
        guard let timeText else {
            return nil
        }

        let parts = timeText.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              (0...23).contains(hour),
              (0...59).contains(minute) else {
            return nil
        }

        return hour * 60 + minute
    }

    private var budgetSummary: String {
        guard let budget = appState.trip.budgetPlan else {
            return "待规划"
        }

        let amount = NSDecimalNumber(decimal: budget.total).intValue
        return "\(budget.currencyCode) \(amount)"
    }

    private var packingSummary: String {
        "\(appState.trip.packingList?.items.count ?? 0) 件"
    }

    private var currentDayNumber: Int {
        let totalDays = max(appState.trip.days.count, 1)
        switch appState.trip.duration {
        case .dateRange(let start, let end):
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let startDay = calendar.startOfDay(for: start)
            let endDay = calendar.startOfDay(for: end)
            if today <= startDay {
                return 1
            }
            if today >= endDay {
                return totalDays
            }
            let offset = calendar.dateComponents([.day], from: startDay, to: today).day ?? 0
            return min(max(offset + 1, 1), totalDays)
        case .dayCount:
            return 1
        }
    }

    private var currentDateLabel: String {
        switch appState.trip.duration {
        case .dateRange(let start, let end):
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let startDay = calendar.startOfDay(for: start)
            let endDay = calendar.startOfDay(for: end)
            let displayDate: Date
            if today <= startDay {
                displayDate = start
            } else if today >= endDay {
                displayDate = end
            } else {
                displayDate = today
            }
            return Self.shortOrdinalDateString(for: displayDate)
        case .dayCount:
            return "日期待定"
        }
    }

    private var headerMessage: String {
        if appState.isGeneratingTrip {
            return "正在定位目的地并生成路线。"
        }

        return appState.aiPlanningMessage ?? "AI 已生成初版路线，地图点位和路线顺序保持一致。"
    }

    private var durationLabel: String {
        switch appState.trip.duration {
        case .dayCount(let count):
            return "\(count) 天"
        case .dateRange:
            return "日期行程"
        }
    }

    private static func shortOrdinalDateString(for date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        return "\(shortMonthFormatter.string(from: date)) \(day)\(ordinalSuffix(for: day))"
    }

    private static func ordinalSuffix(for day: Int) -> String {
        let remainder = day % 100
        if (11...13).contains(remainder) {
            return "th"
        }

        switch day % 10 {
        case 1:
            return "st"
        case 2:
            return "nd"
        case 3:
            return "rd"
        default:
            return "th"
        }
    }

    private static let shortMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        return formatter
    }()
}

private struct ActivityEditTarget: Identifiable {
    let day: TripDay
    let activity: Activity
    let isCreating: Bool

    static func existing(day: TripDay, activity: Activity) -> ActivityEditTarget {
        ActivityEditTarget(day: day, activity: activity, isCreating: false)
    }

    static func new(day: TripDay) -> ActivityEditTarget {
        ActivityEditTarget(
            day: day,
            activity: Activity(
                id: UUID(),
                title: "",
                kind: .sight,
                place: nil,
                startTime: nil,
                endTime: nil,
                notes: nil,
                estimatedCost: nil,
                routeOrder: nil,
                reminder: nil,
                isFixedNode: false
            ),
            isCreating: true
        )
    }

    var id: UUID {
        activity.id
    }
}

private enum PlanSheet: Identifiable {
    case trips
    case budget
    case packing
    case aiAdjustment
    case activity(ActivityEditTarget)

    var id: String {
        switch self {
        case .trips:
            return "trips"
        case .budget:
            return "budget"
        case .packing:
            return "packing"
        case .aiAdjustment:
            return "ai-adjustment"
        case .activity(let target):
            return "activity-\(target.id.uuidString)"
        }
    }
}

private struct AIAdjustmentSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let proposal: AIPlanningProposal?
    let isWorking: Bool
    let onApply: (String) -> Void
    @State private var request = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AyuWalkSpacing.xl) {
                    AWPanel(background: AyuWalkTheme.surface) {
                        VStack(alignment: .leading, spacing: AyuWalkSpacing.sm) {
                            Text("告诉 AI 想怎么调整")
                                .font(AyuWalkTypography.sectionTitle)
                                .foregroundStyle(AyuWalkTheme.ink)
                            Text("固定航班、酒店和提醒节点会保留；普通路线点会在确认后重新安排。")
                                .font(AyuWalkTypography.body)
                                .foregroundStyle(AyuWalkTheme.mutedInk)
                        }
                    }

                    TextEditor(text: $request)
                        .font(AyuWalkTypography.body)
                        .foregroundStyle(AyuWalkTheme.ink)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 140)
                        .padding(AyuWalkSpacing.md)
                        .background(AyuWalkTheme.paper)
                        .clipShape(RoundedRectangle(cornerRadius: AyuWalkTheme.cardRadius, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: AyuWalkTheme.cardRadius, style: .continuous)
                                .stroke(AyuWalkTheme.border, lineWidth: 1)
                        }

                    if let proposal {
                        AWCardChrome(background: AyuWalkTheme.elevated) {
                            VStack(alignment: .leading, spacing: AyuWalkSpacing.sm) {
                                AWStatusPill(
                                    text: "上次规划置信度 \(Int(proposal.confidence * 100))%",
                                    systemImage: proposal.source == .remoteAI ? "sparkles" : "arrow.triangle.2.circlepath",
                                    tint: proposal.source == .remoteAI ? AyuWalkTheme.accent : AyuWalkTheme.secondaryAccent,
                                    isFilled: true
                                )
                                if let reason = proposal.adjustmentReason {
                                    Text(reason)
                                        .font(AyuWalkTypography.body)
                                        .foregroundStyle(AyuWalkTheme.mutedInk)
                                }
                                ForEach(proposal.assumptions) { assumption in
                                    Label(assumption.text, systemImage: "info.circle")
                                        .font(AyuWalkTypography.caption)
                                        .foregroundStyle(AyuWalkTheme.mutedInk)
                                }
                            }
                        }
                    }

                    AWPrimaryButton(
                        title: isWorking ? "正在调整" : "确认并应用调整",
                        systemImage: "sparkles",
                        tint: request.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? AyuWalkTheme.mutedInk
                            : AyuWalkTheme.accent
                    ) {
                        onApply(request)
                        dismiss()
                    }
                    .disabled(request.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isWorking)
                }
                .padding(AyuWalkSpacing.pageInset)
            }
            .background(AyuWalkTheme.canvas)
            .navigationTitle("AI 调整行程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

private struct TripLibrarySheetView: View {
    let workspaces: [TripWorkspace]
    let activeTripID: UUID?
    let onCreateTrip: () -> Void
    let onSelectTrip: (UUID) -> Void
    let onDuplicateTrip: (UUID) -> Void
    let onRenameTrip: (UUID, String) -> Void
    let onSetArchived: (Bool, UUID) -> Void
    let onDeleteTrip: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var renameTarget: TripWorkspace?
    @State private var renameText = ""
    @State private var deleteTarget: TripWorkspace?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AyuWalkSpacing.xl) {
                    AWPrimaryButton(title: "新建行程", systemImage: "plus") {
                        onCreateTrip()
                        dismiss()
                    }

                    workspaceSection(title: "当前与进行中", workspaces: activeWorkspaces)

                    if !archivedWorkspaces.isEmpty {
                        workspaceSection(title: "已归档", workspaces: archivedWorkspaces)
                    }
                }
                .padding(AyuWalkSpacing.pageInset)
            }
            .background(AyuWalkTheme.canvas)
            .navigationTitle("行程库")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("重命名行程", isPresented: renameAlertBinding) {
                TextField("行程名称", text: $renameText)
                Button("取消", role: .cancel) {}
                Button("保存") {
                    guard let renameTarget else { return }
                    onRenameTrip(renameTarget.id, renameText)
                }
            }
            .confirmationDialog(
                "确定删除“\(deleteTarget?.trip.title ?? "")”吗？",
                isPresented: deleteDialogBinding,
                titleVisibility: .visible
            ) {
                Button("删除行程", role: .destructive) {
                    guard let deleteTarget else { return }
                    onDeleteTrip(deleteTarget.id)
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("该行程中的路线、预算、行李和手帐内容都会被删除。")
            }
        }
    }

    private var activeWorkspaces: [TripWorkspace] {
        workspaces.filter { !$0.isArchived }
    }

    private var archivedWorkspaces: [TripWorkspace] {
        workspaces.filter(\.isArchived)
    }

    private var renameAlertBinding: Binding<Bool> {
        Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )
    }

    private var deleteDialogBinding: Binding<Bool> {
        Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        )
    }

    @ViewBuilder
    private func workspaceSection(title: String, workspaces: [TripWorkspace]) -> some View {
        VStack(alignment: .leading, spacing: AyuWalkSpacing.md) {
            AWSectionHeader(title: title, accessory: "\(workspaces.count)")

            ForEach(workspaces) { workspace in
                tripRow(workspace)
            }
        }
    }

    private func tripRow(_ workspace: TripWorkspace) -> some View {
        AWCardChrome(background: workspace.id == activeTripID ? AyuWalkTheme.elevated : AyuWalkTheme.surface) {
            HStack(spacing: AyuWalkSpacing.md) {
                Button {
                    onSelectTrip(workspace.id)
                    dismiss()
                } label: {
                    AWInfoRow(
                        title: workspace.trip.title,
                        subtitle: "\(workspace.trip.destination) · \(workspace.trip.days.count) 天",
                        systemImage: workspace.isArchived ? "archivebox.fill" : "map.fill",
                        tint: workspace.id == activeTripID ? AyuWalkTheme.secondaryAccent : AyuWalkTheme.accent,
                        trailingSystemImage: workspace.id == activeTripID ? "checkmark.circle.fill" : nil
                    )
                }
                .buttonStyle(.plain)
                .disabled(workspace.id == activeTripID)

                Menu {
                    Button {
                        onDuplicateTrip(workspace.id)
                        dismiss()
                    } label: {
                        Label("复制", systemImage: "doc.on.doc")
                    }

                    Button {
                        renameText = workspace.trip.title
                        renameTarget = workspace
                    } label: {
                        Label("重命名", systemImage: "pencil")
                    }

                    Button {
                        onSetArchived(!workspace.isArchived, workspace.id)
                    } label: {
                        Label(workspace.isArchived ? "取消归档" : "归档", systemImage: workspace.isArchived ? "tray.and.arrow.up" : "archivebox")
                    }

                    Button(role: .destructive) {
                        deleteTarget = workspace
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                    .disabled(self.workspaces.count == 1)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(AyuWalkTypography.icon(size: 20))
                        .foregroundStyle(AyuWalkTheme.ink)
                        .frame(width: AyuWalkSize.iconButton, height: AyuWalkSize.iconButton)
                }
                .accessibilityLabel("管理 \(workspace.trip.title)")
            }
        }
    }
}

#Preview {
    PlanHomeView()
        .environment(AppState())
}
