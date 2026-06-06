import AyuWalkCore
import SwiftUI

struct BudgetPlannerView: View {
    let trip: Trip
    let onUpdateBudget: (Decimal, String) -> Void
    let onAddParticipant: (String) -> Void
    let onUpdateParticipant: (UUID, String) -> Void
    let onDeleteParticipant: (UUID) -> Void
    let onAddExpense: (String, Decimal, BudgetCategory, String, UUID?, String?) -> Void
    let onUpdateExpense: (UUID, String, Decimal, BudgetCategory, String, UUID?, BudgetSplitMode, [UUID: Decimal], String?) -> Void
    let onDeleteExpense: (UUID) -> Void
    let onToggleExpenseParticipant: (UUID, UUID) -> Void

    @State private var budgetText = ""
    @State private var newParticipantName = ""
    @State private var newExpenseTitle = ""
    @State private var newExpenseAmountText = ""
    @State private var newExpenseCategory: BudgetCategory = .food
    @State private var newExpenseCurrencyCode = ""
    @State private var newExpensePayerID: UUID?
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

    private var recordedTotalsByCurrency: [String: Decimal] {
        BudgetSplitCalculator.expenseTotalsByCurrency(for: budget.expenses)
    }

    private var participantTotals: [UUID: Decimal] {
        BudgetSplitCalculator.participantTotals(for: budget.expenses)
    }

    private var participantTotalsByCurrency: [UUID: [String: Decimal]] {
        BudgetSplitCalculator.participantTotalsByCurrency(for: budget.expenses)
    }

    private var settlementTransfers: [BudgetSettlementTransfer] {
        BudgetSplitCalculator.settlementTransfers(for: budget.expenses)
    }

    var body: some View {
        AWSheetScaffold(title: "预算规划") {
            AWBudgetTotalCard(
                currencyCode: budget.currencyCode,
                participants: trip.participants,
                budgetText: $budgetText,
                newParticipantName: $newParticipantName,
                onCurrencyChange: { currencyCode in
                    onUpdateBudget(budget.total, currencyCode)
                    if newExpenseCurrencyCode.isEmpty {
                        newExpenseCurrencyCode = currencyCode
                    }
                },
                onSave: {
                    guard let amount = decimal(from: budgetText) else {
                        budgetText = plainAmount(budget.total)
                        return
                    }
                    onUpdateBudget(amount, budget.currencyCode)
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
                recordedTotalText: format(totalsByCurrency: recordedTotalsByCurrency)
            )

            AWBudgetExpenseEntryCard(
                title: $newExpenseTitle,
                amountText: $newExpenseAmountText,
                category: $newExpenseCategory,
                currencyCode: $newExpenseCurrencyCode,
                payerID: $newExpensePayerID,
                notes: $newExpenseNotes,
                participants: trip.participants,
                defaultCurrencyCode: budget.currencyCode
            ) {
                guard let amount = decimal(from: newExpenseAmountText), amount > 0 else {
                    return
                }
                let currencyCode = newExpenseCurrencyCode.isEmpty ? budget.currencyCode : newExpenseCurrencyCode
                onAddExpense(
                    newExpenseTitle,
                    amount,
                    newExpenseCategory,
                    currencyCode,
                    newExpensePayerID ?? trip.participants.first?.id,
                    newExpenseNotes
                )
                newExpenseTitle = ""
                newExpenseAmountText = ""
                newExpenseCategory = .food
                newExpenseCurrencyCode = budget.currencyCode
                newExpensePayerID = trip.participants.first?.id
                newExpenseNotes = ""
            }

            AWBudgetExpenseListCard(
                expenses: budget.expenses,
                participants: trip.participants,
                currencyCode: budget.currencyCode,
                participantTotals: participantTotals,
                participantTotalsByCurrency: participantTotalsByCurrency,
                settlementTransfers: settlementTransfers,
                onUpdate: onUpdateExpense,
                onDelete: onDeleteExpense,
                onToggleParticipant: onToggleExpenseParticipant
            )
        }
        .onAppear {
            budgetText = plainAmount(budget.total)
            newExpenseCurrencyCode = budget.currencyCode
            newExpensePayerID = newExpensePayerID ?? trip.participants.first?.id
        }
        .onChange(of: budget.total) { _, newValue in
            budgetText = plainAmount(newValue)
        }
        .onChange(of: budget.currencyCode) { _, newValue in
            newExpenseCurrencyCode = newValue
        }
        .onChange(of: trip.participants) { _, newValue in
            if newExpensePayerID == nil || !newValue.contains(where: { $0.id == newExpensePayerID }) {
                newExpensePayerID = newValue.first?.id
            }
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

    private func format(totalsByCurrency: [String: Decimal]) -> String? {
        guard !totalsByCurrency.isEmpty else {
            return nil
        }
        return totalsByCurrency
            .sorted { lhs, rhs in lhs.key < rhs.key }
            .map { currencyCode, amount in
                format(amount: amount, currencyCode: currencyCode)
            }
            .joined(separator: " / ")
    }
}

#Preview {
    BudgetPlannerView(
        trip: SampleTripFactory.tokyoFiveDayTrip(),
        onUpdateBudget: { _, _ in },
        onAddParticipant: { _ in },
        onUpdateParticipant: { _, _ in },
        onDeleteParticipant: { _ in },
        onAddExpense: { _, _, _, _, _, _ in },
        onUpdateExpense: { _, _, _, _, _, _, _, _, _ in },
        onDeleteExpense: { _ in },
        onToggleExpenseParticipant: { _, _ in }
    )
}
