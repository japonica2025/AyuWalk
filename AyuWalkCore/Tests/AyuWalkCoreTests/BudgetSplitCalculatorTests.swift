import XCTest
@testable import AyuWalkCore

final class BudgetSplitCalculatorTests: XCTestCase {
    func testPerPersonAmountDividesTotalByParticipantCount() {
        let budget = BudgetPlan(total: 12000, currencyCode: "CNY")

        let split = BudgetSplitCalculator.split(budget: budget, participantCount: 3)

        XCTAssertEqual(split.currencyCode, "CNY")
        XCTAssertEqual(split.perPerson, 4000)
    }

    func testPerPersonAmountIsZeroWhenParticipantCountIsZero() {
        let budget = BudgetPlan(total: 12000, currencyCode: "CNY")

        let split = BudgetSplitCalculator.split(budget: budget, participantCount: 0)

        XCTAssertEqual(split.perPerson, 0)
    }

    func testExpenseSharesDivideExpenseAcrossIncludedParticipants() {
        let anna = UUID()
        let ben = UUID()
        let expense = BudgetExpense(
            id: UUID(),
            title: "晚餐",
            amount: 6000,
            category: .food,
            participantIDs: [anna, ben],
            notes: nil
        )

        let shares = BudgetSplitCalculator.expenseShares(expense)

        XCTAssertEqual(shares, [
            BudgetParticipantShare(participantID: anna, amount: 3000),
            BudgetParticipantShare(participantID: ben, amount: 3000)
        ])
    }

    func testExpenseSharesExcludeRemovedParticipants() {
        let anna = UUID()
        let ben = UUID()
        let expense = BudgetExpense(
            id: UUID(),
            title: "门票",
            amount: 9000,
            category: .ticket,
            participantIDs: [anna],
            notes: "Ben 没有参加"
        )

        let shares = BudgetSplitCalculator.expenseShares(expense)

        XCTAssertEqual(shares, [
            BudgetParticipantShare(participantID: anna, amount: 9000)
        ])
        XCTAssertFalse(shares.contains { $0.participantID == ben })
    }

    func testParticipantTotalsSumAcrossExpenses() {
        let anna = UUID()
        let ben = UUID()
        let expenses = [
            BudgetExpense(
                id: UUID(),
                title: "晚餐",
                amount: 6000,
                category: .food,
                participantIDs: [anna, ben],
                notes: nil
            ),
            BudgetExpense(
                id: UUID(),
                title: "伴手礼",
                amount: 2000,
                category: .shopping,
                participantIDs: [anna],
                notes: nil
            )
        ]

        let totals = BudgetSplitCalculator.participantTotals(for: expenses)

        XCTAssertEqual(totals[anna], 5000)
        XCTAssertEqual(totals[ben], 3000)
    }

    func testParticipantTotalsGroupByExpenseCurrency() {
        let anna = UUID()
        let expenses = [
            BudgetExpense(
                id: UUID(),
                title: "Dinner",
                amount: 100,
                category: .food,
                participantIDs: [anna],
                currencyCode: "EUR",
                notes: nil
            ),
            BudgetExpense(
                id: UUID(),
                title: "Taxi",
                amount: 2000,
                category: .transport,
                participantIDs: [anna],
                currencyCode: "JPY",
                notes: nil
            )
        ]

        let totals = BudgetSplitCalculator.participantTotalsByCurrency(for: expenses)

        XCTAssertEqual(totals[anna]?["EUR"], 100)
        XCTAssertEqual(totals[anna]?["JPY"], 2000)
    }

    func testExpenseTotalsGroupByCurrencyWithoutMixingAmounts() {
        let expenses = [
            BudgetExpense(
                id: UUID(),
                title: "Dinner",
                amount: 100,
                category: .food,
                participantIDs: [],
                currencyCode: "EUR",
                notes: nil
            ),
            BudgetExpense(
                id: UUID(),
                title: "Taxi",
                amount: 2000,
                category: .transport,
                participantIDs: [],
                currencyCode: "JPY",
                notes: nil
            ),
            BudgetExpense(
                id: UUID(),
                title: "Coffee",
                amount: 12,
                category: .food,
                participantIDs: [],
                currencyCode: "EUR",
                notes: nil
            )
        ]

        let totals = BudgetSplitCalculator.expenseTotalsByCurrency(for: expenses)

        XCTAssertEqual(totals["EUR"], 112)
        XCTAssertEqual(totals["JPY"], 2000)
    }
}
