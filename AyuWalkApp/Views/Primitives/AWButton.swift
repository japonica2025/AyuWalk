import SwiftUI

struct AWPrimaryButton: View {
    let title: String
    var systemImage: String?
    var tint: Color = AyuWalkTheme.accent
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AyuWalkSpacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(AyuWalkTypography.button)
                }

                Text(title)
                    .font(AyuWalkTypography.button)

                Spacer()

                Image(systemName: "arrow.right")
                    .font(AyuWalkTypography.metric)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, AyuWalkSpacing.lg)
            .padding(.vertical, AyuWalkSpacing.lg - 2)
            .background {
                RoundedRectangle(cornerRadius: AyuWalkRadii.card, style: .continuous)
                    .fill(tint)

                Image.awPaperCardSurface
                    .resizable()
                    .scaledToFill()
                    .opacity(AyuWalkTexture.cardOpacity * 0.6)
                    .blendMode(.softLight)
                    .clipShape(RoundedRectangle(cornerRadius: AyuWalkRadii.card, style: .continuous))
            }
            .clipShape(RoundedRectangle(cornerRadius: AyuWalkRadii.card, style: .continuous))
            .shadow(color: tint.opacity(0.16), radius: 14, y: 7)
        }
        .buttonStyle(.plain)
    }
}

struct AWActionCapsuleButton: View {
    let title: String
    let systemImage: String
    var tint: Color = AyuWalkTheme.accent
    var isProminent = false
    var fillsWidth = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AyuWalkSpacing.xxs + 1) {
                Image(systemName: systemImage)
                    .font(AyuWalkTypography.captionStrong)
                Text(title)
                    .font(AyuWalkTypography.captionStrong)
            }
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .foregroundStyle(isProminent ? .white : tint)
            .padding(.horizontal, AyuWalkSpacing.md)
            .padding(.vertical, AyuWalkSpacing.sm)
            .background {
                if isProminent {
                    tint

                    Image.awPaperCardSurface
                        .resizable()
                        .scaledToFill()
                        .opacity(AyuWalkTexture.cardOpacity * 0.6)
                        .blendMode(.softLight)
                } else {
                    AyuWalkTheme.chipSurface

                    Image.awPaperCardSurface
                        .resizable()
                        .scaledToFill()
                        .opacity(AyuWalkTexture.cardOpacity)
                        .blendMode(.multiply)
                }
            }
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(isProminent ? Color.clear : tint.opacity(0.16), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct AWPlainIconButton: View {
    let systemImage: String
    var label: String
    var tint: Color = AyuWalkTheme.ink
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(AyuWalkTypography.icon(size: 18))
                .foregroundStyle(tint)
                .frame(width: AyuWalkSize.iconButton, height: AyuWalkSize.iconButton)
                .awPaperCircleBackground(
                    fill: AyuWalkTheme.surface,
                    borderTint: tint,
                    borderOpacity: 0.14
                )
                .shadow(color: AyuWalkTheme.softShadow, radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
