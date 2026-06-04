import AyuWalkCore
import SwiftUI

struct AWPackingProgressCard: View {
    let packedCount: Int
    let itemCount: Int

    var body: some View {
        AWCardChrome(cornerRadius: AyuWalkRadii.panel) {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.md) {
                Text("打包进度")
                    .font(AyuWalkTypography.eyebrow)
                    .foregroundStyle(AyuWalkTheme.secondaryAccent)

                Text("\(packedCount)/\(itemCount) 已完成")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AyuWalkTheme.ink)

                ProgressView(value: itemCount == 0 ? 0 : Double(packedCount), total: Double(max(itemCount, 1)))
                    .tint(AyuWalkTheme.secondaryAccent)

                Text("当前先生成基础清单，后续可以按目的地、天气和行程类型自动补充。")
                    .font(AyuWalkTypography.body)
                    .foregroundStyle(AyuWalkTheme.mutedInk)
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
    var onToggleItem: (UUID) -> Void
    var onUpdateItem: (UUID, String, String?) -> Void
    var onDeleteItem: (UUID) -> Void

    var body: some View {
        AWCardChrome(cornerRadius: AyuWalkRadii.panel) {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.md) {
                Text("清单")
                    .font(AyuWalkTypography.sectionTitle)
                    .foregroundStyle(AyuWalkTheme.ink)

                if items.isEmpty {
                    Text("暂无行李项目")
                        .font(AyuWalkTypography.body)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                        .padding(.vertical, AyuWalkSpacing.md)
                } else {
                    ForEach(items) { item in
                        AWPackingItemRow(
                            item: item,
                            onToggle: onToggleItem,
                            onUpdate: onUpdateItem,
                            onDelete: onDeleteItem
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
    var onToggle: (UUID) -> Void
    var onUpdate: (UUID, String, String?) -> Void
    var onDelete: (UUID) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AyuWalkSpacing.md) {
            Button {
                onToggle(item.id)
            } label: {
                Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                    .font(AyuWalkTypography.icon(size: 23))
                    .foregroundStyle(item.isPacked ? AyuWalkTheme.secondaryAccent : AyuWalkTheme.mutedInk)
                    .frame(width: 32, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isPacked ? "取消打包" : "标记已打包")

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
            }

            Button {
                onDelete(item.id)
            } label: {
                Image(systemName: "trash")
                    .font(AyuWalkTypography.icon(size: 15, weight: .bold))
                    .foregroundStyle(AyuWalkTheme.accent)
                    .frame(width: AyuWalkSize.compactIconButton, height: AyuWalkSize.compactIconButton)
                    .background(AyuWalkTheme.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("删除物品")
        }
        .padding(.vertical, AyuWalkSpacing.xs)
    }
}
