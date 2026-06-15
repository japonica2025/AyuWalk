import AyuWalkCore
import SwiftUI

struct ItineraryTimelineView: View {
    let days: [TripDay]
    var duration: TripDuration? = nil
    var currentDayNumber: Int = 1
    var travelMinutesBeforeActivityID: [UUID: Int] = [:]
    var enabledReminderActivityIDs: Set<UUID> = []
    var completedActivityIDs: Set<UUID> = []
    var highlightedActivityID: UUID?
    var onRescheduleDay: (TripDay) -> Void = { _ in }
    var onEnableReminder: (TripDay, Activity) -> Void = { _, _ in }
    var onAddActivity: (TripDay) -> Void = { _ in }
    var onEditActivity: (TripDay, Activity) -> Void = { _, _ in }
    var onDuplicateActivity: (TripDay, Activity) -> Void = { _, _ in }
    var onDeleteActivity: (TripDay, Activity) -> Void = { _, _ in }
    var onMoveActivity: (TripDay, Activity, TripDay) -> Void = { _, _, _ in }
    var onToggleRouteInclusion: (TripDay, Activity) -> Void = { _, _ in }
    var onToggleCompletion: (TripDay, Activity) -> Void = { _, _ in }
    var onReorderRouteActivities: (TripDay, [UUID]) -> Void = { _, _ in }

