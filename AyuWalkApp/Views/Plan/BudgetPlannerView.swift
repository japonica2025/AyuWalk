import AyuWalkCore
import SwiftUI

struct BudgetPlannerView: View {
    let trip: Trip
    let onUpdateBudget: (Decimal) -> Void
    let onAddParticipant: (String) -> Void
    let onUpdateParticipant: (UUID, String) -> Void
    let onDeleteParticipant: (UUID) -> Void
    let onAddExpense: (String, Decimal, BudgetCategory, String?) -> Void
    let onUpdateExpense: (UUID, String, Decimal, BudgetCategory, String?) -> Void
    let onDeleteExpense: (UUID) -> Void
    let onToggleExpenseParticipant: (UUID, UUID) -> Void

    @State private var budgetText = ""
    @State private var newParticipantName = ""
    @State private var newExpenseTitle = ""
    @State private var newExpenseAmountText = ""
    @State private var newExpenseCategory: BudgetCategory = .food
    @State private var newExpenseNotes = ""

    private var budget: BudgetPlan {
        trip.budgetPlan ?? BudgetPlan(total: 0, currencyCode: "CNY")
    }

    private var split: BudgetSplit {
        BudgetSplitCalculator.split(
            budget: budget,
            participantCount: trip.participants.count
        )
    }

    private var recordedTotal: Decimal {
        budget.expenses.reduce(0) { $0 + $1.amount }
    }

    private var participantTotals: [UUID: Decimal] {
        BudgetSplitCalculator.participantTotals(for: budget.expenses)
    }

    var body: some View {
        AWSheetScaffold(title: "预算规划") {
            AWBudgetTotalCard(
                currencyCode: budget.currencyCode,
                participants: trip.participants,
                budgetText: $budgetText,
                newParticipantName: $newParticipantName,
                onSave: {
                    guard let amount = decimal(from: budgetText) else {
                        budgetText = plainAmount(budget.total)
                        return
                    }
                    onUpdateBudget(amount)
                },
                onAddParticipant: {
                    onAddParticipant(newParticipantName)
                    newParticipantName = ""
                },
                onUpdateParticipant: onUpdateParticipant,
                onDeleteParticipant: onDeleteParticipant
            )

            AWBudgetSplitCard(
                perPersonText: format(amount: split.perPerson, currencyCode: split.currencyCode),
                participantCount: trip.participants.count,
                recordedTotalText: format(amount: recordedTotal, currencyCode: budget.currencyCode)
            )

            AWBudgetExpenseEntryCard(
                title: $newExpenseTitle,
                amountText: $newExpenseAmountText,
                category: $newExpenseCategory,
                notes: $newExpenseNotes,
                currencyCode: budget.currencyCode
            ) {
                guard let amount = decimal(from: newExpenseAmountText), amount > 0 else {
                    return
                }
                onAddExpense(
                    newExpenseTitle,
                    amount,
                    newExpenseCategory,
                    newExpenseNotes
                )
                newExpenseTitle = ""
                newExpenseAmountText = ""
                newExpenseCategory = .food
                newExpenseNotes = ""
            }

            AWBudgetExpenseListCard(
                expenses: budget.expenses,
                participants: trip.participants,
                currencyCode: budget.currencyCode,
                participantTotals: participantTotals,
                onUpdate: onUpdateExpense,
                onDelete: onDeleteExpense,
                onToggleParticipant: onToggleExpenseParticipant
            )
        }
        .onAppear {
            budgetText = plainAmount(budget.total)
        }
        .onChange(of: budget.total) { _, newValue in
            budgetText = plainAmount(newValue)
        }
    }

    private func decimal(from text: String) -> Decimal? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")
        return Decimal(string: normalized)
    }

    private func plainAmount(_ amount: Decimal) -> String {
        let number = NSDecimalNumber(decimal: amount)
        if amount == Decimal(number.intValue) {
            return "\(number.intValue)"
        }
        return number.stringValue
    }

    private func format(amount: Decimal, currencyCode: String) -> String {
        let number = NSDecimalNumber(decimal: amount).intValue
        return "\(currencyCode) \(number)"
    }
}

#Preview {
    BudgetPlannerView(
        trip: SampleTripFactory.tokyoFiveDayTrip(),
        onUpdateBudget: { _ in },
        onAddParticipant: { _ in },
        onUpdateParticipant: { _, _ in },
        onDeleteParticipant: { _ in },
        onAddExpense: { _, _, _, _ in },
        onUpdateExpense: { _, _, _, _, _ in },
        onDeleteExpense: { _ in },
        onToggleExpenseParticipant: { _, _ in }
    )
}
