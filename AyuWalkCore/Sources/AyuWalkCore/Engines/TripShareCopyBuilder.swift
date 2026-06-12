import Foundation

public enum TripShareCopyBuilder {
    public static func socialCopy(trip: Trip) -> String {
        var sections: [String] = []
        sections.append("\(trip.title) 路线整理好了。")
        sections.append("这次去 \(trip.destination)，我把每日路线、预算、AA 和行李清单放在一起，方便边走边调整。")

        let highlights = itineraryHighlights(for: trip)
        if !highlights.isEmpty {
            sections.append("路线亮点：\(highlights.joined(separator: " · "))")
        }

        if let budgetSummary = budgetSummary(for: trip) {
            sections.append(budgetSummary)
        }

        if let packingSummary = packingSummary(for: trip.packingList) {
            sections.append(packingSummary)
        }

        sections.append("#织步记 #AyuWalk #旅行规划 #电子手帐 #\(trip.destination)旅行")
        return sections.joined(separator: "\n\n")
    }

    private static func itineraryHighlights(for trip: Trip) -> [String] {
        trip.days
            .sorted { $0.dayNumber < $1.dayNumber }
            .prefix(3)
            .compactMap { day in
                let activityTitles = day.activities
                    .sorted(by: routeOrderPrecedes)
                    .prefix(2)
                    .map(\.title)
                guard !activityTitles.isEmpty else {
                    return nil
                }
                return "Day \(day.dayNumber) \(activityTitles.joined(separator: " -> "))"
            }
    }

    private static func budgetSummary(for trip: Trip) -> String? {
        guard let budget = trip.budgetPlan else {
            return nil
        }

        var parts = ["预算 \(normalizedCurrencyCode(budget.currencyCode)) \(amountText(budget.total))"]
        let expenseTotals = BudgetSplitCalculator.expenseTotalsByCurrency(for: budget.expenses)
        if !expenseTotals.isEmpty {
            parts.append("已记录 \(format(totalsByCurrency: expenseTotals))")
        }

        let settlementTexts = BudgetSplitCalculator
            .settlementTransfers(for: budget.expenses)
            .map { transfer in
                let fromName = participantName(for: transfer.fromParticipantID, in: trip)
                let toName = participantName(for: transfer.toParticipantID, in: trip)
                return "\(fromName) 转给 \(toName)：\(normalizedCurrencyCode(transfer.currencyCode)) \(amountText(transfer.amount))"
            }
        if !settlementTexts.isEmpty {
            parts.append("结算 \(settlementTexts.joined(separator: "；"))")
        }

        return parts.joined(separator: "，")
    }

    private static func packingSummary(for packingList: PackingList?) -> String? {
        guard let packingList, !packingList.items.isEmpty else {
            return nil
        }

        let packedCount = packingList.items.filter(\.isPacked).count
        return "行李 \(packedCount)/\(packingList.items.count) 已打包。"
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

    private static func format(totalsByCurrency: [String: Decimal]) -> String {
        totalsByCurrency
            .sorted { $0.key < $1.key }
            .map { "\(normalizedCurrencyCode($0.key)) \(amountText($0.value))" }
            .joined(separator: " / ")
    }

    private static func amountText(_ amount: Decimal) -> String {
        let number = NSDecimalNumber(decimal: amount)
        if amount == Decimal(number.intValue) {
            return "\(number.intValue)"
        }
        return number.stringValue
    }

    private static func normalizedCurrencyCode(_ currencyCode: String) -> String {
        let trimmed = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "CNY" : trimmed.uppercased()
    }

    private static func participantName(for participantID: UUID, in trip: Trip) -> String {
        trip.participants.first(where: { $0.id == participantID })?.name ?? "某人"
    }
}
