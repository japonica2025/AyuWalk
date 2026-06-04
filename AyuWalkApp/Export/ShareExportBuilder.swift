import AyuWalkCore
import Foundation

struct ShareExportBuilder {
    static func markdown(
        trip: Trip,
        journalPages: [JournalPage],
        selectedBlocks: (JournalPage) -> [JournalBlock],
        selectedStickers: (JournalPage) -> [Sticker]
    ) -> String {
        var lines: [String] = [
            "# \(trip.title)",
            "",
            "- 目的地：\(trip.destination)",
            "- 产品：\(trip.englishProductName)",
            "- 天数：\(durationText(for: trip.duration))",
            ""
        ]

        lines.append("## 行程")
        for day in trip.days {
            lines.append("")
            lines.append("### \(day.dateLabel) \(day.title)")
            for activity in day.activities.sorted(by: routeOrderPrecedes) {
                let time = timeText(for: activity)
                lines.append("- \(time)\(activity.title)")
                if let notes = activity.notes, !notes.isEmpty {
                    lines.append("  - 备注：\(notes)")
                }
            }
        }

        if let budget = trip.budgetPlan {
            lines.append("")
            lines.append("## 预算")
            lines.append("- 总预算：\(budget.currencyCode) \(NSDecimalNumber(decimal: budget.total).intValue)")
        }

        if let packingList = trip.packingList {
            lines.append("")
            lines.append("## 行李清单")
            for item in packingList.items {
                lines.append("- [\(item.isPacked ? "x" : " ")] \(item.title)")
            }
        }

        lines.append("")
        lines.append("## 电子手帐")
        for page in journalPages {
            lines.append("")
            lines.append("### \(page.title)")
            for block in selectedBlocks(page) {
                if let title = block.title {
                    lines.append("- \(title)：\(block.text ?? "")")
                } else if let text = block.text {
                    lines.append("- \(text)")
                }
            }

            let stickers = selectedStickers(page)
            if !stickers.isEmpty {
                lines.append("- 贴纸：\(stickers.map(\.title).joined(separator: "、"))")
            }
        }

        lines.append("")
        lines.append("> Created with 织步记 / Ayu Walk")
        return lines.joined(separator: "\n")
    }

    static func socialCopy(trip: Trip) -> String {
        let firstDay = trip.days.first?.title ?? trip.destination
        return """
        \(trip.title) 初版路线整理好了。

        这次想用轻松一点的节奏走 \(trip.destination)，先从 \(firstDay) 开始，把路线、预算、行李和手帐草稿放在一起慢慢调整。

        #织步记 #AyuWalk #旅行规划 #电子手帐 #\(trip.destination)旅行
        """
    }

    private static func durationText(for duration: TripDuration) -> String {
        switch duration {
        case .dayCount(let count):
            return "\(count) 天"
        case .dateRange:
            return "日期范围"
        }
    }

    private static func routeOrderPrecedes(_ lhs: Activity, _ rhs: Activity) -> Bool {
        switch (lhs.routeOrder, rhs.routeOrder) {
        case let (lhsOrder?, rhsOrder?):
            return lhsOrder < rhsOrder
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return lhs.title < rhs.title
        }
    }

    private static func timeText(for activity: Activity) -> String {
        let parts = [activity.startTime, activity.endTime].compactMap { $0 }
        return parts.isEmpty ? "" : "\(parts.joined(separator: "-")) "
    }
}
