import AyuWalkCore
import SwiftUI

struct JournalModulePickerView: View {
    let page: JournalPage
    let isSelected: (UUID) -> Bool
    let onToggle: (UUID) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AyuWalkTheme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(page.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AyuWalkTheme.ink)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                        VStack(spacing: 10) {
                            ForEach(page.blocks) { block in
                                Button {
                                    onToggle(block.id)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: isSelected(block.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 23, weight: .semibold))
                                            .foregroundStyle(isSelected(block.id) ? AyuWalkTheme.secondaryAccent : AyuWalkTheme.mutedInk)

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(block.title ?? block.kind.displayName)
                                                .font(.body.weight(.semibold))
                                                .foregroundStyle(AyuWalkTheme.ink)

                                            Text(block.kind.displayName)
                                                .font(.caption)
                                                .foregroundStyle(AyuWalkTheme.mutedInk)
                                        }

                                        Spacer()

                                        if block.isDefaultSelected {
                                            Text("默认")
                                                .font(.caption2.weight(.bold))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 7)
                                                .padding(.vertical, 4)
                                                .background(AyuWalkTheme.secondaryAccent)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    .padding(14)
                                    .awPaperInsetBackground(
                                        cornerRadius: 18,
                                        fill: AyuWalkTheme.paper,
                                        borderTint: isSelected(block.id) ? AyuWalkTheme.secondaryAccent : AyuWalkTheme.accent,
                                        borderOpacity: isSelected(block.id) ? 0.22 : 0.10
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(block.title ?? block.kind.displayName)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("选择模块")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private extension JournalBlockKind {
    var displayName: String {
        switch self {
        case .title:
            return "标题"
        case .dateLocation:
            return "日期地点"
        case .photo:
            return "照片"
        case .text:
            return "文字记录"
        case .mapSnapshot:
            return "地图快照"
        case .routeSummary:
            return "路线概览"
        case .timeline:
            return "时间线"
        case .placeHighlights:
            return "地点亮点"
        case .budgetSummary:
            return "预算"
        case .packingSummary:
            return "行李"
        case .mood:
            return "心情"
        case .sticker:
            return "贴纸"
        }
    }
}

#Preview {
    let page = MockJournalEngine()
        .generatePages(for: SampleTripFactory.tokyoFiveDayTrip())
        .first { $0.kind == .day }!

    JournalModulePickerView(page: page, isSelected: { _ in true }, onToggle: { _ in })
}