    @State private var userExpandedDayIDs: Set<UUID> = []
    @State private var userCollapsedDayIDs: Set<UUID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: AyuWalkSpacing.lg) {
            ForEach(orderedDays) { day in
                daySection(day)
                    .id(day.id)
            }
        }
    }

    private func daySection(_ day: TripDay) -> some View {
        let isExpanded = isExpanded(day)
        let conflictsByActivityID = Dictionary(
            grouping: ScheduleConflictDetector.conflicts(in: day),
            by: \.activityID
        )

        return AWPaperSurface(
            background: AyuWalkTheme.surface,
            tint: day.dayNumber == currentDayNumber ? AyuWalkTheme.accent : AyuWalkTheme.secondaryAccent,
            cornerRadius: AyuWalkTheme.panelRadius,
            padding: AyuWalkSpacing.lg,
            borderOpacity: day.dayNumber == currentDayNumber ? 0.14 : 0.09,
            shadowRadius: 14,
            shadowY: 7
        ) {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.md) {
                dayHeader(day, isExpanded: isExpanded)

                if isExpanded {
                    HStack {
                        Spacer()

                        AWActionCapsuleButton(
                            title: "新增",
                            systemImage: "plus",
                            tint: AyuWalkTheme.secondaryAccent
                        ) {
                            onAddActivity(day)
                        }

                        AWActionCapsuleButton(
                            title: "重排当天",
                            systemImage: "arrow.triangle.2.circlepath",
                            tint: AyuWalkTheme.accent
                        ) {
                            onRescheduleDay(day)
                        }
                    }

                    activityList(day, conflictsByActivityID: conflictsByActivityID)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            Image.awWashiTapeCream
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 24)
                .rotationEffect(.degrees(-3))
                .opacity(day.dayNumber == currentDayNumber ? 0.62 : 0.42)
                .offset(x: 22, y: -12)
                .allowsHitTesting(false)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.88), value: isExpanded)
    }

    private func activityList(
        _ day: TripDay,
        conflictsByActivityID: [UUID: [ScheduleConflict]]
    ) -> some View {
        let activities = displayActivities(in: day)

        return List {
            ForEach(activities) { activity in
                activityRow(
                    activity,
                    day: day,
                    conflict: conflictsByActivityID[activity.id]?.first
                )
                .id(activity.id)
                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .moveDisabled(ScheduleConflictDetector.isLockedFixedNode(activity))
            }
            .onMove { source, destination in
                var movedActivities = activities
                movedActivities.move(fromOffsets: source, toOffset: destination)
                let routeActivityIDs = RouteReorderPolicy.routeActivityIDs(afterDisplaying: movedActivities)
                onReorderRouteActivities(day, routeActivityIDs)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
        .frame(height: activityListHeight(for: activities.count))
        .clipShape(RoundedRectangle(cornerRadius: AyuWalkRadii.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AyuWalkRadii.card, style: .continuous)
                .stroke(AyuWalkTheme.hairline, lineWidth: 1)
        }
    }

    private func dayHeader(_ day: TripDay, isExpanded: Bool) -> some View {
        Button {
            toggleDay(day)
        } label: {
            HStack(spacing: AyuWalkSpacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            day.dayNumber == currentDayNumber
                                ? AyuWalkTheme.accent.opacity(0.14)
                                : AyuWalkTheme.secondaryAccent.opacity(0.12)
                        )
                        .frame(width: 42, height: 42)

                    Text("\(day.dayNumber)")
                        .font(AyuWalkTypography.captionStrong)
                        .foregroundStyle(
                            day.dayNumber == currentDayNumber
                                ? AyuWalkTheme.accent
                                : AyuWalkTheme.secondaryAccent
                        )
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text("\(day.dateLabel)｜\(day.title)")
                            .font(AyuWalkTypography.sectionTitle)
                            .foregroundStyle(AyuWalkTheme.ink)

                        if day.dayNumber == currentDayNumber {
                            AWStatusPill(text: "当天", tint: AyuWalkTheme.secondaryAccent)
                        }
                    }

                    Text("\(day.activities.count) 个行程")
                        .font(AyuWalkTypography.caption)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                }

                Spacer()

                AWStickerIconTray(
                    systemImages: isExpanded ? ["chevron.up"] : ["chevron.down"],
                    tint: day.dayNumber == currentDayNumber ? AyuWalkTheme.accent : AyuWalkTheme.secondaryAccent
                )
                .scaleEffect(0.82)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isExpanded ? "收起\(day.title)" : "展开\(day.title)")
    }

    private func activityRow(
        _ activity: Activity,
        day: TripDay,
        conflict: ScheduleConflict?
    ) -> some View {
        let isCompleted = completedActivityIDs.contains(activity.id)
        let isMissed = ItineraryDayDisplayPolicy.isMissed(
            activity,
            on: day,
            currentDayNumber: currentDayNumber,
            completedActivityIDs: completedActivityIDs
        )

        return HStack(alignment: .top, spacing: 12) {
            if ScheduleConflictDetector.isLockedFixedNode(activity) {
                lockedBadge
            } else if activity.routeOrder == nil {
                unroutedBadge
            } else {
                routeBadge(routeIndex(for: activity, in: day) ?? 1)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(activity.title)
                        .font(AyuWalkTypography.bodyStrong)
                        .foregroundStyle(activityTitleColor(isCompleted: isCompleted, isMissed: isMissed))
                        .strikethrough(isMissed, color: AyuWalkTheme.mutedInk)

                    if ScheduleConflictDetector.isLockedFixedNode(activity) {
                        AWStatusPill(
                            text: "已锁定",
                            systemImage: "lock.fill",
                            tint: AyuWalkTheme.secondaryAccent
                        )
                    }
                }

                if let time = timeLabel(for: activity) {
                    Text(time)
                        .font(AyuWalkTypography.caption)
                        .foregroundStyle(AyuWalkTheme.secondaryAccent)
                }

                if let travelText = travelText(before: activity) {
                    AWStatusPill(
                        text: travelText,
                        systemImage: "figure.walk.motion",
                        tint: AyuWalkTheme.secondaryAccent
                    )
                }

                if let notes = activity.notes {
                    Text(notes)
                        .font(AyuWalkTypography.body)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                }

                if let countdownText = countdownText(for: activity, on: day) {
                    HStack(spacing: 8) {
                        AWStatusPill(
                            text: countdownText,
                            systemImage: "clock",
                            tint: AyuWalkTheme.secondaryAccent,
                            lineLimit: 2
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Button {
                            onEnableReminder(day, activity)
                        } label: {
                            Image(systemName: enabledReminderActivityIDs.contains(activity.id) ? "bell.fill" : "bell")
                                .font(AyuWalkTypography.icon(size: 12, weight: .bold))
                                .foregroundStyle(
                                    enabledReminderActivityIDs.contains(activity.id)
                                        ? AyuWalkTheme.accent
                                        : AyuWalkTheme.secondaryAccent
                                )
                                .frame(width: 28, height: 28)
                                .background(AyuWalkTheme.pageBackground)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            enabledReminderActivityIDs.contains(activity.id)
                                ? "关闭\(activity.title)提醒"
                                : "开启\(activity.title)提醒"
                        )
                    }
                }

                if let conflict {
                    AWStatusPill(
                        text: conflict.message,
                        systemImage: "exclamationmark.triangle.fill",
                        tint: AyuWalkTheme.accent,
                        lineLimit: 2
                    )
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    onToggleCompletion(day, activity)
                } label: {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(AyuWalkTypography.icon(size: 17, weight: .bold))
                        .foregroundStyle(isCompleted ? AyuWalkTheme.secondaryAccent : AyuWalkTheme.mutedInk)
                        .frame(width: 32, height: 32)
                        .background(AyuWalkTheme.chipSurface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isCompleted ? "取消完成\(activity.title)" : "标记完成\(activity.title)")

                Button {
                    onEditActivity(day, activity)
                } label: {
                    Image(systemName: "pencil")
                        .font(AyuWalkTypography.icon(size: 12, weight: .bold))
                        .foregroundStyle(AyuWalkTheme.accent)
                        .frame(width: 32, height: 32)
                        .background(AyuWalkTheme.chipSurface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("编辑\(activity.title)")

                Menu {
                    Button {
                        onDuplicateActivity(day, activity)
                    } label: {
                        Label("复制", systemImage: "doc.on.doc")
                    }

                    if !activity.isFixedNode {
                        Button {
                            onToggleRouteInclusion(day, activity)
                        } label: {
                            Label(
                                activity.routeOrder == nil ? "加入路线" : "移出路线",
                                systemImage: activity.routeOrder == nil ? "point.topleft.down.to.point.bottomright.curvepath" : "point.3.filled.connected.trianglepath.dotted"
                            )
                        }
                    }

                    Menu("移动到其他天") {
                        ForEach(days.filter { $0.id != day.id }) { destinationDay in
                            Button("\(destinationDay.dateLabel) · \(destinationDay.title)") {
                                onMoveActivity(day, activity, destinationDay)
                            }
                        }
                    }

                    Button(role: .destructive) {
                        onDeleteActivity(day, activity)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(AyuWalkTypography.icon(size: 12, weight: .bold))
                        .foregroundStyle(AyuWalkTheme.ink)
                        .frame(width: 32, height: 32)
                        .background(AyuWalkTheme.chipSurface)
                        .clipShape(Circle())
                }
                .accessibilityLabel("管理\(activity.title)")
            }
        }
        .padding(AyuWalkSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: AyuWalkRadii.card, style: .continuous)
                .fill(
                    activity.id == highlightedActivityID
                        ? AyuWalkTheme.secondaryAccent.opacity(0.12)
                        : AyuWalkTheme.surface.opacity(0.82)
                )

            Image.awPaperCardSurface
                .resizable()
                .scaledToFill()
                .opacity(AyuWalkTexture.cardOpacity * 0.75)
                .blendMode(.multiply)
                .clipShape(RoundedRectangle(cornerRadius: AyuWalkRadii.card, style: .continuous))
        }
        .overlay {
            RoundedRectangle(cornerRadius: AyuWalkRadii.card, style: .continuous)
                .stroke(
                    activity.id == highlightedActivityID ? AyuWalkTheme.secondaryAccent.opacity(0.45) : AyuWalkTheme.hairline,
                    lineWidth: 1
                )
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: highlightedActivityID)
    }

    private var orderedDays: [TripDay] {
        ItineraryDayDisplayPolicy.orderedDays(days, currentDayNumber: currentDayNumber)
    }

    private func isExpanded(_ day: TripDay) -> Bool {
        if userExpandedDayIDs.contains(day.id) {
            return true
        }
        if userCollapsedDayIDs.contains(day.id) {
            return false
        }
        return ItineraryDayDisplayPolicy.isExpandedByDefault(
            day,
            currentDayNumber: currentDayNumber
        )
    }

    private func toggleDay(_ day: TripDay) {
        if isExpanded(day) {
            userCollapsedDayIDs.insert(day.id)
            userExpandedDayIDs.remove(day.id)
        } else {
            userExpandedDayIDs.insert(day.id)
            userCollapsedDayIDs.remove(day.id)
        }
    }

    private func activityTitleColor(isCompleted: Bool, isMissed: Bool) -> Color {
        if isMissed {
            return AyuWalkTheme.mutedInk
        }
        if isCompleted {
            return AyuWalkTheme.secondaryAccent
        }
        return AyuWalkTheme.ink
    }

    private func routeBadge(_ order: Int) -> some View {
        Text(String(order))
            .font(AyuWalkTypography.captionStrong)
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(AyuWalkTheme.accent)
            .clipShape(Circle())
    }

    private var lockedBadge: some View {
        Image(systemName: "lock.fill")
            .font(AyuWalkTypography.icon(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(AyuWalkTheme.accent)
            .clipShape(Circle())
    }

    private var unroutedBadge: some View {
        Image(systemName: "minus")
            .font(AyuWalkTypography.icon(size: 12, weight: .bold))
            .foregroundStyle(AyuWalkTheme.mutedInk)
            .frame(width: 26, height: 26)
            .background(AyuWalkTheme.pageBackground)
            .clipShape(Circle())
    }

    private func routeIndex(for activity: Activity, in day: TripDay) -> Int? {
        if let routeOrder = activity.routeOrder {
            return routeOrder
        }

        let routeActivities = displayActivities(in: day).filter { $0.routeOrder != nil }
        guard let index = routeActivities.firstIndex(where: { $0.id == activity.id }) else {
            return nil
        }
        return index + 1
    }

    private func displayActivities(in day: TripDay) -> [Activity] {
        day.activities.sorted(by: activityDisplayPrecedes)
    }

    private func activityDisplayPrecedes(_ lhs: Activity, _ rhs: Activity) -> Bool {
        switch (lhs.routeOrder, rhs.routeOrder) {
        case let (.some(lhsOrder), .some(rhsOrder)):
            return lhsOrder < rhsOrder
        case (.some, .none):
            if ScheduleConflictDetector.isLockedFixedNode(rhs),
               let lhsMinute = minuteValue(lhs.startTime),
               let rhsMinute = minuteValue(rhs.startTime ?? rhs.reminder?.fireTime) {
                return lhsMinute < rhsMinute
            }
            return true
        case (.none, .some):
            if ScheduleConflictDetector.isLockedFixedNode(lhs),
               let lhsMinute = minuteValue(lhs.startTime ?? lhs.reminder?.fireTime),
               let rhsMinute = minuteValue(rhs.startTime) {
                return lhsMinute < rhsMinute
            }
            return false
        case (.none, .none):
            let lhsMinute = minuteValue(lhs.startTime ?? lhs.reminder?.fireTime)
            let rhsMinute = minuteValue(rhs.startTime ?? rhs.reminder?.fireTime)
            switch (lhsMinute, rhsMinute) {
            case let (.some(lhsMinute), .some(rhsMinute)):
                return lhsMinute < rhsMinute
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
        }
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

    private func activityListHeight(for count: Int) -> CGFloat {
        max(CGFloat(count) * 118, 140)
    }

    private func timeLabel(for activity: Activity) -> String? {
        let parts = [activity.startTime, activity.endTime].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: "-")
    }

    private func travelText(before activity: Activity) -> String? {
        guard let minutes = travelMinutesBeforeActivityID[activity.id] else {
            return nil
        }
        return TravelTimeFormatter.routeSegmentText(minutes: minutes)
    }

    private func countdownText(for activity: Activity, on day: TripDay) -> String? {
        guard let reminder = activity.reminder else {
            return nil
        }

        let timeText = activity.startTime ?? reminder.fireTime
        guard let targetDate = targetDate(for: day, timeText: timeText) else {
            return "固定时间提醒 · \(timeText)"
        }

        let interval = targetDate.timeIntervalSince(Date())
        guard interval > 0 else {
            return "固定时间已到 · \(timeText)"
        }

        let totalHours = Int(interval / 3600)
        let days = totalHours / 24
        let hours = totalHours % 24
        if days > 0 {
            return "倒计时 \(days) 天 \(hours) 小时 · \(timeText)"
        }
        return "倒计时 \(max(totalHours, 1)) 小时 · \(timeText)"
    }

    private func targetDate(for day: TripDay, timeText: String) -> Date? {
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

#Preview {
    ItineraryTimelineView(days: SampleTripFactory.tokyoFiveDayTrip().days)
        .padding()
}
