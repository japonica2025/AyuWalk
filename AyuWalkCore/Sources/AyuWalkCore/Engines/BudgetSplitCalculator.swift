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

        if expense.splitMode == .custom {
            let rawShares = participantIDs.map { participantID in
                BudgetParticipantShare(participantID: participantID, amount: max(expense.customShares[participantID] ?? 0, 0))
            }
            let customTotal = rawShares.reduce(Decimal(0)) { $0 + $1.amount }
            guard customTotal > 0 else {
                let perPersonAmount = expense.amount / Decimal(participantIDs.count)
                return participantIDs.map { BudgetParticipantShare(participantID: $0, amount: perPersonAmount) }
            }
            if customTotal == expense.amount {
                return rawShares
            }
            return rawShares.map { share in
                BudgetParticipantShare(
                    participantID: share.participantID,
                    amount: share.amount / customTotal * expense.amount
                )
            }
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

    public static func settlementTransfers(for expenses: [BudgetExpense]) -> [BudgetSettlementTransfer] {
        let balancesByCurrency = expenses.reduce(into: [String: [UUID: Decimal]]()) { balancesByCurrency, expense in
            let currencyCode = expense.currencyCode.isEmpty ? "CNY" : expense.currencyCode
            let payerID = validPayerID(for: expense)
            if let payerID {
                balancesByCurrency[currencyCode, default: [:]][payerID, default: 0] += expense.amount
            }

            for share in expenseShares(expense) {
                balancesByCurrency[currencyCode, default: [:]][share.participantID, default: 0] -= share.amount
            }
        }

        return balancesByCurrency
            .flatMap { currencyCode, balances in
                settlementTransfers(for: balances, currencyCode: currencyCode)
            }
            .sorted { lhs, rhs in
                if lhs.currencyCode != rhs.currencyCode {
                    return lhs.currencyCode < rhs.currencyCode
                }
                if lhs.fromParticipantID != rhs.fromParticipantID {
                    return lhs.fromParticipantID.uuidString < rhs.fromParticipantID.uuidString
                }
                return lhs.toParticipantID.uuidString < rhs.toParticipantID.uuidString
            }
    }

    private static func validPayerID(for expense: BudgetExpense) -> UUID? {
        if let payerID = expense.payerID, expense.participantIDs.contains(payerID) {
            return payerID
        }
        return expense.participantIDs.first
    }

    private static func settlementTransfers(
        for balances: [UUID: Decimal],
        currencyCode: String
    ) -> [BudgetSettlementTransfer] {
        var debtors = balances
            .filter { $0.value < 0 }
            .map { (participantID: $0.key, amount: -$0.value) }
            .sorted { $0.participantID.uuidString < $1.participantID.uuidString }
        var creditors = balances
            .filter { $0.value > 0 }
            .map { (participantID: $0.key, amount: $0.value) }
            .sorted { $0.participantID.uuidString < $1.participantID.uuidString }

        var transfers: [BudgetSettlementTransfer] = []
        var debtorIndex = 0
        var creditorIndex = 0

        while debtorIndex < debtors.count, creditorIndex < creditors.count {
            let amount = min(debtors[debtorIndex].amount, creditors[creditorIndex].amount)
            if amount > 0 {
                transfers.append(
                    BudgetSettlementTransfer(
                        fromParticipantID: debtors[debtorIndex].participantID,
                        toParticipantID: creditors[creditorIndex].participantID,
                        amount: amount,
                        currencyCode: currencyCode
                    )
                )
            }
            debtors[debtorIndex].amount -= amount
            creditors[creditorIndex].amount -= amount
            if debtors[debtorIndex].amount == 0 {
                debtorIndex += 1
            }
            if creditors[creditorIndex].amount == 0 {
                creditorIndex += 1
            }
        }

        return transfers
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

public struct BudgetSettlementTransfer: Equatable, Sendable {
    public var fromParticipantID: UUID
    public var toParticipantID: UUID
    public var amount: Decimal
    public var currencyCode: String

    public init(
        fromParticipantID: UUID,
        toParticipantID: UUID,
        amount: Decimal,
        currencyCode: String
    ) {
        self.fromParticipantID = fromParticipantID
        self.toParticipantID = toParticipantID
        self.amount = amount
        self.currencyCode = currencyCode
    }
}
