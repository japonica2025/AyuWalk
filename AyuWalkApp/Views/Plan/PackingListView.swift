import AyuWalkCore
import SwiftUI

struct PackingListView: View {
    let items: [PackingItem]
    let onToggleItem: (UUID) -> Void
    let onAddItem: (String, String?) -> Void
    let onUpdateItem: (UUID, String, String?) -> Void
    let onDeleteItems: (Set<UUID>) -> Void
    let onApplyTemplates: ([PackingTemplate]) -> Void

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
            AWPackingProgressCard(
                packedCount: packedCount,
                itemCount: items.count,
                onOpenTemplates: {
                    selectedTemplateIDs.removeAll()
                    isShowingTemplates = true
                }
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
        items: SampleTripFactory.tokyoFiveDayTrip().packingList?.items ?? [],
        onToggleItem: { _ in },
        onAddItem: { _, _ in },
        onUpdateItem: { _, _, _ in },
        onDeleteItems: { _ in },
        onApplyTemplates: { _ in }
    )
}
