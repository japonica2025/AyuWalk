import AyuWalkCore
import SwiftUI

struct AWPackingProgressCard: View {
    let packedCount: Int
    let itemCount: Int
    var onOpenTemplates: () -> Void

    var body: some View {
        AWCardChrome(cornerRadius: AyuWalkRadii.panel) {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.md) {
                HStack {
                    Text("打包进度")
                        .font(AyuWalkTypography.eyebrow)
                        .foregroundStyle(AyuWalkTheme.secondaryAccent)

                    Spacer()

                    Button(action: onOpenTemplates) {
                        Label("模板清单", systemImage: "square.grid.2x2")
                            .font(AyuWalkTypography.captionStrong)
                            .foregroundStyle(AyuWalkTheme.accent)
                    }
                    .buttonStyle(.plain)
                }

                Text("\(packedCount)/\(itemCount) 已完成")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AyuWalkTheme.ink)

                ProgressView(value: itemCount == 0 ? 0 : Double(packedCount), total: Double(max(itemCount, 1)))
                    .tint(AyuWalkTheme.secondaryAccent)

                Text("可以应用场景模板补充物品，也可以继续手动添加和编辑。")
                    .font(AyuWalkTypography.body)
                    .foregroundStyle(AyuWalkTheme.mutedInk)
            }
        }
    }
}

struct AWPackingTemplatePicker: View {
    let templates: [PackingTemplate]
    let recommendations: [PackingTemplateRecommendation]
    @Binding var selectedTemplateIDs: Set<PackingTemplateID>
    var onAddSelected: () -> Void

    private var recommendationByTemplateID: [PackingTemplateID: PackingTemplateRecommendation] {
        Dictionary(uniqueKeysWithValues: recommendations.map { ($0.template.id, $0) })
    }

