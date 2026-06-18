import SwiftUI

struct AWPaperSurface<Content: View>: View {
    var background: Color = AyuWalkTheme.surface
    var tint: Color = AyuWalkTheme.accent
    var cornerRadius: CGFloat = AyuWalkRadii.card
    var padding: CGFloat = AyuWalkSpacing.lg
    var borderOpacity: Double = 0.12
    var shadowRadius: CGFloat = 0
    var shadowY: CGFloat = 0
    var showsPaperTexture = true
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                background

                if showsPaperTexture {
                    Image.awPaperCardSurface
                        .resizable()
                        .scaledToFill()
                        .opacity(AyuWalkTexture.cardOpacity)
                        .blendMode(.multiply)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(tint.opacity(borderOpacity), lineWidth: 1)
            }
            .shadow(color: shadowRadius > 0 ? AyuWalkTheme.softShadow : .clear, radius: shadowRadius, y: shadowY)
    }
}

struct AWPaperSection<Content: View>: View {
    var title: String
    var subtitle: String?
    var accessory: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AyuWalkSpacing.md) {
            AWSectionHeader(title: title, subtitle: subtitle, accessory: accessory)
            content
        }
    }
}

private struct AWPaperInsetBackground: ViewModifier {
    var cornerRadius: CGFloat
    var fill: Color
    var borderTint: Color
    var borderOpacity: Double
    var textureOpacity: Double

    func body(content: Content) -> some View {
        content
            .background {
                fill

                Image.awPaperCardSurface
                    .resizable()
                    .scaledToFill()
                    .opacity(textureOpacity)
                    .blendMode(.multiply)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderTint.opacity(borderOpacity), lineWidth: 1)
            }
    }
}

private struct AWPaperCapsuleBackground: ViewModifier {
    var fill: Color
    var borderTint: Color
    var borderOpacity: Double
    var textureOpacity: Double

    func body(content: Content) -> some View {
        content
            .background {
                Capsule()
                    .fill(fill)

                Image.awPaperCardSurface
                    .resizable()
                    .scaledToFill()
                    .opacity(textureOpacity)
                    .blendMode(.multiply)
                    .clipShape(Capsule())
            }
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(borderTint.opacity(borderOpacity), lineWidth: 1)
            }
    }
}

extension View {
    func awPaperInsetBackground(
        cornerRadius: CGFloat,
        fill: Color = AyuWalkTheme.surface,
        borderTint: Color = AyuWalkTheme.accent,
        borderOpacity: Double = 0.08,
        textureOpacity: Double = AyuWalkTexture.cardOpacity
    ) -> some View {
        modifier(
            AWPaperInsetBackground(
                cornerRadius: cornerRadius,
                fill: fill,
                borderTint: borderTint,
                borderOpacity: borderOpacity,
                textureOpacity: textureOpacity
            )
        )
    }

    func awPaperCapsuleBackground(
        fill: Color = AyuWalkTheme.chipSurface,
        borderTint: Color = AyuWalkTheme.accent,
        borderOpacity: Double = 0.10,
        textureOpacity: Double = AyuWalkTexture.cardOpacity
    ) -> some View {
        modifier(
            AWPaperCapsuleBackground(
                fill: fill,
                borderTint: borderTint,
                borderOpacity: borderOpacity,
                textureOpacity: textureOpacity
            )
        )
    }
}

struct AWDecorDivider: View {
    var tint: Color = AyuWalkTheme.accent
    var style: Style = .dots

    enum Style {
        case dots
        case stitchedLeaf
    }

