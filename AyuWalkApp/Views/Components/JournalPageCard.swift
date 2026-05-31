import AyuWalkCore
import SwiftUI

struct JournalPageCard: View {
    let page: JournalPage

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(page.title)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(AyuWalkTheme.ink)

            ForEach(page.blocks) { block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(AyuWalkTheme.paper)
        .clipShape(RoundedRectangle(cornerRadius: AyuWalkTheme.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AyuWalkTheme.cardRadius)
                .stroke(AyuWalkTheme.border)
        )
    }

    private func blockView(_ block: JournalBlock) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = block.title {
                HStack {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AyuWalkTheme.accent)

                    if block.isDefaultSelected {
                        Text("默认")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AyuWalkTheme.accent)
                            .clipShape(Capsule())
                    }
                }
            }

            Text(block.text ?? "")
                .font(.callout)
                .foregroundStyle(AyuWalkTheme.mutedInk)
        }
    }
}

#Preview {
    JournalPageCard(page: MockJournalEngine().generatePages(for: SampleTripFactory.tokyoFiveDayTrip()).first!)
        .padding()
}
