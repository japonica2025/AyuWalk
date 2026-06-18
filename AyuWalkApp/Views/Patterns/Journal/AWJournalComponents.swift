import AyuWalkCore
import SwiftUI
import UIKit

struct AWJournalBookFrame<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal, AyuWalkSpacing.sm)
            .padding(.vertical, AyuWalkSpacing.md)
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(AyuWalkTheme.surface)
                    .overlay {
                        Image.awPaperCardSurface
                            .resizable()
                            .scaledToFill()
                            .opacity(AyuWalkTexture.cardOpacity)
                            .blendMode(.multiply)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    }
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(AyuWalkTheme.accent.opacity(0.16))
                            .frame(width: 5)
                            .padding(.vertical, 24)
                            .padding(.leading, 9)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(AyuWalkTheme.border, lineWidth: 1)
                    }
                    .shadow(color: AyuWalkShadow.journal, radius: 20, x: 0, y: 12)
            }
    }
}

struct AWJournalPageSurface<Content: View>: View {
    var minHeight: CGFloat = 420
    @ViewBuilder let content: Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            journalPaperTexture

            content
                .padding(AyuWalkSpacing.xl)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: minHeight, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: AyuWalkRadii.journalPage, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AyuWalkRadii.journalPage, style: .continuous)
                .stroke(AyuWalkTheme.border, lineWidth: 1)
        }
    }

    private var journalPaperTexture: some View {
        ZStack {
            AyuWalkTheme.paper

            Image.awPaperCardSurface
                .resizable()
                .scaledToFill()
                .opacity(AyuWalkTexture.cardOpacity)
                .blendMode(.multiply)

            VStack(spacing: 28) {
                ForEach(0..<16, id: \.self) { _ in
                    Rectangle()
                        .fill(AyuWalkTheme.hairline.opacity(0.34))
                        .frame(height: 1)
                }
            }
            .padding(.top, 58)
            .padding(.horizontal, AyuWalkSpacing.xl)
        }
    }
}

struct AWJournalBlockCard: View {
    let block: JournalBlock

    var body: some View {
        VStack(alignment: .leading, spacing: AyuWalkSpacing.xs) {
            if let title = block.title {
                HStack(spacing: AyuWalkSpacing.xs) {
                    Image(systemName: iconName)
                        .font(AyuWalkTypography.microStrong)

                    Text(title)
                        .font(AyuWalkTypography.captionStrong)

                    if block.isDefaultSelected {
                        Text("默认")
                            .font(AyuWalkTypography.microStrong)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AyuWalkTheme.secondaryAccent)
                            .clipShape(Capsule())
                    }
                }
                .foregroundStyle(AyuWalkTheme.secondaryAccent)
            }

            Text(block.text ?? "")
                .font(AyuWalkTypography.body)
                .foregroundStyle(AyuWalkTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AyuWalkSpacing.md)
        .awPaperInsetBackground(
            cornerRadius: AyuWalkRadii.smallCard,
            fill: AyuWalkTheme.surface.opacity(0.62),
            borderTint: AyuWalkTheme.accent
        )
    }

    private var iconName: String {
        switch block.kind {
        case .title:
            return "textformat"
        case .dateLocation:
            return "calendar"
        case .photo:
            return "photo"
        case .text:
            return "text.alignleft"
        case .mapSnapshot:
            return "map"
        case .routeSummary:
            return "point.topleft.down.curvedto.point.bottomright.up"
        case .timeline:
            return "list.bullet.rectangle"
        case .placeHighlights:
            return "mappin.and.ellipse"
        case .budgetSummary:
            return "creditcard.fill"
        case .packingSummary:
            return "suitcase.fill"
        case .mood:
            return "heart.fill"
        case .sticker:
            return "seal.fill"
        }
    }
}

struct AWStickerLayer: View {
    let placedStickers: [PlacedJournalSticker]
    var onRemove: (UUID) -> Void = { _ in }
    var onMove: (UUID, Double, Double) -> Void = { _, _, _ in }
    var onTransform: (UUID, Double, Double) -> Void = { _, _, _ in }
    var onInteractionChanged: (Bool) -> Void = { _ in }

