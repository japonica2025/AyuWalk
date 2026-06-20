import SwiftUI

struct AWStatusPill: View {
    let text: String
    var systemImage: String?
    var tint: Color = AyuWalkTheme.secondaryAccent
    var isFilled = false
    var lineLimit: Int? = 1

    var body: some View {
        HStack(spacing: AyuWalkSpacing.xxs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(AyuWalkTypography.microStrong)
            }

            Text(text)
                .lineLimit(lineLimit)
        }
        .font(AyuWalkTypography.captionStrong)
        .foregroundStyle(isFilled ? .white : tint)
        .padding(.horizontal, AyuWalkSpacing.sm)
        .padding(.vertical, AyuWalkSpacing.xs - 1)
        .background {
            if isFilled {
                Capsule()
                    .fill(tint)

                Image.awPaperCardSurface
                    .resizable(resizingMode: .tile)
                    .opacity(AyuWalkTexture.cardOpacity * 0.6)
                    .blendMode(.softLight)
                    .clipShape(Capsule())
            } else {
                Capsule()
                    .fill(AyuWalkTheme.chipSurface)

                Image.awPaperCardSurface
                    .resizable(resizingMode: .tile)
                    .opacity(AyuWalkTexture.cardOpacity)
                    .blendMode(.multiply)
                    .clipShape(Capsule())
            }
        }
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(isFilled ? Color.clear : tint.opacity(0.14), lineWidth: 1)
        }
    }
}

struct AWSelectableChip: View {
    let title: String
    var systemImage: String?
    var isSelected: Bool
    var tint: Color = AyuWalkTheme.secondaryAccent
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AyuWalkSpacing.xxs + 1) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(AyuWalkTypography.microStrong)
                }

                Text(title)
                    .font(AyuWalkTypography.captionStrong)
            }
            .foregroundStyle(isSelected ? .white : AyuWalkTheme.ink)
            .padding(.horizontal, AyuWalkSpacing.sm + 1)
            .padding(.vertical, AyuWalkSpacing.xs)
            .background {
                if isSelected {
                    Capsule()
                        .fill(tint)

                    Image.awPaperCardSurface
                        .resizable(resizingMode: .tile)
                        .opacity(AyuWalkTexture.cardOpacity * 0.6)
                        .blendMode(.softLight)
                        .clipShape(Capsule())
                } else {
                    Capsule()
                        .fill(AyuWalkTheme.chipSurface)

                    Image.awPaperCardSurface
                        .resizable(resizingMode: .tile)
                        .opacity(AyuWalkTexture.cardOpacity)
                        .blendMode(.multiply)
                        .clipShape(Capsule())
                }
            }
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelected ? Color.clear : AyuWalkTheme.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct AWMetricTile: View {
    let title: String
    let value: String
    var tint: Color = AyuWalkTheme.secondaryAccent

    var body: some View {
        VStack(alignment: .leading, spacing: AyuWalkSpacing.xxs) {
            Text(title)
                .font(AyuWalkTypography.microStrong)
                .foregroundStyle(AyuWalkTheme.mutedInk)
            Text(value)
                .font(AyuWalkTypography.metric)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AyuWalkSpacing.md)
        .padding(.vertical, AyuWalkSpacing.md)
        .background {
            AyuWalkTheme.surface
            tint.opacity(0.045)

            Image.awPaperCardSurface
                .resizable(resizingMode: .tile)
                .opacity(AyuWalkTexture.cardOpacity)
                .blendMode(.multiply)
        }
        .clipShape(RoundedRectangle(cornerRadius: AyuWalkRadii.smallCard, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AyuWalkRadii.smallCard, style: .continuous)
                .stroke(tint.opacity(0.10), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: AyuWalkRadii.smallCard, style: .continuous))
    }
}
