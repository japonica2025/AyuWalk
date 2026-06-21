import Foundation

public struct JournalTemplate: Equatable, Identifiable, Sendable {
    public let id: JournalTemplateID
    public var name: String
    public var description: String
    public var coverStyle: JournalTemplateCoverStyle
    public var pageStyle: JournalTemplatePageStyle
    public var exportStyle: JournalTemplateExportStyle
    public var preferredBlockKindsByPageKind: [JournalPageKind: [JournalBlockKind]]

    public init(
        id: JournalTemplateID,
        name: String,
        description: String,
        coverStyle: JournalTemplateCoverStyle,
        pageStyle: JournalTemplatePageStyle,
        exportStyle: JournalTemplateExportStyle,
        preferredBlockKindsByPageKind: [JournalPageKind: [JournalBlockKind]]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.coverStyle = coverStyle
        self.pageStyle = pageStyle
        self.exportStyle = exportStyle
        self.preferredBlockKindsByPageKind = preferredBlockKindsByPageKind
    }
}

public enum JournalTemplateID: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case minimalJournal
    case travelPlanCard
}

public enum JournalTemplateCoverStyle: String, Codable, Equatable, Sendable {
    case paper
    case itineraryCard
}

public enum JournalTemplatePageStyle: String, Codable, Equatable, Sendable {
    case minimal
    case planCard
}

public enum JournalTemplateExportStyle: String, Codable, Equatable, Sendable {
    case longJournalImage
    case planCardImage
}

public enum JournalTemplateLibrary {
    public static let defaultTemplateID: JournalTemplateID = .minimalJournal

    public static let `default`: [JournalTemplate] = [
        JournalTemplate(
            id: .minimalJournal,
            name: "简约手帐",
            description: "适合记录每天的照片、心情和文字手记。",
            coverStyle: .paper,
            pageStyle: .minimal,
            exportStyle: .longJournalImage,
            preferredBlockKindsByPageKind: [
                .cover: [.title, .dateLocation],
                .overview: [.routeSummary],
                .day: [.title, .dateLocation, .photo, .text],
                .summary: [.title, .text]
            ]
        ),
        JournalTemplate(
            id: .travelPlanCard,
            name: "旅行计划卡片",
            description: "适合整理路线、预算、行李和每日计划。",
            coverStyle: .itineraryCard,
            pageStyle: .planCard,
            exportStyle: .planCardImage,
            preferredBlockKindsByPageKind: [
                .cover: [.title, .dateLocation],
                .overview: [.routeSummary, .budgetSummary, .packingSummary],
                .day: [.title, .dateLocation, .timeline, .mapSnapshot],
                .summary: [.routeSummary, .budgetSummary, .packingSummary]
            ]
        )
    ]

    public static func template(id: JournalTemplateID) -> JournalTemplate? {
        `default`.first { $0.id == id }
    }

    public static func selection(
        for page: JournalPage,
        using template: JournalTemplate
    ) -> JournalModuleSelection {
        let preferredKinds = template.preferredBlockKindsByPageKind[page.kind] ?? []
        let selectedIDs = page.blocks
            .filter { preferredKinds.contains($0.kind) }
            .map(\.id)

        if !selectedIDs.isEmpty {
            return JournalModuleSelection(selectedBlockIDs: Set(selectedIDs))
        }

        return JournalModuleSelection.defaults(for: page)
    }
}
