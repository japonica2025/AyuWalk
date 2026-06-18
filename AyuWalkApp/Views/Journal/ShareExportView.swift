import AyuWalkCore
import CoreText
import Photos
import SwiftUI
import UIKit

struct ShareExportView: View {
    let markdown: String
    let socialCopy: String

    @State private var copiedLabel: String?
    @State private var editableSocialCopy: String
    @State private var sharePayload: SharePayload?
    @State private var exportNotice: ExportNotice?

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
                            assetKind: .socialCopy,
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
                            assetKind: .markdown,
                            isEditable: false
                        ) {
                            do {
                                sharePayload = SharePayload(items: [try markdownFileURL()])
                            } catch {
                                exportNotice = .failure("Markdown 文件生成失败，请稍后再试。")
                            }
                        }

                        exportCard(
                            title: "PDF 文档",
                            subtitle: "生成可保存或转发的 PDF 行程文件",
                            content: .constant("包含当前行程、预算、AA、行李清单和手帐模块内容。"),
                            copyLabel: nil,
                            shareLabel: "分享 PDF",
                            assetKind: .pdf,
                            isEditable: false
                        ) {
                            do {
                                sharePayload = SharePayload(items: [try pdfFileURL()])
                            } catch {
                                exportNotice = .failure("PDF 文件生成失败，请稍后再试。")
                            }
                        }

                        exportCard(
                            title: "计划卡片图",
                            subtitle: "生成适合转发的竖版 PNG 卡片",
                            content: .constant("提取当前行程重点，生成一张可分享的旅行计划卡片。"),
                            copyLabel: nil,
                            shareLabel: "分享卡片",
                            saveLabel: "保存相册",
                            assetKind: .summaryCardImage,
                            isEditable: false
                        ) {
                            do {
                                sharePayload = SharePayload(items: [try imageFileURL(style: .summaryCard)])
                            } catch {
                                exportNotice = .failure("卡片图生成失败，请稍后再试。")
                            }
                        } onSave: {
                            Task {
                                await saveImageToPhotoLibrary(style: .summaryCard)
                            }
                        }

                        exportCard(
                            title: "长图文档",
                            subtitle: "生成包含完整内容的长图 PNG",
                            content: .constant("包含当前行程、预算、AA、行李清单和手帐模块的完整图文。"),
                            copyLabel: nil,
                            shareLabel: "分享长图",
                            saveLabel: "保存相册",
                            assetKind: .longDocumentImage,
                            isEditable: false
                        ) {
                            do {
                                sharePayload = SharePayload(items: [try imageFileURL(style: .longDocument)])
                            } catch {
                                exportNotice = .failure("长图生成失败，请稍后再试。")
                            }
                        } onSave: {
                            Task {
                                await saveImageToPhotoLibrary(style: .longDocument)
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
            .alert(item: $exportNotice) { notice in
                Alert(
                    title: Text(notice.title),
                    message: Text(notice.message),
                    dismissButton: .default(Text("知道了"))
                )
            }
        }
    }

    @MainActor
    private func saveImageToPhotoLibrary(style: ExportImageStyle) async {
        do {
            let url = try imageFileURL(style: style)
            try await PhotoLibraryImageSaver.saveImageFile(at: url)
            exportNotice = .success("图片已保存到系统相册。")
        } catch PhotoLibraryImageSaver.SaveError.permissionDenied {
            exportNotice = .failure("没有相册写入权限。请在系统设置中允许 Ayu Walk 添加照片。")
        } catch {
            exportNotice = .failure("图片保存失败，请稍后再试。")
        }
    }

    private func exportCard(
        title: String,
        subtitle: String,
        content: Binding<String>,
        copyLabel: String?,
        shareLabel: String,
        saveLabel: String? = nil,
        assetKind: ShareExportAssetKind,
        isEditable: Bool,
        onShare: @escaping () -> Void,
        onSave: (() -> Void)? = nil
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
                    if assetKind.isRasterImage,
                       let saveLabel,
                       let onSave {
                        Button(action: onSave) {
                            Text(saveLabel)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AyuWalkTheme.ink)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 8)
                                .background {
                                    Capsule()
                                        .fill(AyuWalkTheme.pageBackground)

                                    Image.awPaperCardSurface
                                        .resizable()
                                        .scaledToFill()
                                        .opacity(AyuWalkTexture.cardOpacity)
                                        .blendMode(.multiply)
                                        .clipShape(Capsule())
                                }
                                .clipShape(Capsule())
                                .overlay {
                                    Capsule()
                                        .stroke(AyuWalkTheme.border, lineWidth: 1)
                                }
                        }
                    }

                    Button(action: onShare) {
                        Text(shareLabel)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AyuWalkTheme.accent)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background {
                                Capsule()
                                    .fill(AyuWalkTheme.paper)

                                Image.awPaperCardSurface
                                    .resizable()
                                    .scaledToFill()
                                    .opacity(AyuWalkTexture.cardOpacity)
                                    .blendMode(.multiply)
                                    .clipShape(Capsule())
                            }
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
                    .awPaperInsetBackground(
                        cornerRadius: 14,
                        fill: AyuWalkTheme.pageBackground,
                        borderTint: AyuWalkTheme.secondaryAccent
                    )
            } else {
                Text(content.wrappedValue)
                    .font(.footnote)
                    .foregroundStyle(AyuWalkTheme.ink)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .awPaperInsetBackground(
                        cornerRadius: 14,
                        fill: AyuWalkTheme.pageBackground,
                        borderTint: AyuWalkTheme.secondaryAccent
                    )
            }
        }
        .padding(16)
        .background {
            AyuWalkTheme.paper

            Image.awPaperCardSurface
                .resizable()
                .scaledToFill()
                .opacity(AyuWalkTexture.cardOpacity)
                .blendMode(.multiply)
        }
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

    @MainActor
    private func imageFileURL(style: ExportImageStyle) throws -> URL {
        let title = exportTitle
        let fileName = sanitizedFileName(title) + "-\(style.fileNameSuffix).png"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
        let renderHeight = style.renderHeight(for: markdown)
        guard renderHeight <= style.maximumRenderHeight else {
            throw ExportError.imageRenderingFailed
        }

        let content = ExportImageDocumentView(
            markdown: markdown,
            style: style,
            renderHeight: renderHeight
        )
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: style.canvasWidth, height: renderHeight)

        guard let image = renderer.uiImage,
              let data = image.pngData() else {
            throw ExportError.imageRenderingFailed
        }

        try data.write(to: url, options: .atomic)
        return url
    }

    private func pdfFileURL() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(sanitizedFileName(exportTitle) + ".pdf")
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

    private var exportTitle: String {
        markdown
            .split(separator: "\n")
            .first { $0.hasPrefix("# ") }
            .map { String($0.dropFirst(2)) } ?? "AyuWalk"
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

private enum ExportError: Error {
    case encodingFailed
    case pdfRenderingFailed
    case imageRenderingFailed
}

private enum ExportImageStyle {
    case summaryCard
    case longDocument

    var fileNameSuffix: String {
        switch self {
        case .summaryCard:
            return "card"
        case .longDocument:
            return "long-image"
        }
    }

    var canvasWidth: CGFloat {
        540
    }

    var maximumRenderHeight: CGFloat {
        switch self {
        case .summaryCard:
            return 675
        case .longDocument:
            return 5_000
        }
    }

    func renderHeight(for markdown: String) -> CGFloat {
        switch self {
        case .summaryCard:
            return 675
        case .longDocument:
            let rawLines = markdown.isEmpty ? ["# AyuWalk", "暂无导出内容"] : markdown.components(separatedBy: .newlines)
            let contentHeight = rawLines.reduce(CGFloat(0)) { total, rawLine in
                let line = ExportImageLine(rawValue: rawLine)
                return total + line.estimatedHeight
            }
            let lineSpacing = CGFloat(max(rawLines.count - 1, 0)) * ExportImageDocumentView.longDocumentLineSpacing
            return min(max(contentHeight + lineSpacing + 56, 675), maximumRenderHeight + 1)
        }
    }
}

private struct ExportImageDocumentView: View {
    static let longDocumentLineSpacing: CGFloat = 10

    let markdown: String
    let style: ExportImageStyle
    let renderHeight: CGFloat

    private var lines: [ExportImageLine] {
        let rawLines = markdown.isEmpty ? ["# AyuWalk", "暂无导出内容"] : markdown.components(separatedBy: .newlines)
        return rawLines.map(ExportImageLine.init)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch style {
            case .summaryCard:
                summaryCardContent
            case .longDocument:
                longDocumentContent
            }
        }
        .frame(width: style.canvasWidth, height: renderHeight, alignment: .topLeading)
        .background(ExportImagePalette.paper)
    }

    private var summaryCardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(primaryTitle)
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(ExportImagePalette.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("Ayu Walk Travel Notes")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ExportImagePalette.accent)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(summaryLines.prefix(5)) { line in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(ExportImagePalette.accent.opacity(0.75))
                            .frame(width: 6, height: 6)
                            .padding(.top, 8)

                        Text(line.text)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(ExportImagePalette.ink)
                            .lineLimit(1)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ExportImagePalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            Spacer(minLength: 0)

            HStack {
                Text("Created with 织步记")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ExportImagePalette.mutedInk)

                Spacer()

                Text("AyuWalk")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(ExportImagePalette.accent)
            }
        }
        .padding(34)
        .frame(width: 540, height: 675, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(ExportImagePalette.paper)
        }
    }

    private var longDocumentContent: some View {
        VStack(alignment: .leading, spacing: Self.longDocumentLineSpacing) {
            ForEach(lines) { line in
                if line.text.isEmpty {
                    Spacer()
                        .frame(height: 4)
                } else {
                    Text(line.text)
                        .font(line.font)
                        .foregroundStyle(line.color)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, line.topPadding)
                }
            }
        }
        .padding(28)
        .frame(width: 540, alignment: .topLeading)
        .background(ExportImagePalette.paper)
    }

    private var primaryTitle: String {
        lines.first(where: { $0.kind == .title })?.text ?? "AyuWalk"
    }

    private var summaryLines: [ExportImageLine] {
        let bodyLines = lines.filter { line in
            !line.text.isEmpty && line.kind != .title && line.kind != .heading
        }
        return bodyLines.isEmpty ? [ExportImageLine(rawValue: "暂无导出内容")] : bodyLines
    }
}

