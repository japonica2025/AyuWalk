public enum ShareExportAssetKind: Sendable {
    case socialCopy
    case markdown
    case pdf
    case summaryCardImage
    case longDocumentImage

    public var isRasterImage: Bool {
        switch self {
        case .summaryCardImage, .longDocumentImage:
            return true
        case .socialCopy, .markdown, .pdf:
            return false
        }
    }
}
