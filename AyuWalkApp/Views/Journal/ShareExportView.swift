import CoreText
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

                        exportCard(
                            title: "PDF 文档",
                            subtitle: "生成可保存或转发的 PDF 行程文件",
                            content: .constant("包含当前行程、预算、AA、行李清单和手帐模块内容。"),
                            copyLabel: nil,
                            shareLabel: "分享 PDF",
                            isEditable: false
                        ) {
                            do {
                                sharePayload = SharePayload(items: [try pdfFileURL()])
                            } catch {
                                exportErrorMessage = "PDF 文件生成失败，请稍后再试。"
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
        copyLabel: String?,
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

                    if let copyLabel {
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
        guard let data = markdown.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        try data.write(to: url, options: .atomic)
        return url
    }

    private func pdfFileURL() throws -> URL {
        let title = markdown
            .split(separator: "\n")
            .first { $0.hasPrefix("# ") }
            .map { String($0.dropFirst(2)) } ?? "AyuWalk"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(sanitizedFileName(title) + ".pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
        let attributedContent = pdfAttributedContent()
        var renderedCharacters = 0
        var didAbortRendering = false

        try renderer.writePDF(to: url) { context in
            let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
            let contentRect = pageRect.insetBy(dx: 42, dy: 48)

            let framesetter = CTFramesetterCreateWithAttributedString(attributedContent)
            let frameRect = CGRect(
                x: contentRect.minX,
                y: pageRect.height - contentRect.maxY,
                width: contentRect.width,
                height: contentRect.height
            )
            var range = CFRange(location: 0, length: 0)

            while range.location < attributedContent.length {
                context.beginPage()

                let cgContext = context.cgContext
                cgContext.saveGState()
                cgContext.textMatrix = .identity
                cgContext.translateBy(x: 0, y: pageRect.height)
                cgContext.scaleBy(x: 1, y: -1)

                let path = CGMutablePath()
                path.addRect(frameRect)
                let frame = CTFramesetterCreateFrame(framesetter, range, path, nil)
                CTFrameDraw(frame, cgContext)
                let visibleRange = CTFrameGetVisibleStringRange(frame)

                cgContext.restoreGState()

                guard visibleRange.length > 0 else {
                    didAbortRendering = true
                    break
                }
                range.location += visibleRange.length
                renderedCharacters = range.location
            }
        }

        guard !didAbortRendering, renderedCharacters >= attributedContent.length else {
            try? FileManager.default.removeItem(at: url)
            throw ExportError.pdfRenderingFailed
        }

        return url
    }

    private func pdfAttributedContent() -> NSAttributedString {
        let content = NSMutableAttributedString()
        let lines = markdown.isEmpty ? ["暂无导出内容"] : markdown.components(separatedBy: .newlines)

        for line in lines {
            let isTitle = line.hasPrefix("# ")
            let isHeading = line.hasPrefix("##") || line.hasPrefix("###")
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineBreakMode = .byWordWrapping
            paragraph.lineSpacing = 3
            paragraph.paragraphSpacing = isTitle ? 10 : (isHeading ? 7 : 4)

            let displayLine = line.replacingOccurrences(
                of: "^#+\\s*",
                with: "",
                options: .regularExpression
            )
            let text = (displayLine.isEmpty ? " " : displayLine) + "\n"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: pdfFont(isTitle: isTitle, isHeading: isHeading),
                .foregroundColor: Self.pdfInkColor,
                .paragraphStyle: paragraph
            ]
            content.append(NSAttributedString(string: text, attributes: attributes))
        }

        return content
    }

    private func pdfFont(isTitle: Bool, isHeading: Bool) -> UIFont {
        if isTitle {
            return UIFont.systemFont(ofSize: 22, weight: .bold)
        }
        if isHeading {
            return UIFont.systemFont(ofSize: 15, weight: .semibold)
        }
        return UIFont.systemFont(ofSize: 11)
    }

    private static let pdfInkColor = UIColor(red: 0.18, green: 0.12, blue: 0.08, alpha: 1)

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

private enum ExportError: Error {
    case encodingFailed
    case pdfRenderingFailed
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
