import AyuWalkCore
import SwiftUI

struct BudgetPlannerView: View {
    let trip: Trip
    let onUpdateBudget: (Decimal) -> Void
    let onAddParticipant: (String) -> Void
    let onUpdateParticipant: (UUID, String) -> Void
    let onDeleteParticipant: (UUID) -> Void

    @State private var budgetText = ""
    @State private var newParticipantName = ""

    private var budget: BudgetPlan {
        trip.budgetPlan ?? BudgetPlan(total: 0, currencyCode: "CNY")
    }

    private var split: BudgetSplit {
        BudgetSplitCalculator.split(
            budget: budget,
            participantCount: trip.participants.count
        )
    }

    var body: some View {
        AWSheetScaffold(title: "预算规划") {
            AWBudgetTotalCard(
                currencyCode: budget.currencyCode,
                budgetText: $budgetText
            ) {
                guard let amount = decimal(from: budgetText) else {
                    budgetText = plainAmount(budget.total)
                    return
                }
                onUpdateBudget(amount)
            }

            AWBudgetSplitCard(
                perPersonText: format(amount: split.perPerson, currencyCode: split.currencyCode),
                participantCount: trip.participants.count
            )

            AWParticipantEditorCard(
                participants: trip.participants,
                perPersonText: format(amount: split.perPerson, currencyCode: split.currencyCode),
                newParticipantName: $newParticipantName,
                onAdd: {
                    onAddParticipant(newParticipantName)
                    newParticipantName = ""
                },
                onUpdate: onUpdateParticipant,
                onDelete: onDeleteParticipant
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
        onDeleteParticipant: { _ in }
    )
}
