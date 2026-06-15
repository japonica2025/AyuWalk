import SwiftUI

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
        .padding(.horizontal, AyuWalkSpacing.md)
        .padding(.top, AyuWalkSpacing.xs)
        .padding(.bottom, AyuWalkSpacing.xs)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(AyuWalkTheme.surface.opacity(0.96))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                .overlay {
                    Image.awPaperCardSurface
                        .resizable()
                        .scaledToFill()
                        .opacity(AyuWalkTexture.cardOpacity)
                        .blendMode(.multiply)
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(AyuWalkTheme.border, lineWidth: 1)
                }
        }
        .shadow(color: AyuWalkShadow.floating, radius: 18, y: 8)
        .overlay(alignment: .topLeading) {
            Image.awWashiTapeCream
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 18)
                .rotationEffect(.degrees(-5))
                .opacity(0.50)
                .offset(x: 28, y: -8)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .topTrailing) {
            Image.awWashiTapeRose
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 16)
                .rotationEffect(.degrees(7))
                .opacity(0.42)
                .offset(x: -30, y: -7)
                .allowsHitTesting(false)
        }
    }

    private var actionButton: some View {
        Button(action: action) {
            Image(systemName: actionSystemImage)
                .font(AyuWalkTypography.icon(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: AyuWalkSize.largeIconButton + 2, height: AyuWalkSize.largeIconButton + 2)
                .background(AyuWalkTheme.accent)
                .clipShape(Circle())
                .shadow(color: AyuWalkTheme.accent.opacity(0.20), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(actionLabel)
        .offset(y: -11)
    }

    private func tabButton(_ item: AWFloatingTabItem<Selection>) -> some View {
        Button {
            selection = item.id
        } label: {
            VStack(spacing: AyuWalkSpacing.xxxs - 1) {
                Image(systemName: item.systemImage)
                    .font(AyuWalkTypography.icon(size: 17))

                Text(item.label)
                    .font(AyuWalkTypography.microStrong)
            }
            .foregroundStyle(selection == item.id ? AyuWalkTheme.accent : AyuWalkTheme.ink.opacity(0.78))
            .frame(width: AyuWalkSize.floatingTabWidth, height: AyuWalkSize.floatingTabHeight + 2)
            .background {
                if selection == item.id {
                    RoundedRectangle(cornerRadius: AyuWalkRadii.smallCard, style: .continuous)
                        .fill(AyuWalkTheme.chipSurface.opacity(0.74))
                        .overlay {
                            RoundedRectangle(cornerRadius: AyuWalkRadii.smallCard, style: .continuous)
                                .stroke(AyuWalkTheme.accent.opacity(0.10), lineWidth: 1)
                        }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.label)
    }
}
