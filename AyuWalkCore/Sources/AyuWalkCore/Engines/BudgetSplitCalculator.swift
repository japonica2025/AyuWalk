import Foundation

public enum BudgetSplitCalculator {
    public static func split(budget: BudgetPlan, participantCount: Int) -> BudgetSplit {
        guard participantCount > 0 else {
            return BudgetSplit(perPerson: 0, currencyCode: budget.currencyCode)
        }

        return BudgetSplit(
            perPerson: budget.total / Decimal(participantCount),
            currencyCode: budget.currencyCode
        )
    }

    public static func expenseShares(_ expense: BudgetExpense) -> [BudgetParticipantShare] {
        let participantIDs = expense.participantIDs
        guard !participantIDs.isEmpty else {
            return []
        }

        let perPersonAmount = expense.amount / Decimal(participantIDs.count)
        return participantIDs.map { participantID in
            BudgetParticipantShare(participantID: participantID, amount: perPersonAmount)
        }
    }

    public static func participantTotals(for expenses: [BudgetExpense]) -> [UUID: Decimal] {
        expenses.reduce(into: [:]) { totals, expense in
            for share in expenseShares(expense) {
                totals[share.participantID, default: 0] += share.amount
            }
        }
    }

    public static func participantTotalsByCurrency(for expenses: [BudgetExpense]) -> [UUID: [String: Decimal]] {
        expenses.reduce(into: [:]) { totals, expense in
            let currencyCode = expense.currencyCode.isEmpty ? "CNY" : expense.currencyCode
            for share in expenseShares(expense) {
                totals[share.participantID, default: [:]][currencyCode, default: 0] += share.amount
            }
        }
    }

    public static func expenseTotalsByCurrency(for expenses: [BudgetExpense]) -> [String: Decimal] {
        expenses.reduce(into: [:]) { totals, expense in
            let currencyCode = expense.currencyCode.isEmpty ? "CNY" : expense.currencyCode
            totals[currencyCode, default: 0] += expense.amount
        }
    }
}

public struct BudgetSplit: Equatable, Sendable {
    public var perPerson: Decimal
    public var currencyCode: String

    public init(perPerson: Decimal, currencyCode: String) {
        self.perPerson = perPerson
        self.currencyCode = currencyCode
    }
}
