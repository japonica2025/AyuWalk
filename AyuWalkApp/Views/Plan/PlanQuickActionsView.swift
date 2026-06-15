import AyuWalkCore
import SwiftUI

struct PlanQuickActionsView: View {
    let trip: Trip
    let onOpenBudget: () -> Void
    let onOpenPacking: () -> Void
    let onOpenJournal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            AWSectionHeader(
                title: "出行管理",
                subtitle: "预算、行李和手帐从同一份行程生成",
                accessory: trip.budgetPlan?.currencyCode
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                Button(action: onOpenBudget) {
                    summaryCard(
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
                    summaryCard(
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
                HStack(spacing: 12) {
                    AWIconBadge(systemImage: "book.pages.fill", tint: AyuWalkTheme.accent, size: 42)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("查看电子手帐")
                            .font(AyuWalkTypography.bodyStrong)
                            .foregroundStyle(AyuWalkTheme.ink)
                        Text("已根据当前行程生成每日页面草稿")
                            .font(AyuWalkTypography.caption)
                            .foregroundStyle(AyuWalkTheme.mutedInk)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(AyuWalkTypography.icon(size: 12, weight: .bold))
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                }
                .padding(14)
                .background(AyuWalkTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AyuWalkTheme.hairline, lineWidth: 1)
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

    private func summaryCard(
        title: String,
        value: String,
        detail: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            AWIconBadge(systemImage: systemImage, tint: tint, size: 34)

            Text(title)
                .font(AyuWalkTypography.captionStrong)
                .foregroundStyle(AyuWalkTheme.mutedInk)

            Text(value)
                .font(AyuWalkTypography.sectionTitle)
                .foregroundStyle(AyuWalkTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(detail)
                .font(AyuWalkTypography.micro)
                .foregroundStyle(AyuWalkTheme.mutedInk)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 134, alignment: .topLeading)
        .padding(14)
        .background(AyuWalkTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AyuWalkTheme.hairline, lineWidth: 1)
        }
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
