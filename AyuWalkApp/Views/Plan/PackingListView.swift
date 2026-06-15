import AyuWalkCore
import SwiftUI

struct PackingListView: View {
    let trip: Trip
    let items: [PackingItem]
    let onToggleItem: (UUID) -> Void
    let onAddItem: (String, String?) -> Void
    let onUpdateItem: (UUID, String, String?) -> Void
    let onDeleteItems: (Set<UUID>) -> Void
    let onApplyTemplates: ([PackingTemplate]) -> Void
    let onUpdateReminder: (PackingReminder?) -> Void

    @State private var newItemTitle = ""
    @State private var newItemNotes = ""
    @State private var isShowingTemplates = false
    @State private var selectedTemplateIDs: Set<PackingTemplateID> = []
    @State private var isManagingItems = false
    @State private var selectedItemIDs: Set<UUID> = []
    @State private var pendingDeletionIDs: Set<UUID> = []
    @State private var isShowingDeleteConfirmation = false

    private var packedCount: Int {
        items.filter(\.isPacked).count
    }

    private var recommendations: [PackingTemplateRecommendation] {
        PackingTemplateLibrary.recommendations(for: trip, packingList: packingList)
    }

    private var packingList: PackingList {
        PackingList(items: items, reminder: trip.packingList?.reminder)
    }

    private var suggestedReminder: PackingReminder? {
        PackingReminderPlanner.suggestedReminder(for: trip, packingList: packingList)
    }

    private var deletionTitle: String {
        if pendingDeletionIDs.count == 1,
           let item = items.first(where: { pendingDeletionIDs.contains($0.id) }) {
            return "删除“\(item.title)”？"
        }
        return "删除所选 \(pendingDeletionIDs.count) 个物品？"
    }

    private var deletionMessage: String {
        let names = items
            .filter { pendingDeletionIDs.contains($0.id) }
            .prefix(3)
            .map(\.title)
            .joined(separator: "、")
        let remainder = max(pendingDeletionIDs.count - 3, 0)
        let summary = remainder > 0 ? "\(names) 等 \(pendingDeletionIDs.count) 项" : names
        return summary.isEmpty ? "删除后无法恢复。" : "\(summary)\n删除后无法恢复。"
    }

    var body: some View {
        AWSheetScaffold(title: "行李清单") {
            AWPaperSurface(
                background: AyuWalkTheme.surface,
                tint: AyuWalkTheme.secondaryAccent,
                cornerRadius: AyuWalkTheme.panelRadius,
                padding: AyuWalkSpacing.lg,
                borderOpacity: 0.10,
                shadowRadius: 14,
                shadowY: 7
            ) {
                VStack(alignment: .leading, spacing: AyuWalkSpacing.md) {
                    HStack {
                        AWStickerIconTray(systemImages: ["suitcase.fill", "checkmark.circle.fill"], tint: AyuWalkTheme.secondaryAccent)
                        Spacer()
                        AWPaperTab(title: "\(packedCount)/\(items.count)", systemImage: "checklist", tint: AyuWalkTheme.accent)
                    }

                    Text("把行李当作出发前的小清单")
                        .font(AyuWalkTypography.sectionTitle)
                        .foregroundStyle(AyuWalkTheme.ink)

                    Text("模板、提醒、手动添加和批量管理都保留原来的操作方式。")
                        .font(AyuWalkTypography.caption)
                        .foregroundStyle(AyuWalkTheme.mutedInk)

                    AWDecorDivider(tint: AyuWalkTheme.secondaryAccent)
                }
            }
            .overlay(alignment: .topLeading) {
                Image.awWashiTapeSage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 78, height: 24)
                    .opacity(0.46)
                    .offset(x: 28, y: -12)
                    .allowsHitTesting(false)
            }

            AWPackingProgressCard(
                packedCount: packedCount,
                itemCount: items.count,
                onOpenTemplates: {
                    selectedTemplateIDs = Set(recommendations.map(\.template.id))
                    isShowingTemplates = true
                }
            )

            AWPackingReminderCard(
                reminder: trip.packingList?.reminder,
                suggestedReminder: suggestedReminder,
                onUpdateReminder: onUpdateReminder
            )

            AWPackingAddItemCard(title: $newItemTitle, notes: $newItemNotes) {
                onAddItem(newItemTitle, newItemNotes)
                newItemTitle = ""
                newItemNotes = ""
            }

            AWPackingChecklistCard(
                items: items,
                selectedItemIDs: $selectedItemIDs,
                isManaging: $isManagingItems,
                onToggleItem: onToggleItem,
                onUpdateItem: onUpdateItem,
                onRequestDeleteItem: { itemID in
                    requestDeletion(ids: [itemID])
                },
                onRequestDeleteSelected: {
                    requestDeletion(ids: selectedItemIDs)
                }
            )
        }
        .sheet(isPresented: $isShowingTemplates) {
            AWPackingTemplatePicker(
                templates: PackingTemplateLibrary.default,
                recommendations: recommendations,
                selectedTemplateIDs: $selectedTemplateIDs
            ) {
                let templates = PackingTemplateLibrary.default.filter { selectedTemplateIDs.contains($0.id) }
                onApplyTemplates(templates)
                selectedTemplateIDs.removeAll()
                isShowingTemplates = false
            }
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            deletionTitle,
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("确认删除", role: .destructive) {
                onDeleteItems(pendingDeletionIDs)
                selectedItemIDs.subtract(pendingDeletionIDs)
                pendingDeletionIDs.removeAll()
            }
            Button("取消", role: .cancel) {
                pendingDeletionIDs.removeAll()
            }
        } message: {
            Text(deletionMessage)
        }
    }

    private func requestDeletion(ids: Set<UUID>) {
        guard !ids.isEmpty else {
            return
        }

        pendingDeletionIDs = ids
        isShowingDeleteConfirmation = true
    }
}

#Preview {
    PackingListView(
        trip: SampleTripFactory.tokyoFiveDayTrip(),
        items: SampleTripFactory.tokyoFiveDayTrip().packingList?.items ?? [],
        onToggleItem: { _ in },
        onAddItem: { _, _ in },
        onUpdateItem: { _, _, _ in },
        onDeleteItems: { _ in },
        onApplyTemplates: { _ in },
        onUpdateReminder: { _ in }
    )
}