    var body: some View {
        Group {
            switch style {
            case .dots:
                HStack(spacing: AyuWalkSpacing.xs) {
                    Circle()
                        .fill(tint.opacity(0.42))
                        .frame(width: 4, height: 4)

                    Rectangle()
                        .fill(tint.opacity(0.14))
                        .frame(height: 1)

                    Circle()
                        .fill(tint.opacity(0.28))
                        .frame(width: 4, height: 4)
                }
            case .stitchedLeaf:
                HStack(spacing: AyuWalkSpacing.sm) {
                    stitchedLine
                    leafMark
                    stitchedLine
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var stitchedLine: some View {
        Rectangle()
            .stroke(
                tint.opacity(0.22),
                style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [5, 6])
            )
            .frame(height: 1)
    }

    private var leafMark: some View {
        ZStack {
            Capsule()
                .stroke(tint.opacity(0.28), lineWidth: 1)
                .frame(width: 8, height: 14)
                .rotationEffect(.degrees(-34))

            Capsule()
                .stroke(tint.opacity(0.22), lineWidth: 1)
                .frame(width: 8, height: 14)
                .rotationEffect(.degrees(34))
                .offset(x: 6)

            Rectangle()
                .fill(tint.opacity(0.22))
                .frame(width: 1, height: 13)
                .offset(x: 3, y: 4)
        }
        .frame(width: 24, height: 18)
    }
}

struct AWPaperTab: View {
    let title: String
    var systemImage: String?
    var tint: Color = AyuWalkTheme.accent

    var body: some View {
        HStack(spacing: AyuWalkSpacing.xxs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(AyuWalkTypography.microStrong)
            }

            Text(title)
                .font(AyuWalkTypography.captionStrong)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, AyuWalkSpacing.md)
        .padding(.vertical, AyuWalkSpacing.xs)
        .background {
            AyuWalkTheme.chipSurface
            tint.opacity(0.035)
        }
        .clipShape(RoundedRectangle(cornerRadius: AyuWalkRadii.smallCard, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AyuWalkRadii.smallCard, style: .continuous)
                .stroke(tint.opacity(0.14), lineWidth: 1)
        }
    }
}

struct AWStickerIconTray: View {
    var systemImages: [String]
    var tint: Color = AyuWalkTheme.accent

    var body: some View {
        HStack(spacing: AyuWalkSpacing.xs) {
            ForEach(systemImages, id: \.self) { systemImage in
                Image(systemName: systemImage)
                    .font(AyuWalkTypography.icon(size: 13, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: AyuWalkSize.compactIconButton, height: AyuWalkSize.compactIconButton)
                    .background(AyuWalkTheme.surface)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(tint.opacity(0.14), lineWidth: 1)
                    }
            }
        }
        .padding(AyuWalkSpacing.xxs)
        .background(AyuWalkTheme.chipSurface.opacity(0.82))
        .clipShape(Capsule())
    }
}

struct AWPhotoFrame<Content: View>: View {
    var cornerRadius: CGFloat = AyuWalkRadii.card
    var tint: Color = AyuWalkTheme.accent
    var tape: Tape? = nil
    @ViewBuilder let content: Content

    enum Tape {
        case rose
        case sage
        case cream
    }

    var body: some View {
        AWPaperSurface(
            background: AyuWalkTheme.surface,
            tint: tint,
            cornerRadius: cornerRadius,
            padding: AyuWalkSpacing.xs,
            borderOpacity: 0.10,
            shadowRadius: 10,
            shadowY: 5
        ) {
            content
                .clipShape(RoundedRectangle(cornerRadius: max(cornerRadius - 6, 8), style: .continuous))
        }
        .overlay(alignment: .top) {
            if let tape {
                tape.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 24)
                    .rotationEffect(tape.rotation)
                    .opacity(tape.opacity)
                    .offset(y: -13)
                    .allowsHitTesting(false)
            }
        }
    }
}

private extension AWPhotoFrame.Tape {
    var image: Image {
        switch self {
        case .rose:
            return .awWashiTapeRose
        case .sage:
            return .awWashiTapeSage
        case .cream:
            return .awWashiTapeCream
        }
    }

    var rotation: Angle {
        switch self {
        case .rose:
            return .degrees(-3)
        case .sage:
            return .degrees(2)
        case .cream:
            return .degrees(-1)
        }
    }

    var opacity: Double {
        switch self {
        case .rose:
            return 0.46
        case .sage:
            return 0.40
        case .cream:
            return 0.50
        }
    }
}

struct AWCalloutNote: View {
    let text: String
    var systemImage: String = "sparkles"
    var tint: Color = AyuWalkTheme.accent