    var body: some View {
        AWSheetScaffold(title: "模板清单") {
            Text(templateIntroText)
                .font(AyuWalkTypography.body)
                .foregroundStyle(AyuWalkTheme.mutedInk)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AyuWalkSpacing.sm) {
                ForEach(templates) { template in
                    Button {
                        if selectedTemplateIDs.contains(template.id) {
                            selectedTemplateIDs.remove(template.id)
                        } else {
                            selectedTemplateIDs.insert(template.id)
                        }
                    } label: {
                        AWPackingTemplateTile(
                            template: template,
                            recommendation: recommendationByTemplateID[template.id],
                            isSelected: selectedTemplateIDs.contains(template.id)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(selectedTemplateIDs.contains(template.id) ? "取消选择" : "选择")\(template.title)模板")
                }
            }

            Button(action: onAddSelected) {
                Label("添加所选模板", systemImage: "plus.circle.fill")
                    .font(AyuWalkTypography.metric)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AyuWalkSpacing.md)
                    .background(selectedTemplateIDs.isEmpty ? AyuWalkTheme.mutedInk : AyuWalkTheme.secondaryAccent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(selectedTemplateIDs.isEmpty)
        }
    }

    private var templateIntroText: String {
        recommendations.isEmpty
            ? "选择本次需要补充的模板，添加后已有物品不会重复。"
            : "已根据目的地、天数和行程内容预选推荐模板，添加后已有物品不会重复。"
    }
}

struct AWPackingReminderCard: View {
    let reminder: PackingReminder?
    let suggestedReminder: PackingReminder?
    var onUpdateReminder: (PackingReminder?) -> Void

    private var displayReminder: PackingReminder? {
        reminder ?? suggestedReminder
    }

    var body: some View {
        AWCardChrome(cornerRadius: AyuWalkRadii.panel) {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.md) {
                HStack(alignment: .top, spacing: AyuWalkSpacing.md) {
                    AWIconBadge(
                        systemImage: "bell.badge",
                        tint: reminder?.isEnabled == true ? AyuWalkTheme.secondaryAccent : AyuWalkTheme.accent,
                        size: AyuWalkSize.largeIconButton
                    )

                    VStack(alignment: .leading, spacing: AyuWalkSpacing.xxs) {
                        Text("打包提醒")
                            .font(AyuWalkTypography.sectionTitle)
                            .foregroundStyle(AyuWalkTheme.ink)

                        Text(statusText)
                            .font(AyuWalkTypography.body)
                            .foregroundStyle(AyuWalkTheme.mutedInk)
                    }

                    Spacer()
                }

                if let displayReminder {
                    HStack(spacing: AyuWalkSpacing.sm) {
                        AWStatusPill(
                            text: "出发前 \(displayReminder.dayOffsetBeforeTrip) 天",
                            systemImage: "calendar.badge.clock",
                            tint: AyuWalkTheme.secondaryAccent
                        )
                        AWStatusPill(
                            text: displayReminder.fireTime,
                            systemImage: "clock",
                            tint: AyuWalkTheme.accent
                        )
                    }

                    if let note = displayReminder.note, !note.isEmpty {
                        Text(note)
                            .font(AyuWalkTypography.caption)
                            .foregroundStyle(AyuWalkTheme.mutedInk)
                    }
                }

                HStack(spacing: AyuWalkSpacing.sm) {
                    if let reminder {
                        AWActionCapsuleButton(
                            title: reminder.isEnabled ? "关闭提醒" : "开启提醒",
                            systemImage: reminder.isEnabled ? "bell.slash" : "bell",
                            tint: AyuWalkTheme.secondaryAccent,
                            isProminent: !reminder.isEnabled
                        ) {
                            var updatedReminder = reminder
                            updatedReminder.isEnabled.toggle()
                            onUpdateReminder(updatedReminder)
                        }

                        Button(role: .destructive) {
                            onUpdateReminder(nil)
                        } label: {
                            Image(systemName: "trash")
                                .font(AyuWalkTypography.icon(size: 15, weight: .bold))
                                .frame(width: AyuWalkSize.compactIconButton, height: AyuWalkSize.compactIconButton)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AyuWalkTheme.accent)
                        .accessibilityLabel("删除打包提醒")
                    } else if let suggestedReminder {
                        AWActionCapsuleButton(
                            title: "使用建议",
                            systemImage: "plus.circle.fill",
                            tint: AyuWalkTheme.secondaryAccent,
                            isProminent: true
                        ) {
                            var enabledReminder = suggestedReminder
                            enabledReminder.isEnabled = true
                            onUpdateReminder(enabledReminder)
                        }
                    }
                }
            }
        }
    }

    private var statusText: String {
        if let reminder {
            return reminder.isEnabled ? "已为当前行程开启系统提醒。" : "提醒计划已保存，当前未开启。"
        }
        if suggestedReminder != nil {
            return "根据未打包物品生成一个建议提醒。"
        }
        return "当前物品已全部打包，暂时不需要提醒。"
    }
}

private struct AWPackingTemplateTile: View {
    let template: PackingTemplate
    let recommendation: PackingTemplateRecommendation?
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AyuWalkSpacing.sm) {
            HStack {
                AWIconBadge(
                    systemImage: template.systemImage,
                    tint: isSelected ? AyuWalkTheme.secondaryAccent : AyuWalkTheme.accent,
                    size: AyuWalkSize.largeIconButton
                )

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AyuWalkTheme.secondaryAccent)
                }
            }

            Text(template.title)
                .font(AyuWalkTypography.bodyStrong)
                .foregroundStyle(AyuWalkTheme.ink)

            Text(template.subtitle)
                .font(AyuWalkTypography.caption)
                .foregroundStyle(AyuWalkTheme.mutedInk)
                .lineLimit(2)

            if let recommendation {
                Text(recommendation.reason)
                    .font(AyuWalkTypography.micro)
                    .foregroundStyle(AyuWalkTheme.accent)
                    .lineLimit(3)
            }

            Text("\(template.items.count) 项")
                .font(AyuWalkTypography.captionStrong)
                .foregroundStyle(AyuWalkTheme.secondaryAccent)
        }
        .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
        .padding(AyuWalkSpacing.md)
        .awPaperInsetBackground(
            cornerRadius: AyuWalkRadii.card,
            fill: isSelected ? AyuWalkTheme.elevated : AyuWalkTheme.surface,
            borderTint: isSelected ? AyuWalkTheme.secondaryAccent : AyuWalkTheme.accent,
            borderOpacity: isSelected ? 0.35 : 0.10
        )
        .overlay(alignment: .topTrailing) {
            if recommendation != nil && !isSelected {
                Image.awWashiTapeSage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 46, height: 18)
                    .rotationEffect(.degrees(7))
                    .opacity(0.36)
                    .offset(x: -8, y: -8)
                    .allowsHitTesting(false)
            }
        }
    }
}

struct AWPackingAddItemCard: View {
    @Binding var title: String
    @Binding var notes: String
    var onAdd: () -> Void

