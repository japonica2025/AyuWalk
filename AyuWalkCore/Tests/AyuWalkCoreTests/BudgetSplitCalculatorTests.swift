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
}
