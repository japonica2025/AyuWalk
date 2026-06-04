import SwiftUI
import UIKit

struct ShareExportView: View {
    let markdown: String
    let socialCopy: String

    @State private var copiedLabel: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AyuWalkTheme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        exportCard(
                            title: "小红书文案",
                            subtitle: "可直接复制后发布，也可以再交给 AI 改写",
                            content: socialCopy,
                            copyLabel: "复制文案"
                        )

                        exportCard(
                            title: "Markdown 文档",
                            subtitle: "可导入其他 AI、笔记软件或手帐工具继续编辑",
                            content: markdown,
                            copyLabel: "复制 Markdown"
                        )
                    }
                    .padding(20)
                }
            }
            .navigationTitle("分享导出")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func exportCard(title: String, subtitle: String, content: String, copyLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AyuWalkTheme.ink)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                }

                Spacer()

                Button {
                    UIPasteboard.general.string = content
                    copiedLabel = copyLabel
                } label: {
                    Text(copiedLabel == copyLabel ? "已复制" : copyLabel)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .background(AyuWalkTheme.accent)
                        .clipShape(Capsule())
                }
            }

            Text(content)
                .font(.footnote)
                .foregroundStyle(AyuWalkTheme.ink)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(AyuWalkTheme.pageBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(16)
        .background(AyuWalkTheme.paper)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AyuWalkTheme.border, lineWidth: 1)
        }
    }
}

#Preview {
    ShareExportView(
        markdown: "# 大阪 3 日旅行\n\n- 黑门市场\n- 道顿堀",
        socialCopy: "大阪 3 日路线整理好了。\n\n#织步记 #AyuWalk"
    )
}
