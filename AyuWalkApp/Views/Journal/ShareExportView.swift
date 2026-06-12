import SwiftUI
import UIKit

struct ShareExportView: View {
    let markdown: String
    let socialCopy: String

    @State private var copiedLabel: String?
    @State private var editableSocialCopy: String
    @State private var sharePayload: SharePayload?
    @State private var exportErrorMessage: String?

    init(markdown: String, socialCopy: String) {
        self.markdown = markdown
        self.socialCopy = socialCopy
        _editableSocialCopy = State(initialValue: socialCopy)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AyuWalkTheme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        exportCard(
                            title: "小红书文案",
                            subtitle: "可先编辑，再复制发布",
                            content: $editableSocialCopy,
                            copyLabel: "复制文案",
                            shareLabel: "系统分享",
                            isEditable: true
                        ) {
                            sharePayload = SharePayload(items: [editableSocialCopy])
                        }

                        exportCard(
                            title: "Markdown 文档",
                            subtitle: "可导入其他 AI、笔记软件或手帐工具继续编辑",
                            content: .constant(markdown),
                            copyLabel: "复制 Markdown",
                            shareLabel: "分享文件",
                            isEditable: false
                        ) {
                            do {
                                sharePayload = SharePayload(items: [try markdownFileURL()])
                            } catch {
                                exportErrorMessage = "Markdown 文件生成失败，请稍后再试。"
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("分享导出")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $sharePayload) { payload in
                ShareSheet(items: payload.items)
            }
            .alert("导出失败", isPresented: Binding(
                get: { exportErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        exportErrorMessage = nil
                    }
                }
            )) {
                Button("知道了", role: .cancel) {
                    exportErrorMessage = nil
                }
            } message: {
                Text(exportErrorMessage ?? "")
            }
        }
    }

    private func exportCard(
        title: String,
        subtitle: String,
        content: Binding<String>,
        copyLabel: String,
        shareLabel: String,
        isEditable: Bool,
        onShare: @escaping () -> Void
    ) -> some View {
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

                HStack(spacing: 8) {
                    Button(action: onShare) {
                        Text(shareLabel)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AyuWalkTheme.accent)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(AyuWalkTheme.paper)
                            .clipShape(Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(AyuWalkTheme.border, lineWidth: 1)
                            }
                    }

                    Button {
                        UIPasteboard.general.string = content.wrappedValue
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
            }

            if isEditable {
                TextEditor(text: content)
                    .font(.footnote)
                    .foregroundStyle(AyuWalkTheme.ink)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 180)
                    .padding(8)
                    .background(AyuWalkTheme.pageBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                Text(content.wrappedValue)
                    .font(.footnote)
                    .foregroundStyle(AyuWalkTheme.ink)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(AyuWalkTheme.pageBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(16)
        .background(AyuWalkTheme.paper)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AyuWalkTheme.border, lineWidth: 1)
        }
    }

    private func markdownFileURL() throws -> URL {
        let title = markdown
            .split(separator: "\n")
            .first { $0.hasPrefix("# ") }
            .map { String($0.dropFirst(2)) } ?? "AyuWalk"
        let fileName = sanitizedFileName(title) + ".md"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
        try markdown.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }

    private func sanitizedFileName(_ title: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
            .union(.newlines)
            .union(.controlCharacters)
        let cleaned = title
            .components(separatedBy: invalid)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "AyuWalk-Export" : cleaned
    }
}

private struct SharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ShareExportView(
        markdown: "# 大阪 3 日旅行\n\n- 黑门市场\n- 道顿堀",
        socialCopy: "大阪 3 日路线整理好了。\n\n#织步记 #AyuWalk"
    )
}
