import SwiftUI

struct AWStatusPill: View {
    let text: String
    var systemImage: String?
    var tint: Color = AyuWalkTheme.secondaryAccent
    var isFilled = false

    var body: some View {
        HStack(spacing: AyuWalkSpacing.xxs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(AyuWalkTypography.microStrong)
            }

            Text(text)
                .lineLimit(1)
        }
        .font(AyuWalkTypography.captionStrong)
        .foregroundStyle(isFilled ? .white : tint)
        .padding(.horizontal, AyuWalkSpacing.sm)
        .padding(.vertical, AyuWalkSpacing.xs - 1)
        .background(isFilled ? tint : tint.opacity(0.10))
        .clipShape(Capsule())
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
        .padding(.vertical, AyuWalkSpacing.sm + 1)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AyuWalkRadii.smallCard, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: AyuWalkRadii.smallCard, style: .continuous))
    }
}
