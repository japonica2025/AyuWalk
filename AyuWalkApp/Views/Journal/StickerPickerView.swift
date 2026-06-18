import AyuWalkCore
import SwiftUI

struct StickerPickerView: View {
    let pageTitle: String
    let library: StickerLibrary
    let isSelected: (UUID) -> Bool
    let onToggle: (UUID) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AyuWalkTheme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pageTitle)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(AyuWalkTheme.ink)
                            Text("选择后会贴在当前手帐页面上")
                                .font(.caption)
                                .foregroundStyle(AyuWalkTheme.mutedInk)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        selectedStickerPreview
                            .padding(.horizontal, 20)

                        uploadPlaceholder
                            .padding(.horizontal, 20)

                        ForEach(library.categories) { category in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(category.title)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AyuWalkTheme.ink)

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                                    ForEach(category.stickers) { sticker in
                                        Button {
                                            onToggle(sticker.id)
                                        } label: {
                                            VStack(spacing: 8) {
                                                Image(systemName: sticker.symbol)
                                                    .font(.system(size: 22, weight: .semibold))
                                                Text(sticker.title)
                                                    .font(.caption.weight(.bold))
                                            }
                                            .foregroundStyle(isSelected(sticker.id) ? .white : AyuWalkTheme.ink)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .awPaperInsetBackground(
                                                cornerRadius: AyuWalkRadii.card,
                                                fill: isSelected(sticker.id) ? AyuWalkTheme.secondaryAccent : AyuWalkTheme.paper,
                                                borderTint: isSelected(sticker.id) ? AyuWalkTheme.secondaryAccent : AyuWalkTheme.accent,
                                                borderOpacity: isSelected(sticker.id) ? 0 : 0.10,
                                                textureOpacity: isSelected(sticker.id) ? 0 : AyuWalkTexture.cardOpacity
                                            )
                                        }
                                        .accessibilityLabel(sticker.title)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("选择贴纸")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var selectedStickers: [Sticker] {
        library.categories
            .flatMap(\.stickers)
            .filter { isSelected($0.id) }
    }

    private var selectedStickerPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("当前页已贴")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AyuWalkTheme.ink)

                Spacer()

                Text("\(selectedStickers.count) 个")
                    .font(AyuWalkTypography.microStrong)
                    .foregroundStyle(AyuWalkTheme.secondaryAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .awPaperCapsuleBackground(
                        fill: AyuWalkTheme.pageBackground,
                        borderTint: AyuWalkTheme.secondaryAccent,
                        borderOpacity: 0.12
                    )
            }

            if selectedStickers.isEmpty {
                Text("还没有给这一页添加贴纸。")
                    .font(AyuWalkTypography.caption)
                    .foregroundStyle(AyuWalkTheme.mutedInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .awPaperInsetBackground(
                        cornerRadius: AyuWalkRadii.card,
                        fill: AyuWalkTheme.paper,
                        borderTint: AyuWalkTheme.accent
                    )
            } else {
                FlowStickerRow(stickers: selectedStickers) { sticker in
                    onToggle(sticker.id)
                }
            }
        }
    }

    private var uploadPlaceholder: some View {
        HStack(spacing: 10) {
            Image(systemName: "photo.badge.plus")
                .font(.headline.weight(.bold))
                .foregroundStyle(AyuWalkTheme.secondaryAccent)
                .frame(width: 34, height: 34)
                .background {
                    Circle()
                        .fill(AyuWalkTheme.secondaryAccent.opacity(0.10))

                    Image.awPaperCardSurface
                        .resizable()
                        .scaledToFill()
                        .opacity(AyuWalkTexture.cardOpacity)
                        .blendMode(.multiply)
                        .clipShape(Circle())
                }
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("上传图片贴纸")
                    .font(AyuWalkTypography.captionStrong)
                    .foregroundStyle(AyuWalkTheme.ink)
                Text("预留功能，后续支持透明 PNG 和照片抠图")
                    .font(AyuWalkTypography.micro)
                    .foregroundStyle(AyuWalkTheme.mutedInk)
            }

            Spacer()

            Text("未开放")
                .font(AyuWalkTypography.microStrong)
                .foregroundStyle(AyuWalkTheme.mutedInk)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .awPaperCapsuleBackground(
                    fill: AyuWalkTheme.pageBackground,
                    borderTint: AyuWalkTheme.accent,
                    borderOpacity: 0.08
                )
        }
        .padding(12)
        .awPaperInsetBackground(
            cornerRadius: AyuWalkRadii.card,
            fill: AyuWalkTheme.paper.opacity(0.82),
            borderTint: AyuWalkTheme.accent
        )
    }
}

private struct FlowStickerRow: View {
    let stickers: [Sticker]
    let onRemove: (Sticker) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 8) {
            ForEach(stickers) { sticker in
                Button {
                    onRemove(sticker)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: sticker.symbol)
                            .font(AyuWalkTypography.microStrong)
                        Text(sticker.title)
                            .font(AyuWalkTypography.microStrong)
                            .lineLimit(1)
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(AyuWalkTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(AyuWalkTheme.surface)

                        Image.awPaperCardSurface
                            .resizable()
                            .scaledToFill()
                            .opacity(AyuWalkTexture.cardOpacity)
                            .blendMode(.multiply)
                            .clipShape(Capsule())
                    }
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(AyuWalkTheme.border, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("移除\(sticker.title)")
            }
        }
    }
}

#Preview {
    StickerPickerView(
        pageTitle: "涩谷 - 原宿",
        library: .default,
        isSelected: { _ in false },
        onToggle: { _ in }
    )
}
