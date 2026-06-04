import Foundation

public struct JournalModuleSelection: Codable, Equatable, Sendable {
    public private(set) var selectedBlockIDs: Set<UUID>

    public init(selectedBlockIDs: Set<UUID>) {
        self.selectedBlockIDs = selectedBlockIDs
    }

    public static func defaults(for page: JournalPage) -> JournalModuleSelection {
        JournalModuleSelection(
            selectedBlockIDs: Set(page.blocks.filter(\.isDefaultSelected).map(\.id))
        )
    }

    public func contains(_ blockID: UUID) -> Bool {
        selectedBlockIDs.contains(blockID)
    }

    public mutating func toggle(_ blockID: UUID) {
        if selectedBlockIDs.contains(blockID) {
            selectedBlockIDs.remove(blockID)
        } else {
            selectedBlockIDs.insert(blockID)
        }
    }
}
