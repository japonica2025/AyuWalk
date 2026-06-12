import AyuWalkCore
import SwiftUI

struct JournalPageCard: View {
    let page: JournalPage
    var visibleBlocks: [JournalBlock]? = nil
    var placedStickers: [PlacedJournalSticker] = []
    var isStickerEditingMode = false
    var onDropSticker: (UUID, Double, Double) -> Void = { _, _, _ in }
    var onRemoveSticker: (UUID) -> Void = { _ in }
    var onMoveSticker: (UUID, Double, Double) -> Void = { _, _, _ in }
    var onTransformSticker: (UUID, Double, Double) -> Void = { _, _, _ in }
    var onStickerInteractionChanged: (Bool) -> Void = { _ in }

    @State private var isStickerInteracting = false

    var body: some View {
        AWJournalBookFrame {
            AWJournalPageSurface {
                ScrollView(.vertical, showsIndicators: true) {
                    ZStack(alignment: .topLeading) {
                        GeometryReader { proxy in
                            ZStack(alignment: .topLeading) {
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack {
                                        Text(page.kind.displayName)
                                            .font(AyuWalkTypography.captionStrong)
                                            .foregroundStyle(AyuWalkTheme.accent)

                                        Spacer()

                                        Text("Ayu Walk")
                                            .font(AyuWalkTypography.microStrong)
                                            .foregroundStyle(AyuWalkTheme.mutedInk)
                                    }

                                    Text(page.title)
                                        .font(AyuWalkTypography.pageTitle)
                                        .foregroundStyle(AyuWalkTheme.ink)
                                        .fixedSize(horizontal: false, vertical: true)

                                    ForEach(visibleBlocks ?? page.blocks) { block in
                                        AWJournalBlockCard(block: block)
                                    }

                                    Spacer(minLength: 24)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.trailing, 4)
                                .padding(.bottom, 72)

                                AWStickerLayer(
                                    placedStickers: placedStickers,
                                    onRemove: onRemoveSticker,
                                    onMove: onMoveSticker,
                                    onTransform: onTransformSticker,
                                    onInteractionChanged: { isInteracting in
                                        isStickerInteracting = isInteracting
                                        onStickerInteractionChanged(isInteracting)
                                    }
                                )
                            }
                            .dropDestination(for: String.self) { items, location in
                                guard let firstItem = items.first,
                                      let stickerID = UUID(uuidString: firstItem) else {
                                    return false
                                }

                                onDropSticker(
                                    stickerID,
                                    location.x / max(proxy.size.width, 1),
                                    location.y / max(proxy.size.height, 1)
                                )
                                return true
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 560, alignment: .topLeading)
                }
                .scrollDisabled(isStickerEditingMode || isStickerInteracting)
                .frame(maxWidth: .infinity, minHeight: 430, maxHeight: 560, alignment: .topLeading)
            }
        }
    }
}

private extension JournalPageKind {
    var displayName: String {
        switch self {
        case .cover:
            return "封面"
        case .overview:
            return "总览"
        case .day:
            return "每日页面"
        case .summary:
            return "总结"
        }
    }
}

#Preview {
    JournalPageCard(page: MockJournalEngine().generatePages(for: SampleTripFactory.tokyoFiveDayTrip()).first!)
        .padding()
}