    var body: some View {
        AWCardChrome(cornerRadius: AyuWalkRadii.panel) {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.md) {
                Text("添加物品")
                    .font(AyuWalkTypography.sectionTitle)
                    .foregroundStyle(AyuWalkTheme.ink)

                AWTextField(placeholder: "物品名称", text: $title)
                AWTextField(placeholder: "备注，可不填", text: $notes, font: AyuWalkTypography.body)

                Button(action: onAdd) {
                    Label("添加到清单", systemImage: "plus.circle.fill")
                        .font(AyuWalkTypography.metric)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AyuWalkSpacing.md)
                        .background(AyuWalkTheme.secondaryAccent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct AWPackingChecklistCard: View {
    let items: [PackingItem]
    @Binding var selectedItemIDs: Set<UUID>
    @Binding var isManaging: Bool
    var onToggleItem: (UUID) -> Void
    var onUpdateItem: (UUID, String, String?) -> Void
    var onRequestDeleteItem: (UUID) -> Void
    var onRequestDeleteSelected: () -> Void

    var body: some View {
        AWCardChrome(cornerRadius: AyuWalkRadii.panel) {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.md) {
                HStack {
                    Text(isManaging ? "已选择 \(selectedItemIDs.count) 项" : "清单")
                        .font(AyuWalkTypography.sectionTitle)
                        .foregroundStyle(AyuWalkTheme.ink)

                    Spacer()

                    if isManaging && !selectedItemIDs.isEmpty {
                        Button(action: onRequestDeleteSelected) {
                            Image(systemName: "trash")
                                .foregroundStyle(AyuWalkTheme.accent)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("删除所选物品")
                    }

                    Button {
                        isManaging.toggle()
                        selectedItemIDs.removeAll()
                    } label: {
                        Text(isManaging ? "完成" : "批量管理")
                            .font(AyuWalkTypography.captionStrong)
                            .foregroundStyle(AyuWalkTheme.secondaryAccent)
                    }
                    .buttonStyle(.plain)
                }

                if items.isEmpty {
                    Text("暂无行李项目")
                        .font(AyuWalkTypography.body)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                        .padding(.vertical, AyuWalkSpacing.md)
                } else {
                    ForEach(items) { item in
                        AWPackingItemRow(
                            item: item,
                            isManaging: isManaging,
                            isSelected: selectedItemIDs.contains(item.id),
                            onSelect: {
                                if selectedItemIDs.contains(item.id) {
                                    selectedItemIDs.remove(item.id)
                                } else {
                                    selectedItemIDs.insert(item.id)
                                }
                            },
                            onToggle: onToggleItem,
                            onUpdate: onUpdateItem,
                            onDelete: onRequestDeleteItem
                        )

                        if item.id != items.last?.id {
                            Divider()
                                .overlay(AyuWalkTheme.border)
                        }
                    }
                }
            }
        }
    }
}

private struct AWPackingItemRow: View {
    let item: PackingItem
    let isManaging: Bool
    let isSelected: Bool
    var onSelect: () -> Void
    var onToggle: (UUID) -> Void
    var onUpdate: (UUID, String, String?) -> Void
    var onDelete: (UUID) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AyuWalkSpacing.md) {
            Button {
                if isManaging {
                    onSelect()
                } else {
                    onToggle(item.id)
                }
            } label: {
                Image(systemName: (isManaging ? isSelected : item.isPacked) ? "checkmark.circle.fill" : "circle")
                    .font(AyuWalkTypography.icon(size: 23))
                    .foregroundStyle((isManaging ? isSelected : item.isPacked) ? AyuWalkTheme.secondaryAccent : AyuWalkTheme.mutedInk)
                    .frame(width: 32, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                isManaging
                    ? (isSelected ? "取消选择\(item.title)" : "选择\(item.title)")
                    : (item.isPacked ? "取消打包\(item.title)" : "标记\(item.title)已打包")
            )

            VStack(alignment: .leading, spacing: AyuWalkSpacing.xs) {
                TextField(
                    "物品名称",
                    text: Binding(
                        get: { item.title },
                        set: { onUpdate(item.id, $0, item.notes) }
                    )
                )
                .textFieldStyle(.plain)
                .font(AyuWalkTypography.bodyStrong)
                .foregroundStyle(AyuWalkTheme.ink)
                .disabled(isManaging)

                TextField(
                    "备注",
                    text: Binding(
                        get: { item.notes ?? "" },
                        set: { onUpdate(item.id, item.title, $0) }
                    )
                )
                .textFieldStyle(.plain)
                .font(AyuWalkTypography.caption)
                .foregroundStyle(AyuWalkTheme.mutedInk)
                .disabled(isManaging)
            }

            if !isManaging {
                Button {
                    onDelete(item.id)
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
                .accessibilityLabel("删除\(item.title)")
            }
        }
        .padding(.vertical, AyuWalkSpacing.xs)
    }
}
