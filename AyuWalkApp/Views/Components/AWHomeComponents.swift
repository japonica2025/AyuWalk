import SwiftUI

struct AWScrapbookMetricTile: View {
    let title: String
    let value: String
    var systemImage: String
    var tint: Color = AyuWalkTheme.secondaryAccent

    var body: some View {
        VStack(alignment: .leading, spacing: AyuWalkSpacing.xs) {
            HStack(spacing: AyuWalkSpacing.xxs) {
                Image(systemName: systemImage)
                    .font(AyuWalkTypography.icon(size: 12, weight: .bold))
                Text(title)
                    .font(AyuWalkTypography.microStrong)
            }
            .foregroundStyle(AyuWalkTheme.mutedInk)

            Text(value)
                .font(AyuWalkTypography.metric)
                .foregroundStyle(tint)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
        .padding(.horizontal, AyuWalkSpacing.md)
        .padding(.vertical, AyuWalkSpacing.md)
        .background {
            AyuWalkTheme.surface
            tint.opacity(0.035)

            Image.awPaperCardSurface
                .resizable()
                .scaledToFill()
                .opacity(AyuWalkTexture.cardOpacity)
                .blendMode(.multiply)
        }
        .clipShape(RoundedRectangle(cornerRadius: AyuWalkRadii.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AyuWalkRadii.card, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: AyuWalkRadii.card, style: .continuous))
    }
}

struct AWTripCoverCard<RoutePreview: View>: View {
    let brandTitle: String
    let brandSubtitle: String
    let title: String
    let message: String
    let statusText: String
    let statusSystemImage: String
    var statusTint: Color = AyuWalkTheme.secondaryAccent
    var isStatusFilled = false
    let destination: String
    let dateLabel: String
    let dayLabel: String
    let budgetSummary: String
    let packingSummary: String
    let nextStopTitle: String
    var onOpenTrips: () -> Void
    var onAIAdjust: () -> Void
    var onOpenBudget: () -> Void
    var onOpenPacking: () -> Void
    var onJumpNext: () -> Void
    var onOpenRouteMap: () -> Void
    @ViewBuilder var routePreview: RoutePreview

    var body: some View {
        AWPanel(background: AyuWalkTheme.surface, showsPaperTexture: true) {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.lg) {
                header
                titleBlock
                metadataChips
                controls
                metricTiles
                routeButton
            }
        }
        .overlay(alignment: .topLeading) {
            AWWashiTape()
                .offset(x: 30, y: -20)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.xxxs) {
                Text(brandTitle)
                    .font(AyuWalkTypography.brand)
                    .foregroundStyle(AyuWalkTheme.accent)
                Text(brandSubtitle)
                    .font(AyuWalkTypography.captionStrong)
                    .foregroundStyle(AyuWalkTheme.mutedInk)
            }

            Spacer()

            AWPlainIconButton(
                systemImage: "rectangle.stack.fill",
                label: "打开行程库",
                tint: AyuWalkTheme.secondaryAccent,
                action: onOpenTrips
            )

            AWStatusPill(
                text: statusText,
                systemImage: statusSystemImage,
                tint: statusTint,
                isFilled: isStatusFilled
            )
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: AyuWalkSpacing.xs) {
            Text(title)
                .font(AyuWalkTypography.screenTitle)
                .foregroundStyle(AyuWalkTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.78)

            Text(message)
                .font(AyuWalkTypography.body)
                .foregroundStyle(AyuWalkTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var metadataChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AyuWalkSpacing.xs) {
                AWStatusPill(text: destination, systemImage: "mappin.and.ellipse", tint: AyuWalkTheme.accent)
                AWStatusPill(text: dateLabel, systemImage: "calendar", tint: AyuWalkTheme.secondaryAccent)
                AWStatusPill(text: dayLabel, systemImage: "rectangle.stack.fill", tint: AyuWalkTheme.secondaryAccent)
            }
        }
    }

    private var controls: some View {
        AWActionCapsuleButton(
            title: "AI 调整",
            systemImage: "sparkles",
            tint: AyuWalkTheme.accent,
            isProminent: false,
            action: onAIAdjust
        )
    }

    private var metricTiles: some View {
        HStack(spacing: AyuWalkSpacing.sm) {
            Button(action: onOpenBudget) {
                AWScrapbookMetricTile(
                    title: "预算规划",
                    value: budgetSummary,
                    systemImage: "creditcard.fill",
                    tint: AyuWalkTheme.secondaryAccent
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("打开预算规划")

            Button(action: onOpenPacking) {
                AWScrapbookMetricTile(
                    title: "行李清单",
                    value: packingSummary,
                    systemImage: "bag.fill",
                    tint: AyuWalkTheme.accent
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("打开行李清单")

            Button(action: onJumpNext) {
                AWScrapbookMetricTile(
                    title: "下一站",
                    value: nextStopTitle,
                    systemImage: "arrow.turn.down.right",
                    tint: AyuWalkTheme.ink
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("跳到下一站")
        }
    }

    private var routeButton: some View {
        Button(action: onOpenRouteMap) {
            routePreview
        }
        .buttonStyle(.plain)
    }
}

struct AWHomeMapCard<Accessory: View, Content: View, Footer: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var accessory: Accessory
    @ViewBuilder var content: Content
    @ViewBuilder var footer: Footer

    var body: some View {
        AWPaperSurface(
            background: AyuWalkTheme.surface,
            tint: AyuWalkTheme.accent,
            cornerRadius: AyuWalkTheme.panelRadius,
            padding: AyuWalkSpacing.lg,
            borderOpacity: 0.10,
            shadowRadius: 18,
            shadowY: 8
        ) {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.md + 2) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: AyuWalkSpacing.xxs - 1) {
                        Text(title)
                            .font(AyuWalkTypography.sectionTitle)
                            .foregroundStyle(AyuWalkTheme.ink)
                        Text(subtitle)
                            .font(AyuWalkTypography.caption)
                            .foregroundStyle(AyuWalkTheme.mutedInk)
                    }

                    Spacer()

                    accessory
                }

                AWPhotoFrame(cornerRadius: AyuWalkRadii.card, tint: AyuWalkTheme.accent) {
                    content
                }

                footer
            }
        }
    }
}

struct AWQuickActionCard: View {
    let title: String
    let value: String
    let detail: String
    var systemImage: String
    var tint: Color = AyuWalkTheme.accent

    var body: some View {
        AWPaperSurface(
            background: AyuWalkTheme.surface,
            tint: tint,
            cornerRadius: AyuWalkRadii.card,
            padding: AyuWalkSpacing.md + 2,
            borderOpacity: 0.12,
            shadowRadius: 8,
            shadowY: 4
        ) {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.sm) {
                HStack {
                    AWIconBadge(systemImage: systemImage, tint: tint, size: 34)
                    Spacer()
                    AWCornerSticker(systemImage: "circle.fill", tint: tint)
                        .opacity(0.72)
                }

                Text(title)
                    .font(AyuWalkTypography.captionStrong)
                    .foregroundStyle(AyuWalkTheme.mutedInk)

                Text(value)
                    .font(AyuWalkTypography.sectionTitle)
                    .foregroundStyle(AyuWalkTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                AWDecorDivider(tint: tint)

                Text(detail)
                    .font(AyuWalkTypography.micro)
                    .foregroundStyle(AyuWalkTheme.mutedInk)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        }
    }
}