    var body: some View {
        HStack(alignment: .top, spacing: AyuWalkSpacing.sm) {
            Image(systemName: systemImage)
                .font(AyuWalkTypography.captionStrong)
                .foregroundStyle(tint)
                .padding(.top, 2)

            Text(text)
                .font(AyuWalkTypography.caption)
                .foregroundStyle(AyuWalkTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AyuWalkSpacing.md)
        .background {
            AyuWalkTheme.chipSurface.opacity(0.72)

            Image.awPaperCardSurface
                .resizable()
                .scaledToFill()
                .opacity(AyuWalkTexture.cardOpacity)
                .blendMode(.multiply)
        }
        .clipShape(RoundedRectangle(cornerRadius: AyuWalkRadii.smallCard, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AyuWalkRadii.smallCard, style: .continuous)
                .stroke(tint.opacity(0.10), lineWidth: 1)
        }
    }
}

struct AWInlineActionRow: View {
    let title: String
    var subtitle: String?
    var systemImage: String
    var tint: Color = AyuWalkTheme.accent
    var trailingSystemImage: String = "chevron.right"

    var body: some View {
        HStack(spacing: AyuWalkSpacing.md) {
            AWIconBadge(systemImage: systemImage, tint: tint, size: 38)

            VStack(alignment: .leading, spacing: AyuWalkSpacing.xxxs) {
                Text(title)
                    .font(AyuWalkTypography.bodyStrong)
                    .foregroundStyle(AyuWalkTheme.ink)

                if let subtitle {
                    Text(subtitle)
                        .font(AyuWalkTypography.caption)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: trailingSystemImage)
                .font(AyuWalkTypography.icon(size: 12, weight: .bold))
                .foregroundStyle(AyuWalkTheme.mutedInk)
        }
    }
}

struct AWFormPaperField<Content: View>: View {
    var tint: Color = AyuWalkTheme.secondaryAccent
    @ViewBuilder let content: Content

    var body: some View {
        AWPaperSurface(
            background: AyuWalkTheme.paper,
            tint: tint,
            cornerRadius: AyuWalkTheme.cardRadius,
            padding: AyuWalkSpacing.md,
            borderOpacity: 0.12,
            shadowRadius: 0,
            showsPaperTexture: false
        ) {
            content
        }
    }
}

struct AWEmptyPaperState: View {
    let title: String
    var subtitle: String?
    var systemImage: String = "sparkles"
    var tint: Color = AyuWalkTheme.accent

    var body: some View {
        AWPaperSurface(tint: tint, cornerRadius: AyuWalkRadii.card, padding: AyuWalkSpacing.xl, borderOpacity: 0.12) {
            VStack(spacing: AyuWalkSpacing.sm) {
                AWStickerIconTray(systemImages: [systemImage], tint: tint)

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
        }
    }
}

struct AWCornerSticker: View {
    var systemImage: String = "heart.fill"
    var tint: Color = AyuWalkTheme.accent

    var body: some View {
        Image(systemName: systemImage)
            .font(AyuWalkTypography.icon(size: 12, weight: .bold))
            .foregroundStyle(tint)
            .padding(AyuWalkSpacing.xs)
            .background {
                Circle()
                    .fill(AyuWalkTheme.chipSurface)

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
                    .stroke(tint.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: tint.opacity(0.08), radius: 6, y: 3)
            .rotationEffect(.degrees(-4))
            .allowsHitTesting(false)
    }
}

struct AWHandwrittenScribble: View {
    var tint: Color = AyuWalkTheme.accent

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 8))
            path.addCurve(to: CGPoint(x: 34, y: 9), control1: CGPoint(x: 9, y: 1), control2: CGPoint(x: 20, y: 15))
            path.addCurve(to: CGPoint(x: 72, y: 8), control1: CGPoint(x: 46, y: 2), control2: CGPoint(x: 58, y: 14))
        }
        .stroke(tint.opacity(0.26), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        .frame(width: 72, height: 16)
        .allowsHitTesting(false)
    }
}
