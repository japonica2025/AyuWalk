import AyuWalkCore
import SwiftUI

struct PackingListView: View {
    let items: [PackingItem]
    let onToggleItem: (UUID) -> Void

    private var packedCount: Int {
        items.filter(\.isPacked).count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AyuWalkTheme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        progressCard
                        checklistCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle("行李清单")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("打包进度")
                .font(.caption.weight(.bold))
                .foregroundStyle(AyuWalkTheme.secondaryAccent)

            Text("\(packedCount)/\(items.count) 已完成")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AyuWalkTheme.ink)

            ProgressView(value: items.isEmpty ? 0 : Double(packedCount), total: Double(max(items.count, 1)))
                .tint(AyuWalkTheme.secondaryAccent)

            Text("当前先生成基础清单，后续可以按目的地、天气和行程类型自动补充。")
                .font(.callout)
                .foregroundStyle(AyuWalkTheme.mutedInk)
        }
        .card()
    }

    private var checklistCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("清单")
                .font(.headline.weight(.bold))
                .foregroundStyle(AyuWalkTheme.ink)

            if items.isEmpty {
                Text("暂无行李项目")
                    .font(.callout)
                    .foregroundStyle(AyuWalkTheme.mutedInk)
                    .padding(.vertical, 12)
            } else {
                ForEach(items) { item in
                    Button {
                        onToggleItem(item.id)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 23, weight: .semibold))
                                .foregroundStyle(item.isPacked ? AyuWalkTheme.secondaryAccent : AyuWalkTheme.mutedInk)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(AyuWalkTheme.ink)

                                if let notes = item.notes {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundStyle(AyuWalkTheme.mutedInk)
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.title)

                    if item.id != items.last?.id {
                        Divider()
                            .overlay(AyuWalkTheme.border)
                    }
                }
            }
        }
        .card()
    }
}

private extension View {
    func card() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AyuWalkTheme.paper)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AyuWalkTheme.border, lineWidth: 1)
            }
    }
}

#Preview {
    PackingListView(items: SampleTripFactory.tokyoFiveDayTrip().packingList?.items ?? []) { _ in }
}
