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

    func testExpenseSharesUseCustomAmountsWhenSelected() {
        let anna = UUID()
        let ben = UUID()
        let expense = BudgetExpense(
            id: UUID(),
            title: "酒店",
            amount: 9000,
            category: .lodging,
            participantIDs: [anna, ben],
            payerID: anna,
            currencyCode: "JPY",
            splitMode: .custom,
            customShares: [anna: 3000, ben: 6000],
            notes: nil
        )

        let shares = BudgetSplitCalculator.expenseShares(expense)

        XCTAssertEqual(shares, [
            BudgetParticipantShare(participantID: anna, amount: 3000),
            BudgetParticipantShare(participantID: ben, amount: 6000)
        ])
    }

    func testExpenseSharesNormalizeCustomAmountsToExpenseTotal() {
        let anna = UUID()
        let ben = UUID()
        let expense = BudgetExpense(
            id: UUID(),
            title: "酒店",
            amount: 120,
            category: .lodging,
            participantIDs: [anna, ben],
            payerID: anna,
            currencyCode: "EUR",
            splitMode: .custom,
            customShares: [anna: 50, ben: 50],
            notes: nil
        )

        let shares = BudgetSplitCalculator.expenseShares(expense)

        XCTAssertEqual(shares, [
            BudgetParticipantShare(participantID: anna, amount: 60),
            BudgetParticipantShare(participantID: ben, amount: 60)
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

    func testCategoryProgressUsesConfiguredCategoryBudgets() {
        let budget = BudgetPlan(
            total: 1000,
            currencyCode: "EUR",
            categoryBudgets: [
                .food: 300,
                .transport: 200
            ],
            expenses: [
                BudgetExpense(
                    id: UUID(),
                    title: "Dinner",
                    amount: 120,
                    category: .food,
                    participantIDs: [],
                    currencyCode: "EUR",
                    notes: nil
                ),
                BudgetExpense(
                    id: UUID(),
                    title: "Coffee",
                    amount: 30,
                    category: .food,
                    participantIDs: [],
                    currencyCode: "EUR",
                    notes: nil
                ),
                BudgetExpense(
                    id: UUID(),
                    title: "Taxi",
                    amount: 80,
                    category: .transport,
                    participantIDs: [],
                    currencyCode: "EUR",
                    notes: nil
                )
            ]
        )

        let progress = BudgetSplitCalculator.categoryProgress(for: budget)

        XCTAssertEqual(progress, [
            BudgetCategoryProgress(category: .transport, budgeted: 200, spent: 80, currencyCode: "EUR"),
            BudgetCategoryProgress(category: .food, budgeted: 300, spent: 150, currencyCode: "EUR")
        ])
        XCTAssertEqual(progress.first { $0.category == .food }?.usageRatio, Decimal(string: "0.5"))
    }

    func testCategoryProgressIncludesUnbudgetedSpentCategoriesByCurrency() {
        let budget = BudgetPlan(
            total: 1000,
            currencyCode: "EUR",
            categoryBudgets: [.food: 300],
            expenses: [
                BudgetExpense(
                    id: UUID(),
                    title: "Museum",
                    amount: 60,
                    category: .ticket,
                    participantIDs: [],
                    currencyCode: "EUR",
                    notes: nil
                ),
                BudgetExpense(
                    id: UUID(),
                    title: "Train",
                    amount: 2000,
                    category: .transport,
                    participantIDs: [],
                    currencyCode: "JPY",
                    notes: nil
                )
            ]
        )

        let progress = BudgetSplitCalculator.categoryProgress(for: budget)

        XCTAssertEqual(progress, [
            BudgetCategoryProgress(category: .food, budgeted: 300, spent: 0, currencyCode: "EUR"),
            BudgetCategoryProgress(category: .ticket, budgeted: 0, spent: 60, currencyCode: "EUR"),
            BudgetCategoryProgress(category: .transport, budgeted: 0, spent: 2000, currencyCode: "JPY")
        ])
        XCTAssertNil(progress[1].usageRatio)
    }

    func testSettlementTransfersDebtorsToPayersByCurrency() {
        let anna = UUID()
        let ben = UUID()
        let expense = BudgetExpense(
            id: UUID(),
            title: "Dinner",
            amount: 120,
            category: .food,
            participantIDs: [anna, ben],
            payerID: anna,
            currencyCode: "EUR",
            notes: nil
        )

        let transfers = BudgetSplitCalculator.settlementTransfers(for: [expense])

        XCTAssertEqual(transfers, [
            BudgetSettlementTransfer(fromParticipantID: ben, toParticipantID: anna, amount: 60, currencyCode: "EUR")
        ])
    }

    func testSettlementTransfersUseCustomShares() {
        let anna = UUID()
        let ben = UUID()
        let expense = BudgetExpense(
            id: UUID(),
            title: "Hotel",
            amount: 9000,
            category: .lodging,
            participantIDs: [anna, ben],
            payerID: anna,
            currencyCode: "JPY",
            splitMode: .custom,
            customShares: [anna: 3000, ben: 6000],
            notes: nil
        )

        let transfers = BudgetSplitCalculator.settlementTransfers(for: [expense])

        XCTAssertEqual(transfers, [
            BudgetSettlementTransfer(fromParticipantID: ben, toParticipantID: anna, amount: 6000, currencyCode: "JPY")
        ])
    }

    func testSettlementTransfersIgnoreInvalidDeletedPayer() {
        let anna = UUID()
        let ben = UUID()
        let deleted = UUID()
        let expense = BudgetExpense(
            id: UUID(),
            title: "Dinner",
            amount: 120,
            category: .food,
            participantIDs: [anna, ben],
            payerID: deleted,
            currencyCode: "EUR",
            notes: nil
        )

        let transfers = BudgetSplitCalculator.settlementTransfers(for: [expense])

        XCTAssertEqual(transfers, [
            BudgetSettlementTransfer(fromParticipantID: ben, toParticipantID: anna, amount: 60, currencyCode: "EUR")
        ])
    }
}
