import SwiftUI

struct AWPrimaryButton: View {
    let title: String
    var systemImage: String?
    var tint: Color = AyuWalkTheme.secondaryAccent
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
            HStack(spacing: AyuWalkSpacing.xxs + 1) {
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