private struct ExportImageLine: Identifiable {
    enum Kind {
        case title
        case heading
        case body
    }

    let id = UUID()
    let text: String
    let kind: Kind

    init(rawValue: String) {
        if rawValue.hasPrefix("# ") {
            text = String(rawValue.dropFirst(2))
            kind = .title
        } else if rawValue.hasPrefix("##") {
            text = rawValue.replacingOccurrences(
                of: "^#+\\s*",
                with: "",
                options: .regularExpression
            )
            kind = .heading
        } else {
            text = rawValue.replacingOccurrences(
                of: "^[-*>\\s\\[x\\]]+",
                with: "",
                options: .regularExpression
            )
            kind = .body
        }
    }

    var font: Font {
        switch kind {
        case .title:
            return .system(size: 30, weight: .bold, design: .serif)
        case .heading:
            return .system(size: 20, weight: .bold)
        case .body:
            return .system(size: 15, weight: .regular)
        }
    }

    var color: Color {
        switch kind {
        case .title, .heading:
            return ExportImagePalette.ink
        case .body:
            return ExportImagePalette.mutedInk
        }
    }

    var topPadding: CGFloat {
        switch kind {
        case .title:
            return 0
        case .heading:
            return 14
        case .body:
            return 0
        }
    }

    var estimatedHeight: CGFloat {
        if text.isEmpty {
            return 14
        }

        let wrappedLineCount = CGFloat(max(Int(ceil(Double(text.count) / 28.0)), 1))
        switch kind {
        case .title:
            return 42 * wrappedLineCount
        case .heading:
            return 34 + topPadding
        case .body:
            return 24 * wrappedLineCount
        }
    }
}

private enum ExportImagePalette {
    static let paper = AyuWalkTheme.pageBackground
    static let surface = AyuWalkTheme.surface.opacity(0.92)
    static let ink = AyuWalkTheme.ink
    static let mutedInk = AyuWalkTheme.mutedInk
    static let accent = AyuWalkTheme.accent
}

private struct ExportNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String

    static func success(_ message: String) -> ExportNotice {
        ExportNotice(title: "已完成", message: message)
    }

    static func failure(_ message: String) -> ExportNotice {
        ExportNotice(title: "导出失败", message: message)
    }
}

private enum PhotoLibraryImageSaver {
    enum SaveError: Error {
        case permissionDenied
        case saveFailed
    }

    static func saveImageFile(at url: URL) async throws {
        let status = await photoLibraryAddStatus()
        guard status == .authorized || status == .limited else {
            throw SaveError.permissionDenied
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, fileURL: url, options: nil)
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: SaveError.saveFailed)
                }
            }
        }
    }

    private static func photoLibraryAddStatus() async -> PHAuthorizationStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        guard currentStatus == .notDetermined else {
            return currentStatus
        }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
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
