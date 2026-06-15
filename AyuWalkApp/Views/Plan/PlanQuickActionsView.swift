import AyuWalkCore
import SwiftUI

struct PlanQuickActionsView: View {
    let trip: Trip
    let onOpenBudget: () -> Void
    let onOpenPacking: () -> Void
    let onOpenJournal: () -> Void

    var body: some View {
        AWPaperSection(
            title: "出行管理",
            subtitle: "预算、行李和手帐从同一份行程生成",
            accessory: trip.budgetPlan?.currencyCode
        ) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                Button(action: onOpenBudget) {
                    AWQuickActionCard(
                        title: "预算规划",
                        value: budgetText,
                        detail: budgetDetail,
                        systemImage: "creditcard.fill",
                        tint: AyuWalkTheme.accent
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("预算规划")

                Button(action: onOpenPacking) {
                    AWQuickActionCard(
                        title: "行李清单",
                        value: "\(trip.packingList?.items.count ?? 0) 件",
                        detail: packingDetail,
                        systemImage: "suitcase.fill",
                        tint: AyuWalkTheme.secondaryAccent
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("行李清单")
            }

            Button(action: onOpenJournal) {
                AWPaperSurface(
                    background: AyuWalkTheme.surface,
                    tint: AyuWalkTheme.accent,
                    cornerRadius: AyuWalkRadii.card,
                    padding: AyuWalkSpacing.md + 2,
                    borderOpacity: 0.10,
                    shadowRadius: 8,
                    shadowY: 4
                ) {
                    AWInlineActionRow(
                        title: "查看电子手帐",
                        subtitle: "已根据当前行程生成每日页面草稿",
                        systemImage: "book.pages.fill",
                        tint: AyuWalkTheme.accent
                    )
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("查看电子手帐")
        }
    }

    private var budgetText: String {
        guard let budget = trip.budgetPlan else {
            return "待规划"
        }

        let amount = NSDecimalNumber(decimal: budget.total).intValue
        return "\(budget.currencyCode) \(amount)"
    }

    private var budgetDetail: String {
        guard let budget = trip.budgetPlan else {
            return "点此建立预算"
        }

        let split = BudgetSplitCalculator.split(
            budget: budget,
            participantCount: trip.participants.count
        )
        let amount = NSDecimalNumber(decimal: split.perPerson).intValue
        return "AA 人均 \(split.currencyCode) \(amount)"
    }

    private var packingDetail: String {
        guard let items = trip.packingList?.items, !items.isEmpty else {
            return "先生成基础清单"
        }

        let packedCount = items.filter(\.isPacked).count
        return "\(packedCount)/\(items.count) 已完成"
    }
}

#Preview {
    PlanQuickActionsView(
        trip: SampleTripFactory.tokyoFiveDayTrip(),
        onOpenBudget: {},
        onOpenPacking: {},
        onOpenJournal: {}
    )
        .padding()
        .background(AyuWalkTheme.pageBackground)
}
