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
            let expenseTotals = BudgetSplitCalculator.expenseTotalsByCurrency(for: budget.expenses)
            if !expenseTotals.isEmpty {
                lines.append("- 已记录：\(format(totalsByCurrency: expenseTotals))")
                let convertedTotal = BudgetSplitCalculator.convertedExpenseTotal(for: budget)
                lines.append("- 折算已记录：\(convertedTotal.currencyCode) \(amountText(convertedTotal.amount))")
                if !convertedTotal.missingCurrencyCodes.isEmpty {
                    lines.append("- 未折算币种：\(convertedTotal.missingCurrencyCodes.joined(separator: "、"))")
                }
                let exchangeRateTexts = exchangeRateTexts(for: budget)
                if !exchangeRateTexts.isEmpty {
                    lines.append("- 手动汇率：\(exchangeRateTexts.joined(separator: " / "))")
                }
            }

            let categoryProgress = BudgetSplitCalculator.categoryProgress(for: budget)
            if !categoryProgress.isEmpty {
                lines.append("")
                lines.append("### 分类预算")
                for item in categoryProgress {
                    let budgetText = item.budgeted > 0
                        ? "\(item.currencyCode) \(amountText(item.budgeted))"
                        : "未设置"
                    lines.append("- \(item.category.displayName)：已用 \(item.currencyCode) \(amountText(item.spent)) / 预算 \(budgetText)")
                }
            }

            let participantTotals = BudgetSplitCalculator.participantTotalsByCurrency(for: budget.expenses)
            if !participantTotals.isEmpty {
                lines.append("")
                lines.append("### AA 摘要")
                for participant in trip.participants {
                    let totals = participantTotals[participant.id] ?? [:]
                    if !totals.isEmpty {
                        lines.append("- \(participant.name)：\(format(totalsByCurrency: totals))")
                    }
                }
            }

            let transfers = BudgetSplitCalculator.settlementTransfers(for: budget.expenses)
            if !transfers.isEmpty {
                lines.append("")
                lines.append("### 结算建议")
                for transfer in transfers {
                    let fromName = participantName(for: transfer.fromParticipantID, in: trip)
                    let toName = participantName(for: transfer.toParticipantID, in: trip)
                    lines.append("- \(fromName) 转给 \(toName)：\(transfer.currencyCode) \(amountText(transfer.amount))")
                }
            }
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

    private static func format(totalsByCurrency: [String: Decimal]) -> String {
        totalsByCurrency
            .sorted { $0.key < $1.key }
            .map { "\($0.key) \(amountText($0.value))" }
            .joined(separator: " / ")
    }

    private static func amountText(_ amount: Decimal) -> String {
        let number = NSDecimalNumber(decimal: amount)
        if amount == Decimal(number.intValue) {
            return "\(number.intValue)"
        }
        return number.stringValue
    }

    private static func exchangeRateTexts(for budget: BudgetPlan) -> [String] {
        let baseCurrencyCode = normalizedCurrencyCode(budget.currencyCode)
        return budget.exchangeRates
            .filter { normalizedCurrencyCode($0.key) != baseCurrencyCode && $0.value > 0 }
            .sorted { $0.key < $1.key }
            .map { currencyCode, rate in
                "1 \(normalizedCurrencyCode(currencyCode)) = \(amountText(rate)) \(baseCurrencyCode)"
            }
    }

    private static func normalizedCurrencyCode(_ currencyCode: String) -> String {
        let trimmed = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "CNY" : trimmed.uppercased()
    }

    private static func participantName(for participantID: UUID, in trip: Trip) -> String {
        trip.participants.first(where: { $0.id == participantID })?.name ?? "某人"
    }
}
