import AyuWalkCore
import SwiftUI

struct AWBudgetTotalCard: View {
    let currencyCode: String
    @Binding var budgetText: String
    var onSave: () -> Void

    var body: some View {
        AWCardChrome(cornerRadius: AyuWalkRadii.panel) {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.md) {
                Text("总预算")
                    .font(AyuWalkTypography.eyebrow)
                    .foregroundStyle(AyuWalkTheme.accent)

                HStack(alignment: .firstTextBaseline, spacing: AyuWalkSpacing.sm) {
                    Text(currencyCode)
                        .font(AyuWalkTypography.sectionTitle)
                        .foregroundStyle(AyuWalkTheme.mutedInk)

                    TextField("填写总预算", text: $budgetText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(AyuWalkTheme.ink)
                        .textFieldStyle(.plain)
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
            }
        }
    }
}

struct AWBudgetSplitCard: View {
    let perPersonText: String
    let participantCount: Int

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
                }

                Spacer()
            }
        }
    }
}

struct AWParticipantEditorCard: View {
    let participants: [Participant]
    let perPersonText: String
    @Binding var newParticipantName: String
    var onAdd: () -> Void
    var onUpdate: (UUID, String) -> Void
    var onDelete: (UUID) -> Void

    var body: some View {
        AWCardChrome(cornerRadius: AyuWalkRadii.panel) {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.md) {
                Text("参与人")
                    .font(AyuWalkTypography.sectionTitle)
                    .foregroundStyle(AyuWalkTheme.ink)

                HStack(spacing: AyuWalkSpacing.sm) {
                    AWTextField(placeholder: "添加参与人", text: $newParticipantName)

                    Button(action: onAdd) {
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
                    Text("还没有参与人，添加后会自动计算人均预算。")
                        .font(AyuWalkTypography.body)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                        .padding(.vertical, AyuWalkSpacing.xs)
                } else {
                    ForEach(participants) { participant in
                        AWParticipantEditorRow(
                            participant: participant,
                            perPersonText: perPersonText,
                            onUpdate: onUpdate,
                            onDelete: onDelete
                        )

                        if participant.id != participants.last?.id {
                            Divider()
                                .overlay(AyuWalkTheme.border)
                        }
                    }
                }
            }
        }
    }
}

private struct AWParticipantEditorRow: View {
    let participant: Participant
    let perPersonText: String
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

            Text(perPersonText)
                .font(AyuWalkTypography.captionStrong)
                .foregroundStyle(AyuWalkTheme.secondaryAccent)
                .lineLimit(1)

            Button {
                onDelete(participant.id)
            } label: {
                Image(systemName: "trash")
                    .font(AyuWalkTypography.icon(size: 15, weight: .bold))
                    .foregroundStyle(AyuWalkTheme.accent)
                    .frame(width: AyuWalkSize.compactIconButton, height: AyuWalkSize.compactIconButton)
                    .background(AyuWalkTheme.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("删除参与人")
        }
        .padding(.vertical, AyuWalkSpacing.xxs + 1)
    }
}
