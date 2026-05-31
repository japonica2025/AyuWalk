import Foundation

public struct MockJournalEngine: Sendable {
    public init() {}

    public func generatePages(for trip: Trip) -> [JournalPage] {
        [
            coverPage(for: trip),
            overviewPage(for: trip)
        ] + trip.days.enumerated().map { index, day in
            dailyPage(for: day, pageIndex: index)
        }
    }

    private func coverPage(for trip: Trip) -> JournalPage {
        JournalPage(
            id: uuid(namespace: 1, index: 1),
            kind: .cover,
            title: trip.title,
            dayID: nil,
            blocks: [
                block(.title, pageIndex: 1, blockIndex: 1, title: trip.title, text: trip.destination),
                block(.dateLocation, pageIndex: 1, blockIndex: 2, title: "旅行信息", text: "\(trip.destination) · \(durationText(for: trip.duration))")
            ]
        )
    }

    private func overviewPage(for trip: Trip) -> JournalPage {
        JournalPage(
            id: uuid(namespace: 1, index: 2),
            kind: .overview,
            title: "行程总览",
            dayID: nil,
            blocks: [
                block(.routeSummary, pageIndex: 2, blockIndex: 1, title: "路线概览", text: routeSummary(for: trip)),
                block(.budgetSummary, pageIndex: 2, blockIndex: 2, title: "预算概览", text: budgetSummary(for: trip.budgetPlan)),
                block(.packingSummary, pageIndex: 2, blockIndex: 3, title: "行李概览", text: packingSummary(for: trip.packingList))
            ]
        )
    }

    private func dailyPage(for day: TripDay, pageIndex: Int) -> JournalPage {
        let stablePageIndex = pageIndex + 3

        return JournalPage(
            id: uuid(namespace: 1, index: stablePageIndex),
            kind: .day,
            title: day.title,
            dayID: day.id,
            blocks: [
                block(.title, pageIndex: stablePageIndex, blockIndex: 1, title: day.title, text: "第 \(day.dayNumber) 天"),
                block(.dateLocation, pageIndex: stablePageIndex, blockIndex: 2, title: day.dateLabel, text: dayLocationSummary(for: day)),
                block(.photo, pageIndex: stablePageIndex, blockIndex: 3, title: "照片", text: "为今天的代表照片预留版位"),
                block(.text, pageIndex: stablePageIndex, blockIndex: 4, title: "旅行手记", text: "记录今天最想保存的瞬间。"),
                block(.timeline, pageIndex: stablePageIndex, blockIndex: 5, title: "时间线", text: timelineSummary(for: day)),
                block(.mapSnapshot, pageIndex: stablePageIndex, blockIndex: 6, title: "地图快照", text: mapSummary(for: day)),
                block(.sticker, pageIndex: stablePageIndex, blockIndex: 7, title: "贴纸", text: "天气、交通、美食、景点、心情、酒店、购物、演唱会")
            ]
        )
    }

    private func block(
        _ kind: JournalBlockKind,
        pageIndex: Int,
        blockIndex: Int,
        title: String?,
        text: String?
    ) -> JournalBlock {
        JournalBlock(
            id: uuid(namespace: 2, index: pageIndex * 100 + blockIndex),
            kind: kind,
            title: title,
            text: text,
            assetReference: nil
        )
    }

    private func durationText(for duration: TripDuration) -> String {
        switch duration {
        case .dayCount(let count):
            return "\(count) 日"
        case .dateRange:
            return "日期范围"
        }
    }

    private func routeSummary(for trip: Trip) -> String {
        let daySummaries = trip.days.map { day in
            let places = day.activities
                .sorted { $0.routeOrder < $1.routeOrder }
                .map(\.title)
                .joined(separator: " → ")
            return "\(day.dateLabel)：\(places)"
        }

        return daySummaries.isEmpty ? "暂无路线安排" : daySummaries.joined(separator: "\n")
    }

    private func budgetSummary(for budgetPlan: BudgetPlan?) -> String {
        guard let budgetPlan else {
            return "暂无预算计划"
        }

        return "预计总预算 \(budgetPlan.total) \(budgetPlan.currencyCode)"
    }

    private func packingSummary(for packingList: PackingList?) -> String {
        guard let packingList, !packingList.items.isEmpty else {
            return "暂无行李清单"
        }

        return packingList.items.map(\.title).joined(separator: "、")
    }

    private func dayLocationSummary(for day: TripDay) -> String {
        let locations = day.activities
            .compactMap(\.place?.name)
            .joined(separator: "、")

        return locations.isEmpty ? day.dateLabel : "\(day.dateLabel) · \(locations)"
    }

    private func timelineSummary(for day: TripDay) -> String {
        let entries = day.activities
            .sorted { $0.routeOrder < $1.routeOrder }
            .map { activity in
                if let timeLabel = timeLabel(for: activity) {
                    return "\(timeLabel) \(activity.title)"
                }

                return activity.title
            }

        return entries.isEmpty ? "暂无时间线安排" : entries.joined(separator: "\n")
    }

    private func timeLabel(for activity: Activity) -> String? {
        switch (activity.startTime, activity.endTime) {
        case let (start?, end?):
            return "\(start)-\(end)"
        case let (start?, nil):
            return start
        case let (nil, end?):
            return end
        case (nil, nil):
            return nil
        }
    }

    private func mapSummary(for day: TripDay) -> String {
        let orderedPlaces = day.activities
            .sorted { $0.routeOrder < $1.routeOrder }
            .compactMap(\.place?.name)

        return orderedPlaces.isEmpty ? "暂无地图点位" : orderedPlaces.joined(separator: " → ")
    }

    private func uuid(namespace: Int, index: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-%04x-%012x", namespace, index))!
    }
}

public extension JournalBlock {
    var isDefaultSelected: Bool {
        [.title, .dateLocation, .photo, .text].contains(kind)
    }
}