    @State private var selectedStickerID: UUID?
    @State private var dragOffsets: [UUID: CGSize] = [:]
    @State private var scaleDrafts: [UUID: Double] = [:]
    @State private var rotationDrafts: [UUID: Double] = [:]

    var body: some View {
        if !placedStickers.isEmpty {
            GeometryReader { proxy in
                ForEach(Array(placedStickers.enumerated()), id: \.element.id) { index, placedSticker in
                    let dragOffset = dragOffsets[placedSticker.id] ?? .zero
                    let isSelected = selectedStickerID == placedSticker.id
                    let scale = scaleDrafts[placedSticker.id] ?? placedSticker.placement.scale
                    let rotation = rotationDrafts[placedSticker.id] ?? placedSticker.placement.rotationDegrees

                    stickerToken(
                        placedSticker: placedSticker,
                        isSelected: isSelected,
                        scale: scale,
                        rotationDegrees: rotation,
                        canvasSize: proxy.size
                    )
                    .position(
                        x: placedSticker.placement.xRatio * proxy.size.width,
                        y: placedSticker.placement.yRatio * proxy.size.height
                    )
                    .offset(dragOffset)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func stickerToken(
        placedSticker: PlacedJournalSticker,
        isSelected: Bool,
        scale: Double,
        rotationDegrees: Double,
        canvasSize: CGSize
    ) -> some View {
        ZStack {
            AWStickerToken(sticker: placedSticker.sticker)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotationDegrees))
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedStickerID = isSelected ? nil : placedSticker.id
                }
                .gesture(
                    DragGesture(minimumDistance: 8)
                        .onChanged { value in
                            if selectedStickerID != placedSticker.id {
                                selectedStickerID = placedSticker.id
                            }
                            onInteractionChanged(true)
                            dragOffsets[placedSticker.id] = value.translation
                        }
                        .onEnded { value in
                            dragOffsets[placedSticker.id] = nil
                            let xRatio = placedSticker.placement.xRatio + value.translation.width / max(canvasSize.width, 1)
                            let yRatio = placedSticker.placement.yRatio + value.translation.height / max(canvasSize.height, 1)

                            onMove(placedSticker.id, xRatio, yRatio)
                            onInteractionChanged(false)
                        }
                )

            if isSelected {
                stickerEditingChrome(
                    placedSticker: placedSticker,
                    scale: scale,
                    rotationDegrees: rotationDegrees
                )
            }
        }
        .frame(
            width: editingChromeSize(for: scale).width,
            height: editingChromeSize(for: scale).height
        )
        .contentShape(Rectangle())
    }

    private func stickerEditingChrome(
        placedSticker: PlacedJournalSticker,
        scale: Double,
        rotationDegrees: Double
    ) -> some View {
        let boxSize = editingBoxSize(for: scale)

        return ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    AyuWalkTheme.secondaryAccent,
                    style: StrokeStyle(lineWidth: 1.3, dash: [4, 3])
                )
                .frame(width: boxSize.width, height: boxSize.height)
                .rotationEffect(.degrees(rotationDegrees))
                .allowsHitTesting(false)

            stickerEditHandle(systemImage: "arrow.triangle.2.circlepath")
                .offset(
                    rotatedCornerOffset(
                        xSign: -1,
                        ySign: -1,
                        boxSize: boxSize,
                        rotationDegrees: rotationDegrees
                    )
                )
                .gesture(
                    DragGesture(minimumDistance: 4)
                        .onChanged { value in
                            onInteractionChanged(true)
                            rotationDrafts[placedSticker.id] = placedSticker.placement.rotationDegrees + Double(value.translation.width)
                        }
                        .onEnded { value in
                            let newRotation = placedSticker.placement.rotationDegrees + Double(value.translation.width)
                            rotationDrafts[placedSticker.id] = nil
                            onTransform(placedSticker.id, placedSticker.placement.scale, newRotation)
                            onInteractionChanged(false)
                        }
                )

            Button {
                onRemove(placedSticker.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(Color.red)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.9), lineWidth: 1.5)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("删除\(placedSticker.sticker.title)")
            .offset(
                rotatedCornerOffset(
                    xSign: 1,
                    ySign: -1,
                    boxSize: boxSize,
                    rotationDegrees: rotationDegrees
                )
            )

            stickerEditHandle(systemImage: "arrow.up.left.and.arrow.down.right")
                .offset(
                    rotatedCornerOffset(
                        xSign: 1,
                        ySign: 1,
                        boxSize: boxSize,
                        rotationDegrees: rotationDegrees
                    )
                )
                .gesture(
                    DragGesture(minimumDistance: 4)
                        .onChanged { value in
                            onInteractionChanged(true)
                            let delta = (value.translation.width + value.translation.height) / 140
                            scaleDrafts[placedSticker.id] = min(max(placedSticker.placement.scale + delta, 0.65), 2.2)
                        }
                        .onEnded { value in
                            let delta = (value.translation.width + value.translation.height) / 140
                            let newScale = min(max(placedSticker.placement.scale + delta, 0.65), 2.2)
                            scaleDrafts[placedSticker.id] = nil
                            onTransform(placedSticker.id, newScale, placedSticker.placement.rotationDegrees)
                            onInteractionChanged(false)
                        }
                )
        }
    }

    private func editingBoxSize(for scale: Double) -> CGSize {
        CGSize(width: max(72, 98 * scale), height: max(38, 44 * scale))
    }

    private func editingChromeSize(for scale: Double) -> CGSize {
        let boxSize = editingBoxSize(for: scale)
        let diagonal = sqrt(boxSize.width * boxSize.width + boxSize.height * boxSize.height)
        let controlAllowance: CGFloat = 48
        return CGSize(width: diagonal + controlAllowance, height: diagonal + controlAllowance)
    }

    private func rotatedCornerOffset(
        xSign: CGFloat,
        ySign: CGFloat,
        boxSize: CGSize,
        rotationDegrees: Double
    ) -> CGSize {
        let controlGap: CGFloat = 12
        let x = xSign * (boxSize.width / 2 + controlGap)
        let y = ySign * (boxSize.height / 2 + controlGap)
        let radians = CGFloat(rotationDegrees * .pi / 180)
        return CGSize(
            width: x * cos(radians) - y * sin(radians),
            height: x * sin(radians) + y * cos(radians)
        )
    }

    private func stickerEditHandle(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(AyuWalkTheme.secondaryAccent)
            .frame(width: 22, height: 22)
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
                    .stroke(AyuWalkTheme.secondaryAccent.opacity(0.42), lineWidth: 1)
            }
            .shadow(color: AyuWalkShadow.journal, radius: 6, x: 0, y: 3)
    }
}

struct AWStickerToken: View {
    let sticker: Sticker

    var body: some View {
        HStack(spacing: 6) {
            if let imageDataBase64 = sticker.imageDataBase64,
               let imageData = Data(base64Encoded: imageDataBase64),
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 22, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            } else {
                Image(systemName: sticker.symbol)
                    .font(.caption.weight(.bold))
            }
            Text(sticker.title)
                .font(AyuWalkTypography.captionStrong)
                .lineLimit(1)
        }
        .foregroundStyle(AyuWalkTheme.ink)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(AyuWalkTheme.surface.opacity(0.92))

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
        .shadow(color: AyuWalkShadow.journal, radius: 8, x: 0, y: 4)
    }
}

#Preview {
    AWJournalBookFrame {
        AWJournalPageSurface {
            VStack(alignment: .leading, spacing: 12) {
                AWJournalBlockCard(
                    block: JournalBlock(
                        id: UUID(),
                        kind: .text,
                        title: "文字记录",
                        text: "今天的路线和心情记录会放在这里。",
                        assetReference: nil,
                        isDefaultSelected: true
                    )
                )
            }
        }
    }
    .padding()
}
