import AyuWalkCore
import SwiftUI

private let supportedBudgetCurrencyCodes = ["CNY", "JPY", "EUR", "USD", "GBP", "KRW", "HKD", "TWD", "MNT"]

private struct BudgetCurrencyMenu: View {
    let currencyCode: String
    let label: String
    var onSelect: (String) -> Void

    var body: some View {
        Menu {
            ForEach(supportedBudgetCurrencyCodes, id: \.self) { code in
                Button {
                    onSelect(code)
                } label: {
                    if code == currencyCode {
                        Label(code, systemImage: "checkmark")
                    } else {
                        Text(code)
                    }
                }
            }
        } label: {
            HStack(spacing: AyuWalkSpacing.xxs) {
                Text(currencyCode)
                    .font(AyuWalkTypography.bodyStrong)
                Image(systemName: "chevron.down")
                    .font(AyuWalkTypography.microStrong)
            }
            .foregroundStyle(AyuWalkTheme.secondaryAccent)
            .padding(.horizontal, AyuWalkSpacing.sm)
            .frame(height: AyuWalkSize.formControlHeight)
            .awPaperInsetBackground(
                cornerRadius: AyuWalkRadii.card,
                fill: AyuWalkTheme.surface,
                borderTint: AyuWalkTheme.secondaryAccent
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct AWBudgetTotalCard: View {
    let currencyCode: String
    let participants: [Participant]
    @Binding var budgetText: String
    @Binding var newParticipantName: String
    var onCurrencyChange: (String) -> Void
    var onSave: () -> Void
    var onAddParticipant: () -> Void
    var onUpdateParticipant: (UUID, String) -> Void
    var onDeleteParticipant: (UUID) -> Void

    @State private var isManagingParticipants = false
    @FocusState private var isBudgetFieldFocused: Bool

    var body: some View {
        AWCardChrome(cornerRadius: AyuWalkRadii.panel) {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.md) {
                HStack {
                    Text("总预算")
                        .font(AyuWalkTypography.eyebrow)
                        .foregroundStyle(AyuWalkTheme.accent)

                    Spacer()

                    Button {
                        withAnimation(AyuWalkMotion.quick) {
                            isManagingParticipants.toggle()
                        }
                    } label: {
                        Label(
                            "\(participants.count) 位参与人",
                            systemImage: isManagingParticipants ? "chevron.up" : "person.badge.plus"
                        )
                        .font(AyuWalkTypography.captionStrong)
                        .foregroundStyle(AyuWalkTheme.secondaryAccent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("管理参与人")
                }

                HStack(alignment: .firstTextBaseline, spacing: AyuWalkSpacing.sm) {
                    BudgetCurrencyMenu(
                        currencyCode: currencyCode,
                        label: "总预算货币",
                        onSelect: onCurrencyChange
                    )

                    TextField("填写总预算", text: $budgetText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(AyuWalkTheme.ink)
                        .textFieldStyle(.plain)
                        .focused($isBudgetFieldFocused)
                        .padding(.horizontal, AyuWalkSpacing.sm)
                        .frame(maxWidth: .infinity, minHeight: AyuWalkSize.formControlHeight)
                        .awPaperInsetBackground(
                            cornerRadius: AyuWalkRadii.card,
                            fill: AyuWalkTheme.surface,
                            borderTint: AyuWalkTheme.secondaryAccent
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isBudgetFieldFocused = true
                        }
                        .accessibilityLabel("总预算")
                }
                .padding(.vertical, AyuWalkSpacing.xxs - 1)

                Button(action: onSave) {
                    Label("保存预算", systemImage: "checkmark.circle.fill")
                        .font(AyuWalkTypography.metric)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AyuWalkSpacing.md)
                        .background(AyuWalkTheme.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Text("先用总预算撑起 AA 估算，后续再拆交通、酒店、餐饮和购物。")
                    .font(AyuWalkTypography.body)
                    .foregroundStyle(AyuWalkTheme.mutedInk)

                if isManagingParticipants {
                    Divider()
                        .overlay(AyuWalkTheme.border)

                    participantEditor
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var participantEditor: some View {
        VStack(alignment: .leading, spacing: AyuWalkSpacing.sm) {
            HStack(spacing: AyuWalkSpacing.sm) {
                AWTextField(placeholder: "添加参与人", text: $newParticipantName)

                Button(action: onAddParticipant) {
                    Image(systemName: "plus")
                        .font(AyuWalkTypography.icon(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: AyuWalkSize.largeIconButton, height: AyuWalkSize.largeIconButton)
                        .background(AyuWalkTheme.secondaryAccent)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("添加参与人")
            }

            if participants.isEmpty {
                Text("添加参与人后，新支出会默认让所有人一起 AA。")
                    .font(AyuWalkTypography.caption)
                    .foregroundStyle(AyuWalkTheme.mutedInk)
            } else {
                ForEach(participants) { participant in
                    AWParticipantEditorRow(
                        participant: participant,
                        perPersonText: nil,
                        onUpdate: onUpdateParticipant,
                        onDelete: onDeleteParticipant
                    )
                }
            }
        }
    }
}

struct AWBudgetSplitCard: View {
    let perPersonText: String
    let participantCount: Int
    let recordedTotalText: String?

    var body: some View {
        AWCardChrome(cornerRadius: AyuWalkRadii.panel) {
            HStack(spacing: AyuWalkSpacing.lg - 2) {
                AWIconBadge(systemImage: "person.2.fill", tint: AyuWalkTheme.secondaryAccent, size: AyuWalkSize.largeIconButton)

                VStack(alignment: .leading, spacing: AyuWalkSpacing.xxs - 1) {
                    Text("AA 人均")
                        .font(AyuWalkTypography.eyebrow)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                    Text(perPersonText)
                        .font(AyuWalkTypography.pageTitle)
                        .foregroundStyle(AyuWalkTheme.ink)
                    Text("\(max(participantCount, 0)) 人参与计算")
                        .font(AyuWalkTypography.caption)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                    if let recordedTotalText {
                        Text("已记账 \(recordedTotalText)")
                            .font(AyuWalkTypography.captionStrong)
                            .foregroundStyle(AyuWalkTheme.accent)
                    }
                }

                Spacer()
            }
        }
    }
}

struct AWBudgetExchangeRateCard: View {
    let convertedTotal: BudgetConvertedTotal
    let totalBudget: Decimal
    let defaultCurrencyCode: String
    let exchangeRates: [String: Decimal]
    let expenseCurrencyCodes: [String]
    var onUpdateRate: (String, Decimal) -> Void

    @State private var rateTexts: [String: String] = [:]

    private var normalizedDefaultCurrencyCode: String {
        defaultCurrencyCode.isEmpty ? "CNY" : defaultCurrencyCode.uppercased()
    }

    private var foreignCurrencyCodes: [String] {
        Array(
            Set(
                expenseCurrencyCodes
                    .map { normalizedCurrencyCode($0) }
                    .filter { $0 != normalizedDefaultCurrencyCode }
            )
        )
        .sorted()
    }

    var body: some View {
        AWCardChrome(cornerRadius: AyuWalkRadii.panel) {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.md) {
                HStack {
                    Text("汇率折算")
                        .font(AyuWalkTypography.sectionTitle)
                        .foregroundStyle(AyuWalkTheme.ink)

                    Spacer()

                    Text("手动")
                        .font(AyuWalkTypography.microStrong)
                        .foregroundStyle(AyuWalkTheme.secondaryAccent)
                }

                VStack(alignment: .leading, spacing: AyuWalkSpacing.xs) {
                    Text("折算已记录 \(convertedTotal.currencyCode) \(plainAmount(convertedTotal.amount)) / 总预算 \(normalizedDefaultCurrencyCode) \(plainAmount(totalBudget))")
                        .font(AyuWalkTypography.captionStrong)
                        .foregroundStyle(AyuWalkTheme.ink)

                    if !convertedTotal.missingCurrencyCodes.isEmpty {
                        Text("缺少 \(convertedTotal.missingCurrencyCodes.joined(separator: "、")) 汇率，暂未计入折算进度。")
                            .font(AyuWalkTypography.caption)
                            .foregroundStyle(AyuWalkTheme.accent)
                    } else {
                        Text("仅用于总预算进度，原始支出和 AA 结算保留原货币。")
                            .font(AyuWalkTypography.caption)
                            .foregroundStyle(AyuWalkTheme.mutedInk)
                    }
                }
                .padding(AyuWalkSpacing.sm)
                .awPaperInsetBackground(
                    cornerRadius: AyuWalkRadii.card,
                    fill: AyuWalkTheme.surface,
                    borderTint: AyuWalkTheme.secondaryAccent,
                    borderOpacity: 0.06
                )

                if foreignCurrencyCodes.isEmpty {
                    Text("当前没有外币支出，暂时不需要设置汇率。")
                        .font(AyuWalkTypography.body)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                } else {
                    ForEach(foreignCurrencyCodes, id: \.self) { currencyCode in
                        exchangeRateRow(currencyCode)

                        if currencyCode != foreignCurrencyCodes.last {
                            Divider()
                                .overlay(AyuWalkTheme.border)
                        }
                    }
                }
            }
        }
        .onAppear {
            syncRateTexts()
        }
        .onChange(of: exchangeRates) { _, _ in
            syncRateTexts()
        }
        .onChange(of: expenseCurrencyCodes) { _, _ in
            syncRateTexts()
        }
    }

    private func exchangeRateRow(_ currencyCode: String) -> some View {
        HStack(spacing: AyuWalkSpacing.sm) {
            Text("1 \(currencyCode) =")
                .font(AyuWalkTypography.captionStrong)
                .foregroundStyle(AyuWalkTheme.ink)

            TextField(
                normalizedDefaultCurrencyCode,
                text: Binding(
                    get: { rateTexts[currencyCode] ?? plainAmount(exchangeRate(for: currencyCode) ?? 0) },
                    set: { rateTexts[currencyCode] = $0 }
                )
            )
            .keyboardType(.decimalPad)
            .textFieldStyle(.plain)
            .font(AyuWalkTypography.bodyStrong)
            .foregroundStyle(AyuWalkTheme.ink)
            .padding(.horizontal, AyuWalkSpacing.sm)
            .frame(height: AyuWalkSize.formControlHeight)
            .awPaperInsetBackground(
                cornerRadius: AyuWalkRadii.card,
                fill: AyuWalkTheme.surface,
                borderTint: AyuWalkTheme.secondaryAccent
            )
            .accessibilityLabel("\(currencyCode) 汇率")

            Text(normalizedDefaultCurrencyCode)
                .font(AyuWalkTypography.captionStrong)
                .foregroundStyle(AyuWalkTheme.mutedInk)

            Button {
                let rate = decimal(from: rateTexts[currencyCode] ?? "") ?? 0
                onUpdateRate(currencyCode, rate)
            } label: {
                Image(systemName: "checkmark")
                    .font(AyuWalkTypography.icon(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: AyuWalkSize.iconButton, height: AyuWalkSize.iconButton)
                    .background(AyuWalkTheme.secondaryAccent)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("保存 \(currencyCode) 汇率")
        }
    }

    private func syncRateTexts() {
        for currencyCode in foreignCurrencyCodes {
            rateTexts[currencyCode] = plainAmount(exchangeRate(for: currencyCode) ?? 0)
        }
    }

    private func exchangeRate(for currencyCode: String) -> Decimal? {
        exchangeRates[currencyCode] ?? exchangeRates.first { item in
            normalizedCurrencyCode(item.key) == currencyCode
        }?.value
    }

    private func normalizedCurrencyCode(_ currencyCode: String) -> String {
        let trimmed = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "CNY" : trimmed.uppercased()
    }

    private func decimal(from text: String) -> Decimal? {
        Decimal(string: text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ""))
    }

    private func plainAmount(_ amount: Decimal) -> String {
        let number = NSDecimalNumber(decimal: amount)
        if amount == Decimal(number.intValue) {
            return "\(number.intValue)"
        }
        return number.stringValue
    }
}

struct AWBudgetCategoryProgressCard: View {
    let progress: [BudgetCategoryProgress]
    let defaultCurrencyCode: String
    var onUpdateBudget: (BudgetCategory, Decimal) -> Void

    @State private var budgetTexts: [BudgetCategory: String] = [:]

    private var normalizedDefaultCurrencyCode: String {
        defaultCurrencyCode.isEmpty ? "CNY" : defaultCurrencyCode
    }

    var body: some View {
        AWCardChrome(cornerRadius: AyuWalkRadii.panel) {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.md) {
                HStack {
                    Text("分类预算")
                        .font(AyuWalkTypography.sectionTitle)
                        .foregroundStyle(AyuWalkTheme.ink)

                    Spacer()

                    Text("0 表示不设上限")
                        .font(AyuWalkTypography.microStrong)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                }

                ForEach(BudgetCategory.allCases, id: \.self) { category in
                    categoryRow(category)

                    if category != BudgetCategory.allCases.last {
                        Divider()
                            .overlay(AyuWalkTheme.border)
                    }
                }
            }
        }
        .onAppear {
            syncBudgetTexts()
        }
        .onChange(of: progress) { _, _ in
            syncBudgetTexts()
        }
    }

    private func categoryRow(_ category: BudgetCategory) -> some View {
        let item = primaryProgress(for: category)
        let otherCurrencyProgress = additionalProgress(for: category)

        return VStack(alignment: .leading, spacing: AyuWalkSpacing.xs) {
            HStack(spacing: AyuWalkSpacing.sm) {
                Text(category.displayName)
                    .font(AyuWalkTypography.captionStrong)
                    .foregroundStyle(AyuWalkTheme.ink)

                Spacer()

                Text("\(item.currencyCode) 已用 \(plainAmount(item.spent))")
                    .font(AyuWalkTypography.microStrong)
                    .foregroundStyle(item.spent > item.budgeted && item.budgeted > 0 ? AyuWalkTheme.accent : AyuWalkTheme.mutedInk)
            }

            HStack(spacing: AyuWalkSpacing.sm) {
                TextField(
                    "预算",
                    text: Binding(
                        get: { budgetTexts[category] ?? plainAmount(item.budgeted) },
                        set: { budgetTexts[category] = $0 }
                    )
                )
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                .font(AyuWalkTypography.bodyStrong)
                .foregroundStyle(AyuWalkTheme.ink)
                .padding(.horizontal, AyuWalkSpacing.sm)
                .frame(height: AyuWalkSize.formControlHeight)
                .awPaperInsetBackground(
                    cornerRadius: AyuWalkRadii.card,
                    fill: AyuWalkTheme.surface,
                    borderTint: AyuWalkTheme.secondaryAccent
                )
                .accessibilityLabel("\(category.displayName)分类预算")

                Button {
                    let amount = decimal(from: budgetTexts[category] ?? "") ?? 0
                    onUpdateBudget(category, amount)
                } label: {
                    Image(systemName: "checkmark")
                        .font(AyuWalkTypography.icon(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: AyuWalkSize.iconButton, height: AyuWalkSize.iconButton)
                        .background(AyuWalkTheme.secondaryAccent)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("保存\(category.displayName)分类预算")
            }

            ProgressView(value: progressValue(for: item))
                .tint(item.spent > item.budgeted && item.budgeted > 0 ? AyuWalkTheme.accent : AyuWalkTheme.secondaryAccent)

            Text(statusText(for: item))
                .font(AyuWalkTypography.micro)
                .foregroundStyle(AyuWalkTheme.mutedInk)

            ForEach(otherCurrencyProgress, id: \.currencyCode) { extraItem in
                Text("\(extraItem.currencyCode) 另有支出 \(plainAmount(extraItem.spent))")
                    .font(AyuWalkTypography.micro)
                    .foregroundStyle(AyuWalkTheme.mutedInk)
            }
        }
    }

    private func primaryProgress(for category: BudgetCategory) -> BudgetCategoryProgress {
        progress.first { item in
            item.category == category && item.currencyCode == normalizedDefaultCurrencyCode
        } ?? BudgetCategoryProgress(
            category: category,
            budgeted: 0,
            spent: 0,
            currencyCode: normalizedDefaultCurrencyCode
        )
    }

    private func additionalProgress(for category: BudgetCategory) -> [BudgetCategoryProgress] {
        progress.filter { item in
            item.category == category && item.currencyCode != normalizedDefaultCurrencyCode
        }
    }

    private func statusText(for item: BudgetCategoryProgress) -> String {
        guard item.budgeted > 0 else {
            return "未设置预算上限"
        }
        if item.remaining >= 0 {
            return "剩余 \(item.currencyCode) \(plainAmount(item.remaining))"
        }
        return "超出 \(item.currencyCode) \(plainAmount(-item.remaining))"
    }

    private func progressValue(for item: BudgetCategoryProgress) -> Double {
        guard let ratio = item.usageRatio else {
            return 0
        }
        return min(max(NSDecimalNumber(decimal: ratio).doubleValue, 0), 1)
    }

    private func syncBudgetTexts() {
        for category in BudgetCategory.allCases {
            budgetTexts[category] = plainAmount(primaryProgress(for: category).budgeted)
        }
    }

    private func decimal(from text: String) -> Decimal? {
        Decimal(string: text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ""))
    }

    private func plainAmount(_ amount: Decimal) -> String {
        let number = NSDecimalNumber(decimal: amount)
        if amount == Decimal(number.intValue) {
            return "\(number.intValue)"
        }
        return number.stringValue
    }
}

struct AWBudgetExpenseEntryCard: View {
    @Binding var title: String
    @Binding var amountText: String
    @Binding var category: BudgetCategory
    @Binding var currencyCode: String
    @Binding var payerID: UUID?
    @Binding var notes: String
    let participants: [Participant]
    var defaultCurrencyCode: String
    var onAdd: () -> Void

    var body: some View {
        let effectiveCurrencyCode = currencyCode.isEmpty ? defaultCurrencyCode : currencyCode
        AWCardChrome(cornerRadius: AyuWalkRadii.panel) {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.md) {
                Text("记录一笔")
                    .font(AyuWalkTypography.sectionTitle)
                    .foregroundStyle(AyuWalkTheme.ink)

                AWTextField(placeholder: "支出名称", text: $title)

                HStack(spacing: AyuWalkSpacing.sm) {
                    BudgetCurrencyMenu(
                        currencyCode: effectiveCurrencyCode,
                        label: "支出货币"
                    ) { selected in
                        currencyCode = selected
                    }

                    TextField("金额", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(AyuWalkTypography.bodyStrong)
                        .foregroundStyle(AyuWalkTheme.ink)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, AyuWalkSpacing.md)
                        .frame(height: AyuWalkSize.formControlHeight)
                        .awPaperInsetBackground(
                            cornerRadius: AyuWalkRadii.card,
                            fill: AyuWalkTheme.surface,
                            borderTint: AyuWalkTheme.secondaryAccent
                        )
                }

                payerPicker

                Picker("分类", selection: $category) {
                    ForEach(BudgetCategory.allCases, id: \.self) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(.segmented)

                AWTextField(placeholder: "备注，可不填", text: $notes, font: AyuWalkTypography.body)

                Button(action: onAdd) {
                    Label("添加支出", systemImage: "plus.circle.fill")
                        .font(AyuWalkTypography.metric)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AyuWalkSpacing.md)
                        .background(AyuWalkTheme.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var payerPicker: some View {
        HStack {
            Text("付款人")
                .font(AyuWalkTypography.captionStrong)
                .foregroundStyle(AyuWalkTheme.mutedInk)
            Spacer()
            Menu {
                ForEach(participants) { participant in
                    Button(participant.name) {
                        payerID = participant.id
                    }
                }
            } label: {
                Text(payerName)
                    .font(AyuWalkTypography.captionStrong)
                    .foregroundStyle(AyuWalkTheme.secondaryAccent)
                    .padding(.horizontal, AyuWalkSpacing.sm)
                    .padding(.vertical, AyuWalkSpacing.xs)
                    .awPaperCapsuleBackground(
                        fill: AyuWalkTheme.surface,
                        borderTint: AyuWalkTheme.secondaryAccent,
                        borderOpacity: 0.12
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("选择付款人")
        }
    }

    private var payerName: String {
        guard let payerID,
              let participant = participants.first(where: { $0.id == payerID }) else {
            return participants.first?.name ?? "未设置"
        }
        return participant.name
    }
}

struct AWBudgetExpenseListCard: View {
    let expenses: [BudgetExpense]
    let participants: [Participant]
    let currencyCode: String
    let participantTotals: [UUID: Decimal]
    let participantTotalsByCurrency: [UUID: [String: Decimal]]
    let settlementTransfers: [BudgetSettlementTransfer]
    var onUpdate: (UUID, String, Decimal, BudgetCategory, String, UUID?, BudgetSplitMode, [UUID: Decimal], String?) -> Void
    var onDelete: (UUID) -> Void
    var onToggleParticipant: (UUID, UUID) -> Void

    var body: some View {
        AWCardChrome(cornerRadius: AyuWalkRadii.panel) {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.md) {
                Text("支出明细")
                    .font(AyuWalkTypography.sectionTitle)
                    .foregroundStyle(AyuWalkTheme.ink)

                participantTotalsView
                settlementView

                if expenses.isEmpty {
                    Text("还没有记录支出。新增一笔后，会默认让所有参与人一起 AA。")
                        .font(AyuWalkTypography.body)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                        .padding(.vertical, AyuWalkSpacing.xs)
                } else {
                    ForEach(expenses) { expense in
                        AWBudgetExpenseRow(
                            expense: expense,
                            participants: participants,
                            currencyCode: currencyCode,
                            onUpdate: onUpdate,
                            onDelete: onDelete,
                            onToggleParticipant: onToggleParticipant
                        )

                        if expense.id != expenses.last?.id {
                            Divider()
                                .overlay(AyuWalkTheme.border)
                        }
                    }
                }
            }
        }
    }

    private var participantTotalsView: some View {
        VStack(alignment: .leading, spacing: AyuWalkSpacing.xs) {
            Text("个人汇总")
                .font(AyuWalkTypography.eyebrow)
                .foregroundStyle(AyuWalkTheme.mutedInk)

            if participants.isEmpty {
                Text("添加参与人后会显示每个人应承担的金额。")
                    .font(AyuWalkTypography.caption)
                    .foregroundStyle(AyuWalkTheme.mutedInk)
            } else {
                ForEach(participants) { participant in
                    HStack {
                        Text(participant.name)
                            .font(AyuWalkTypography.captionStrong)
                            .foregroundStyle(AyuWalkTheme.ink)
                        Spacer()
                        Text(participantTotalText(for: participant))
                            .font(AyuWalkTypography.captionStrong)
                            .foregroundStyle(AyuWalkTheme.secondaryAccent)
                    }
                }
            }
        }
        .padding(AyuWalkSpacing.sm)
        .awPaperInsetBackground(
            cornerRadius: AyuWalkRadii.card,
            fill: AyuWalkTheme.surface,
            borderTint: AyuWalkTheme.secondaryAccent,
            borderOpacity: 0.08
        )
    }

    private func format(amount: Decimal, currencyCode: String) -> String {
        let number = NSDecimalNumber(decimal: amount).doubleValue
        let formatted = number.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(number))
            : String(format: "%.2f", number)
        return "\(currencyCode) \(formatted)"
    }

    private func participantTotalText(for participant: Participant) -> String {
        let groupedTotals = participantTotalsByCurrency[participant.id] ?? [:]
        if groupedTotals.isEmpty {
            return format(amount: participantTotals[participant.id] ?? 0, currencyCode: currencyCode)
        }
        return groupedTotals
            .sorted { $0.key < $1.key }
            .map { format(amount: $0.value, currencyCode: $0.key) }
            .joined(separator: " / ")
    }

    private var settlementView: some View {
        VStack(alignment: .leading, spacing: AyuWalkSpacing.xs) {
            Text("结算摘要")
                .font(AyuWalkTypography.eyebrow)
                .foregroundStyle(AyuWalkTheme.mutedInk)

            if settlementTransfers.isEmpty {
                Text("当前没有需要转账的金额。")
                    .font(AyuWalkTypography.caption)
                    .foregroundStyle(AyuWalkTheme.mutedInk)
            } else {
                ForEach(Array(settlementTransfers.enumerated()), id: \.offset) { _, transfer in
                    Text(settlementText(for: transfer))
                        .font(AyuWalkTypography.captionStrong)
                        .foregroundStyle(AyuWalkTheme.ink)
                }
            }
        }
        .padding(AyuWalkSpacing.sm)
        .awPaperInsetBackground(
            cornerRadius: AyuWalkRadii.card,
            fill: AyuWalkTheme.surface,
            borderTint: AyuWalkTheme.accent,
            borderOpacity: 0.08
        )
    }

    private func settlementText(for transfer: BudgetSettlementTransfer) -> String {
        let fromName = participants.first(where: { $0.id == transfer.fromParticipantID })?.name ?? "某人"
        let toName = participants.first(where: { $0.id == transfer.toParticipantID })?.name ?? "某人"
        return "\(fromName) 转给 \(toName) \(format(amount: transfer.amount, currencyCode: transfer.currencyCode))"
    }
}

private struct AWBudgetExpenseRow: View {
    let expense: BudgetExpense
    let participants: [Participant]
    let currencyCode: String
    var onUpdate: (UUID, String, Decimal, BudgetCategory, String, UUID?, BudgetSplitMode, [UUID: Decimal], String?) -> Void
    var onDelete: (UUID) -> Void
    var onToggleParticipant: (UUID, UUID) -> Void

    @State private var isEditing = false

    private var shareText: String {
        guard !expense.participantIDs.isEmpty else {
            return "未选择 AA 人员"
        }

        if expense.splitMode == .custom {
            let total = expense.participantIDs.reduce(Decimal(0)) { partialResult, participantID in
                partialResult + (expense.customShares[participantID] ?? 0)
            }
            return "\(expense.participantIDs.count) 人自定义分摊 · \(expenseCurrencyCode) \(plainAmount(total))"
        }

        let amount = expense.amount / Decimal(expense.participantIDs.count)
        return "\(expense.participantIDs.count) 人 AA · \(expenseCurrencyCode) \(plainAmount(amount)) / 人"
    }

    private var expenseCurrencyCode: String {
        expense.currencyCode.isEmpty ? currencyCode : expense.currencyCode
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AyuWalkSpacing.sm) {
            summaryRow

            if isEditing {
                editingFields
                    .transition(.opacity.combined(with: .move(edge: .top)))

                Text("参与这笔 AA")
                    .font(AyuWalkTypography.eyebrow)
                    .foregroundStyle(AyuWalkTheme.mutedInk)

                if participants.isEmpty {
                    Text("当前没有参与人，请先在总预算中添加。")
                        .font(AyuWalkTypography.caption)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                } else {
                    participantChips
                }
            }
        }
        .padding(.vertical, AyuWalkSpacing.xs)
        .animation(AyuWalkMotion.quick, value: isEditing)
    }

    private var summaryRow: some View {
        HStack(alignment: .top, spacing: AyuWalkSpacing.sm) {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.xs) {
                Text(expense.title)
                    .font(AyuWalkTypography.bodyStrong)
                    .foregroundStyle(AyuWalkTheme.ink)

                HStack {
                    Text(expense.category.displayName)
                        .font(AyuWalkTypography.captionStrong)
                        .foregroundStyle(AyuWalkTheme.accent)
                    Text(shareText)
                        .font(AyuWalkTypography.caption)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                }
                if let payerName {
                    Text("付款人 \(payerName)")
                        .font(AyuWalkTypography.caption)
                        .foregroundStyle(AyuWalkTheme.secondaryAccent)
                }
            }

            Spacer()

            Text("\(expenseCurrencyCode) \(plainAmount(expense.amount))")
                .font(AyuWalkTypography.bodyStrong)
                .foregroundStyle(AyuWalkTheme.ink)

            Button {
                isEditing.toggle()
            } label: {
                Image(systemName: isEditing ? "checkmark" : "pencil")
                    .font(AyuWalkTypography.icon(size: 15, weight: .bold))
                    .foregroundStyle(AyuWalkTheme.secondaryAccent)
                    .frame(width: AyuWalkSize.compactIconButton, height: AyuWalkSize.compactIconButton)
                    .background {
                        Circle()
                            .fill(AyuWalkTheme.surface)

                        Image.awPaperCardSurface
                            .resizable()
                            .scaledToFill()
                            .opacity(AyuWalkTexture.cardOpacity)
                            .blendMode(.multiply)
                            .clipShape(Circle())
                    }
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(AyuWalkTheme.secondaryAccent.opacity(0.12), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isEditing ? "完成编辑支出" : "编辑支出")

            Button {
                onDelete(expense.id)
            } label: {
                Image(systemName: "trash")
                    .font(AyuWalkTypography.icon(size: 15, weight: .bold))
                    .foregroundStyle(AyuWalkTheme.accent)
                    .frame(width: AyuWalkSize.compactIconButton, height: AyuWalkSize.compactIconButton)
                    .background {
                        Circle()
                            .fill(AyuWalkTheme.surface)

                        Image.awPaperCardSurface
                            .resizable()
                            .scaledToFill()
                            .opacity(AyuWalkTexture.cardOpacity)
                            .blendMode(.multiply)
                            .clipShape(Circle())
                    }
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(AyuWalkTheme.accent.opacity(0.12), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("删除支出")
        }
    }

    private var editingFields: some View {
        VStack(alignment: .leading, spacing: AyuWalkSpacing.sm) {
            AWTextField(
                placeholder: "支出名称",
                text: Binding(
                    get: { expense.title },
                    set: { update(title: $0) }
                )
            )

            AWTextField(
                placeholder: "金额",
                text: Binding(
                    get: { plainAmount(expense.amount) },
                    set: { text in
                        if let amount = decimal(from: text) {
                            update(amount: amount)
                        }
                    }
                ),
                keyboardType: .decimalPad
            )

            BudgetCurrencyMenu(
                currencyCode: expenseCurrencyCode,
                label: "支出货币"
            ) { selected in
                update(currencyCode: selected)
            }

            payerPicker

            Picker(
                "分摊方式",
                selection: Binding(
                    get: { expense.splitMode },
                    set: { update(splitMode: $0) }
                )
            ) {
                Text("均分").tag(BudgetSplitMode.equal)
                Text("自定义").tag(BudgetSplitMode.custom)
            }
            .pickerStyle(.segmented)

            Picker(
                "分类",
                selection: Binding(
                    get: { expense.category },
                    set: { update(category: $0) }
                )
            ) {
                ForEach(BudgetCategory.allCases, id: \.self) { category in
                    Text(category.displayName).tag(category)
                }
            }
            .pickerStyle(.menu)

            TextField(
                "备注",
                text: Binding(
                    get: { expense.notes ?? "" },
                    set: { update(notes: $0) }
                )
            )
            .textFieldStyle(.plain)
            .font(AyuWalkTypography.caption)
            .foregroundStyle(AyuWalkTheme.mutedInk)
        }
    }

    private var payerPicker: some View {
        HStack {
            Text("付款人")
                .font(AyuWalkTypography.captionStrong)
                .foregroundStyle(AyuWalkTheme.mutedInk)
            Spacer()
            Menu {
                ForEach(participants) { participant in
                    Button(participant.name) {
                        update(payerID: participant.id)
                    }
                }
            } label: {
                Text(payerName ?? "未设置")
                    .font(AyuWalkTypography.captionStrong)
                    .foregroundStyle(AyuWalkTheme.secondaryAccent)
                    .padding(.horizontal, AyuWalkSpacing.sm)
                    .padding(.vertical, AyuWalkSpacing.xs)
                    .awPaperCapsuleBackground(
                        fill: AyuWalkTheme.surface,
                        borderTint: AyuWalkTheme.secondaryAccent,
                        borderOpacity: 0.12
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var participantChips: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 94), spacing: AyuWalkSpacing.xs)],
            alignment: .leading,
            spacing: AyuWalkSpacing.xs
        ) {
            ForEach(participants) { participant in
                let isIncluded = expense.participantIDs.contains(participant.id)
                VStack(alignment: .leading, spacing: AyuWalkSpacing.xxs) {
                    Button {
                        onToggleParticipant(expense.id, participant.id)
                    } label: {
                        Label(participant.name, systemImage: isIncluded ? "checkmark.circle.fill" : "minus.circle")
                            .font(AyuWalkTypography.captionStrong)
                            .foregroundStyle(isIncluded ? AyuWalkTheme.secondaryAccent : AyuWalkTheme.mutedInk)
                            .padding(.horizontal, AyuWalkSpacing.sm)
                            .padding(.vertical, AyuWalkSpacing.xs)
                            .awPaperCapsuleBackground(
                                fill: isIncluded ? AyuWalkTheme.secondaryAccent.opacity(0.12) : AyuWalkTheme.surface,
                                borderTint: isIncluded ? AyuWalkTheme.secondaryAccent : AyuWalkTheme.accent,
                                borderOpacity: isIncluded ? 0.18 : 0.08
                            )
                    }
                    .buttonStyle(.plain)

                    if isIncluded, expense.splitMode == .custom {
                        TextField(
                            "金额",
                            text: Binding(
                                get: { plainAmount(expense.customShares[participant.id] ?? 0) },
                                set: { text in
                                    if let amount = decimal(from: text) {
                                        var shares = expense.customShares
                                        shares[participant.id] = amount
                                        update(customShares: shares)
                                    }
                                }
                            )
                        )
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .font(AyuWalkTypography.caption)
                        .foregroundStyle(AyuWalkTheme.ink)
                        .padding(.horizontal, AyuWalkSpacing.sm)
                        .padding(.vertical, AyuWalkSpacing.xs)
                        .awPaperCapsuleBackground(
                            fill: AyuWalkTheme.surface,
                            borderTint: AyuWalkTheme.secondaryAccent,
                            borderOpacity: 0.10
                        )
                    }
                }
            }
        }
    }

    private var payerName: String? {
        guard let payerID = expense.payerID else {
            return nil
        }
        return participants.first(where: { $0.id == payerID })?.name
    }

    private func update(
        title: String? = nil,
        amount: Decimal? = nil,
        category: BudgetCategory? = nil,
        currencyCode: String? = nil,
        payerID: UUID?? = nil,
        splitMode: BudgetSplitMode? = nil,
        customShares: [UUID: Decimal]? = nil,
        notes: String? = nil
    ) {
        let nextSplitMode = splitMode ?? expense.splitMode
        let nextCustomShares: [UUID: Decimal]
        if let customShares {
            nextCustomShares = customShares
        } else if nextSplitMode == .custom, expense.customShares.isEmpty {
            nextCustomShares = defaultCustomShares()
        } else {
            nextCustomShares = expense.customShares
        }

        onUpdate(
            expense.id,
            title ?? expense.title,
            amount ?? expense.amount,
            category ?? expense.category,
            currencyCode ?? expenseCurrencyCode,
            payerID == nil ? expense.payerID : payerID!,
            nextSplitMode,
            nextCustomShares,
            notes ?? expense.notes
        )
    }

    private func defaultCustomShares() -> [UUID: Decimal] {
        guard !expense.participantIDs.isEmpty else {
            return [:]
        }
        let perPersonAmount = expense.amount / Decimal(expense.participantIDs.count)
        return Dictionary(uniqueKeysWithValues: expense.participantIDs.map { ($0, perPersonAmount) })
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
}

private struct AWParticipantEditorRow: View {
    let participant: Participant
    let perPersonText: String?
    var onUpdate: (UUID, String) -> Void
    var onDelete: (UUID) -> Void

    var body: some View {
        HStack(spacing: AyuWalkSpacing.sm) {
            TextField(
                "参与人姓名",
                text: Binding(
                    get: { participant.name },
                    set: { onUpdate(participant.id, $0) }
                )
            )
            .textFieldStyle(.plain)
            .font(AyuWalkTypography.bodyStrong)
            .foregroundStyle(AyuWalkTheme.ink)

            if let perPersonText {
                Text(perPersonText)
                    .font(AyuWalkTypography.captionStrong)
                    .foregroundStyle(AyuWalkTheme.secondaryAccent)
                    .lineLimit(1)
            }

            Button {
                onDelete(participant.id)
            } label: {
                Image(systemName: "trash")
                    .font(AyuWalkTypography.icon(size: 15, weight: .bold))
                    .foregroundStyle(AyuWalkTheme.accent)
                    .frame(width: AyuWalkSize.compactIconButton, height: AyuWalkSize.compactIconButton)
                    .background {
                        Circle()
                            .fill(AyuWalkTheme.surface)

                        Image.awPaperCardSurface
                            .resizable()
                            .scaledToFill()
                            .opacity(AyuWalkTexture.cardOpacity)
                            .blendMode(.multiply)
                            .clipShape(Circle())
                    }
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(AyuWalkTheme.accent.opacity(0.12), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("删除参与人")
        }
        .padding(.vertical, AyuWalkSpacing.xxs + 1)
    }
}
