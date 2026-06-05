import AyuWalkCore
import SwiftUI

struct PlanHomeView: View {
    @Environment(AppState.self) private var appState
    @State private var activeSheet: PlanSheet?
    @State private var isShowingRouteMap = false
    @State private var highlightedActivityID: UUID?

    var onOpenJournal: () -> Void = {}

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        tripCover(scrollProxy: scrollProxy)

                        AWSectionHeader(
                            title: "每日安排",
                            subtitle: "固定交通、酒店时间会锁定，普通点位可继续调整",
                            accessory: durationLabel
                        )

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
                                    await appState.enableReminder(dayID: day.id, activityID: activity.id)
                                }
                            },
                            onEditActivity: { day, activity in
                                activeSheet = .activity(ActivityEditTarget(day: day, activity: activity))
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
                    .padding(.top, 12)
                    .padding(.bottom, 132)
                }
                .background(AyuWalkTheme.canvas)
            }
            .navigationTitle("织步记")
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
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .budget:
                    BudgetPlannerView(
                        trip: appState.trip,
                        onUpdateBudget: appState.updateBudgetTotal,
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
                        items: appState.trip.packingList?.items ?? [],
                        onToggleItem: appState.togglePackingItem,
                        onAddItem: appState.addPackingItem,
                        onUpdateItem: appState.updatePackingItem,
                        onDeleteItems: appState.deletePackingItems,
                        onApplyTemplates: appState.applyPackingTemplates
                    )
                    .presentationDetents([.medium, .large])
                case .activity(let target):
                    ActivityEditorView(day: target.day, activity: target.activity) { draft in
                        appState.updateActivity(
                            dayID: target.day.id,
                            activityID: target.activity.id,
                            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                            startTime: draft.normalizedStartTime,
                            endTime: draft.normalizedEndTime,
                            notes: draft.normalizedNotes,
                            reminder: draft.reminder
                        )
                    }
                    .presentationDetents([.medium, .large])
                }
            }
        }
    }

    private func tripCover(scrollProxy: ScrollViewProxy) -> some View {
        AWPanel(background: AyuWalkTheme.surface) {
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

    var id: UUID {
        activity.id
    }
}

private enum PlanSheet: Identifiable {
    case budget
    case packing
    case activity(ActivityEditTarget)

    var id: String {
        switch self {
        case .budget:
            return "budget"
        case .packing:
            return "packing"
        case .activity(let target):
            return "activity-\(target.id.uuidString)"
        }
    }
}

#Preview {
    PlanHomeView()
        .environment(AppState())
}
