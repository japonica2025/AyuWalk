import SwiftUI

struct AWMapMarkerBadge: View {
    var text: String?
    var systemImage: String?
    var tint: Color = AyuWalkTheme.accent
    var size: CGFloat = 30

    var body: some View {
        Group {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(AyuWalkTypography.icon(size: size * 0.42, weight: .bold))
            } else if let text {
                Text(text)
                    .font(AyuWalkTypography.captionStrong)
            }
        }
        .foregroundStyle(.white)
        .frame(width: size, height: size)
        .background(tint)
        .clipShape(Circle())
        .shadow(color: AyuWalkTheme.ink.opacity(0.16), radius: 8, y: 4)
    }
}

struct AWMapFloatingLabel: View {
    let text: String
    var font: Font = AyuWalkTypography.microStrong

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(AyuWalkTheme.ink)
            .lineLimit(1)
            .padding(.horizontal, AyuWalkSpacing.xs)
            .padding(.vertical, AyuWalkSpacing.xxs)
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
                    .stroke(AyuWalkTheme.hairline, lineWidth: 1)
            }
    }
}

struct AWRouteDrawerSurface<Content: View>: View {
    var cornerRadius: CGFloat = AyuWalkTheme.panelRadius
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(AyuWalkSpacing.lg)
            .background {
                AyuWalkTheme.surface.opacity(0.98)

                Image.awPaperCardSurface
                    .resizable()
                    .scaledToFill()
                    .opacity(AyuWalkTexture.cardOpacity)
                    .blendMode(.multiply)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AyuWalkTheme.hairline, lineWidth: 1)
            }
            .shadow(color: AyuWalkTheme.softShadow, radius: 20, x: 0, y: 10)
    }
}
