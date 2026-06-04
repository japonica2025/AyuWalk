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
}

public struct BudgetSplit: Equatable, Sendable {
    public var perPerson: Decimal
    public var currencyCode: String

    public init(perPerson: Decimal, currencyCode: String) {
        self.perPerson = perPerson
        self.currencyCode = currencyCode
    }
}
