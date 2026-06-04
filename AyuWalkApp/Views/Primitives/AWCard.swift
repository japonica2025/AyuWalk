import SwiftUI

struct AWIconBadge: View {
    let systemImage: String
    var tint: Color = AyuWalkTheme.accent
    var size: CGFloat = 38

    var body: some View {
        Image(systemName: systemImage)
            .font(AyuWalkTypography.icon(size: size * 0.42))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(tint)
            .clipShape(Circle())
    }
}

struct AWSectionHeader: View {
    let title: String
    var subtitle: String?
    var accessory: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.xxs - 1) {
                Text(title)
                    .font(AyuWalkTypography.sectionTitle)
                    .foregroundStyle(AyuWalkTheme.ink)

                if let subtitle {
                    Text(subtitle)
                        .font(AyuWalkTypography.caption)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                }
            }

            Spacer()

            if let accessory {
                Text(accessory)
                    .font(AyuWalkTypography.eyebrow)
                    .foregroundStyle(AyuWalkTheme.secondaryAccent)
            }
        }
    }
}

struct AWInfoRow: View {
    let title: String
    var subtitle: String?
    var systemImage: String
    var tint: Color = AyuWalkTheme.accent
    var trailingSystemImage: String? = "chevron.right"

    var body: some View {
        HStack(spacing: AyuWalkSpacing.md) {
            AWIconBadge(systemImage: systemImage, tint: tint, size: 38)

            VStack(alignment: .leading, spacing: AyuWalkSpacing.xxxs) {
                Text(title)
                    .font(AyuWalkTypography.cardTitle)
                    .foregroundStyle(AyuWalkTheme.ink)

                if let subtitle {
                    Text(subtitle)
                        .font(AyuWalkTypography.caption)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                        .lineLimit(2)
                }
            }

            Spacer()

            if let trailingSystemImage {
                Image(systemName: trailingSystemImage)
                    .font(AyuWalkTypography.captionStrong)
                    .foregroundStyle(AyuWalkTheme.mutedInk)
            }
        }
    }
}

struct AWPanel<Content: View>: View {
    var background: Color = AyuWalkTheme.surface
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(AyuWalkSpacing.lg)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AyuWalkTheme.panelRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AyuWalkTheme.panelRadius, style: .continuous)
                    .stroke(AyuWalkTheme.hairline, lineWidth: 1)
            }
            .shadow(color: AyuWalkTheme.softShadow, radius: 18, x: 0, y: 8)
    }
}

struct AWEmptyState: View {
    let title: String
    var subtitle: String?
    var systemImage: String = "sparkles"

    var body: some View {
        VStack(spacing: AyuWalkSpacing.sm) {
            Image(systemName: systemImage)
                .font(AyuWalkTypography.icon(size: 24, weight: .bold))
                .foregroundStyle(AyuWalkTheme.accent)

            Text(title)
                .font(AyuWalkTypography.cardTitle)
                .foregroundStyle(AyuWalkTheme.ink)

            if let subtitle {
                Text(subtitle)
                    .font(AyuWalkTypography.caption)
                    .foregroundStyle(AyuWalkTheme.mutedInk)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AyuWalkSpacing.xl)
        .background(AyuWalkTheme.paper)
        .clipShape(RoundedRectangle(cornerRadius: AyuWalkRadii.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AyuWalkRadii.card, style: .continuous)
                .stroke(AyuWalkTheme.border, lineWidth: 1)
        }
    }
}

struct AWCardChrome<Content: View>: View {
    var background: Color = AyuWalkTheme.paper
    var cornerRadius: CGFloat = AyuWalkRadii.card
    var padding: CGFloat = AyuWalkSpacing.lg
    var showsShadow = false
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AyuWalkTheme.border, lineWidth: 1)
            }
            .shadow(color: showsShadow ? AyuWalkShadow.card : .clear, radius: 14, y: 8)
    }
}
