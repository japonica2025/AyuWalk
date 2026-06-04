import SwiftUI

struct AWStatusPill: View {
    let text: String
    var systemImage: String?
    var tint: Color = AyuWalkTheme.secondaryAccent
    var isFilled = false

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(AyuWalkTypography.microStrong)
            }

            Text(text)
                .lineLimit(1)
        }
        .font(AyuWalkTypography.captionStrong)
        .foregroundStyle(isFilled ? .white : tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isFilled ? tint : tint.opacity(0.10))
        .clipShape(Capsule())
    }
}

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
            VStack(alignment: .leading, spacing: 4) {
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

struct AWPanel<Content: View>: View {
    var background: Color = AyuWalkTheme.surface
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AyuWalkTheme.panelRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AyuWalkTheme.panelRadius, style: .continuous)
                    .stroke(AyuWalkTheme.hairline, lineWidth: 1)
            }
            .shadow(color: AyuWalkTheme.softShadow, radius: 18, x: 0, y: 8)
    }
}

struct AWMetricTile: View {
    let title: String
    let value: String
    var tint: Color = AyuWalkTheme.secondaryAccent

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
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
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct AWPrimaryButton: View {
    let title: String
    var systemImage: String?
    var tint: Color = AyuWalkTheme.secondaryAccent
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
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
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(tint)
            .clipShape(RoundedRectangle(cornerRadius: AyuWalkTheme.cardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct AWActionCapsuleButton: View {
    let title: String
    let systemImage: String
    var tint: Color = AyuWalkTheme.accent
    var isProminent = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(AyuWalkTypography.captionStrong)
                Text(title)
                    .font(AyuWalkTypography.captionStrong)
            }
            .foregroundStyle(isProminent ? .white : tint)
            .padding(.horizontal, AyuWalkSpacing.md)
            .padding(.vertical, AyuWalkSpacing.sm)
            .background(isProminent ? tint : AyuWalkTheme.paper)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(isProminent ? Color.clear : AyuWalkTheme.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
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
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(AyuWalkTypography.microStrong)
                }

                Text(title)
                    .font(AyuWalkTypography.captionStrong)
            }
            .foregroundStyle(isSelected ? .white : AyuWalkTheme.ink)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(isSelected ? tint : AyuWalkTheme.paper)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(AyuWalkTheme.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
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

            VStack(alignment: .leading, spacing: 3) {
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
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AyuWalkTheme.border, lineWidth: 1)
            }
            .shadow(color: showsShadow ? AyuWalkShadow.card : .clear, radius: 14, y: 8)
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
                .frame(width: 40, height: 40)
                .background(AyuWalkTheme.surface)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(AyuWalkTheme.hairline, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct AWFloatingTabItem<Selection: Hashable>: Identifiable {
    let id: Selection
    let label: String
    let systemImage: String
}

struct AWFloatingTabBar<Selection: Hashable>: View {
    @Binding var selection: Selection
    let items: [AWFloatingTabItem<Selection>]
    let actionLabel: String
    let actionSystemImage: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            if items.count == 2 {
                tabButton(items[0])
                actionButton
                tabButton(items[1])
            } else {
                ForEach(items) { item in
                    tabButton(item)
                }
                actionButton
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 5)
        .background {
            Capsule()
                .fill(AyuWalkTheme.paper.opacity(0.86))
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(AyuWalkTheme.border, lineWidth: 1)
                }
        }
        .shadow(color: Color.black.opacity(0.10), radius: 12, y: 6)
    }

    private var actionButton: some View {
        Button(action: action) {
            Image(systemName: actionSystemImage)
                .font(AyuWalkTypography.icon(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(AyuWalkTheme.accent)
                .clipShape(Circle())
                .shadow(color: AyuWalkTheme.accent.opacity(0.22), radius: 9, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(actionLabel)
        .offset(y: -11)
    }

    private func tabButton(_ item: AWFloatingTabItem<Selection>) -> some View {
        Button {
            selection = item.id
        } label: {
            VStack(spacing: 2) {
                Image(systemName: item.systemImage)
                    .font(AyuWalkTypography.icon(size: 17))

                Text(item.label)
                    .font(AyuWalkTypography.microStrong)
            }
            .foregroundStyle(selection == item.id ? AyuWalkTheme.accent : AyuWalkTheme.ink.opacity(0.78))
            .frame(width: 72, height: 35)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.label)
    }
}
