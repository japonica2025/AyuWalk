import Foundation

public struct MockJournalEngine: Sendable {
    public init() {}

    public func generatePages(for trip: Trip) -> [JournalPage] {
        [
            coverPage(for: trip),
            overviewPage(for: trip)
        ] + trip.days.map { day in
            dailyPage(for: day)
        }
    }

    private func coverPage(for trip: Trip) -> JournalPage {
        let pageSeed = "trip:\(trip.id.uuidString):cover"

        return JournalPage(
            id: stableID(pageSeed),
            kind: .cover,
            title: trip.title,
            dayID: nil,
            blocks: [
                block(.title, parentSeed: pageSeed, title: trip.title, text: trip.destination),
                block(.dateLocation, parentSeed: pageSeed, title: "旅行信息", text: "\(trip.destination) · \(durationText(for: trip.duration))")
            ]
        )
    }

    private func overviewPage(for trip: Trip) -> JournalPage {
        let pageSeed = "trip:\(trip.id.uuidString):overview"

        return JournalPage(
            id: stableID(pageSeed),
            kind: .overview,
            title: "行程总览",
            dayID: nil,
            blocks: [
                block(.routeSummary, parentSeed: pageSeed, title: "路线概览", text: routeSummary(for: trip)),
                block(.budgetSummary, parentSeed: pageSeed, title: "预算概览", text: budgetSummary(for: trip.budgetPlan)),
                block(.packingSummary, parentSeed: pageSeed, title: "行李概览", text: packingSummary(for: trip.packingList))
            ]
        )
    }

    private func dailyPage(for day: TripDay) -> JournalPage {
        let pageSeed = "day:\(day.id.uuidString):day"

        return JournalPage(
            id: stableID(pageSeed),
            kind: .day,
            title: day.title,
            dayID: day.id,
            blocks: [
                block(.title, parentSeed: pageSeed, title: day.title, text: "第 \(day.dayNumber) 天"),
                block(.dateLocation, parentSeed: pageSeed, title: day.dateLabel, text: dayLocationSummary(for: day)),
                block(.photo, parentSeed: pageSeed, title: "照片", text: "为今天的代表照片预留版位"),
                block(.text, parentSeed: pageSeed, title: "旅行手记", text: "记录今天最想保存的瞬间。"),
                block(.timeline, parentSeed: pageSeed, title: "时间线", text: timelineSummary(for: day)),
                block(.mapSnapshot, parentSeed: pageSeed, title: "地图快照", text: mapSummary(for: day)),
                block(.sticker, parentSeed: pageSeed, title: "贴纸", text: "天气、交通、美食、景点、心情、酒店、购物、演唱会")
            ]
        )
    }

    private func block(
        _ kind: JournalBlockKind,
        parentSeed: String,
        title: String?,
        text: String?
    ) -> JournalBlock {
        JournalBlock(
            id: stableID("\(parentSeed):block:\(kind.rawValue)"),
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

    private func stableID(_ seed: String) -> UUID {
        let bytes = Array(seed.utf8)
        let first = fnv1a64(bytes, offsetBasis: 0xcbf29ce484222325)
        let second = fnv1a64(bytes, offsetBasis: 0x84222325cbf29ce4)
        let uuidBytes = (0..<16).map { index -> UInt8 in
            let value = index < 8 ? first : second
            return UInt8((value >> ((index % 8) * 8)) & 0xff)
        }

        return UUID(uuid: (
            uuidBytes[0],
            uuidBytes[1],
            uuidBytes[2],
            uuidBytes[3],
            uuidBytes[4],
            uuidBytes[5],
            uuidBytes[6],
            uuidBytes[7],
            uuidBytes[8],
            uuidBytes[9],
            uuidBytes[10],
            uuidBytes[11],
            uuidBytes[12],
            uuidBytes[13],
            uuidBytes[14],
            uuidBytes[15]
        ))
    }

    private func fnv1a64(_ bytes: [UInt8], offsetBasis: UInt64) -> UInt64 {
        bytes.reduce(offsetBasis) { hash, byte in
            (hash ^ UInt64(byte)) &* 0x00000100000001b3
        }
    }
}

public extension JournalBlock {
    /// Initial module default policy for mock journal generation, not persisted user selection state.
    var isDefaultSelected: Bool {
        [.title, .dateLocation, .photo, .text].contains(kind)
    }
}
