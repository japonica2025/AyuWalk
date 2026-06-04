import AyuWalkCore
import SwiftUI

struct BudgetPlannerView: View {
    let trip: Trip
    let onAdjustBudget: (Decimal) -> Void

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
        NavigationStack {
            ZStack {
                AyuWalkTheme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        headerCard
                        splitCard
                        adjustmentCard
                        participantCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle("预算规划")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("总预算")
                .font(.caption.weight(.bold))
                .foregroundStyle(AyuWalkTheme.accent)

            Text(format(amount: budget.total, currencyCode: budget.currencyCode))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(AyuWalkTheme.ink)

            Text("先用总预算撑起 AA 估算，后续再拆交通、酒店、餐饮和购物。")
                .font(.callout)
                .foregroundStyle(AyuWalkTheme.mutedInk)
        }
        .card()
    }

    private var splitCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(AyuWalkTheme.secondaryAccent)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("AA 人均")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AyuWalkTheme.mutedInk)
                Text(format(amount: split.perPerson, currencyCode: split.currencyCode))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AyuWalkTheme.ink)
                Text("\(max(trip.participants.count, 0)) 人参与计算")
                    .font(.caption)
                    .foregroundStyle(AyuWalkTheme.mutedInk)
            }

            Spacer()
        }
        .card()
    }

    private var adjustmentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速调整")
                .font(.headline.weight(.bold))
                .foregroundStyle(AyuWalkTheme.ink)

            HStack(spacing: 10) {
                budgetButton("-500") {
                    onAdjustBudget(-500)
                }
                budgetButton("+500") {
                    onAdjustBudget(500)
                }
                budgetButton("+1000") {
                    onAdjustBudget(1000)
                }
            }
        }
        .card()
    }

    private var participantCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("参与人")
                .font(.headline.weight(.bold))
                .foregroundStyle(AyuWalkTheme.ink)

            ForEach(trip.participants) { participant in
                HStack {
                    Text(participant.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AyuWalkTheme.ink)
                    Spacer()
                    Text(format(amount: split.perPerson, currencyCode: split.currencyCode))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AyuWalkTheme.secondaryAccent)
                }
                .padding(.vertical, 6)
            }
        }
        .card()
    }

    private func budgetButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(title.hasPrefix("+") ? .white : AyuWalkTheme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(title.hasPrefix("+") ? AyuWalkTheme.accent : AyuWalkTheme.paper)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(AyuWalkTheme.border, lineWidth: 1)
                }
        }
    }

    private func format(amount: Decimal, currencyCode: String) -> String {
        let number = NSDecimalNumber(decimal: amount).intValue
        return "\(currencyCode) \(number)"
    }
}

private extension View {
    func card() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AyuWalkTheme.paper)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AyuWalkTheme.border, lineWidth: 1)
            }
    }
}

#Preview {
    BudgetPlannerView(trip: SampleTripFactory.tokyoFiveDayTrip()) { _ in }
}
