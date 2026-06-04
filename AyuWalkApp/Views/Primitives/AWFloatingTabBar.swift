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
        .padding(.top, AyuWalkSpacing.xxs - 1)
        .padding(.bottom, AyuWalkSpacing.xxs)
        .background {
            Capsule()
                .fill(AyuWalkTheme.paper.opacity(0.86))
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(AyuWalkTheme.border, lineWidth: 1)
                }
        }
        .shadow(color: AyuWalkShadow.floating, radius: 12, y: 6)
    }

    private var actionButton: some View {
        Button(action: action) {
            Image(systemName: actionSystemImage)
                .font(AyuWalkTypography.icon(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: AyuWalkSize.largeIconButton, height: AyuWalkSize.largeIconButton)
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
            VStack(spacing: AyuWalkSpacing.xxxs - 1) {
                Image(systemName: item.systemImage)
                    .font(AyuWalkTypography.icon(size: 17))

                Text(item.label)
                    .font(AyuWalkTypography.microStrong)
            }
            .foregroundStyle(selection == item.id ? AyuWalkTheme.accent : AyuWalkTheme.ink.opacity(0.78))
            .frame(width: AyuWalkSize.floatingTabWidth, height: AyuWalkSize.floatingTabHeight)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.label)
    }
}
