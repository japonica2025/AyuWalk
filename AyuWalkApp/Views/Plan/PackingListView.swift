import AyuWalkCore
import SwiftUI

struct PackingListView: View {
    let items: [PackingItem]
    let onToggleItem: (UUID) -> Void
    let onAddItem: (String, String?) -> Void
    let onUpdateItem: (UUID, String, String?) -> Void
    let onDeleteItem: (UUID) -> Void

    @State private var newItemTitle = ""
    @State private var newItemNotes = ""

    private var packedCount: Int {
        items.filter(\.isPacked).count
    }

    var body: some View {
        AWSheetScaffold(title: "行李清单") {
            AWPackingProgressCard(packedCount: packedCount, itemCount: items.count)

            AWPackingAddItemCard(title: $newItemTitle, notes: $newItemNotes) {
                onAddItem(newItemTitle, newItemNotes)
                newItemTitle = ""
                newItemNotes = ""
            }

            AWPackingChecklistCard(
                items: items,
                onToggleItem: onToggleItem,
                onUpdateItem: onUpdateItem,
                onDeleteItem: onDeleteItem
            )
        }
    }
}

#Preview {
    PackingListView(
        items: SampleTripFactory.tokyoFiveDayTrip().packingList?.items ?? [],
        onToggleItem: { _ in },
        onAddItem: { _, _ in },
        onUpdateItem: { _, _, _ in },
        onDeleteItem: { _ in }
    )
}
