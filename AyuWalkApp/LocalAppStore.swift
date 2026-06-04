import AyuWalkCore
import Foundation

struct AppPersistenceSnapshot: Codable, Equatable {
    var trip: Trip
    var journalPages: [JournalPage]
    var journalSelections: [UUID: JournalModuleSelection]
    var stickerSelections: [UUID: StickerSelection]
    var customStickers: [Sticker]
    var completedActivityIDs: Set<UUID>

    init(
        trip: Trip,
        journalPages: [JournalPage],
        journalSelections: [UUID: JournalModuleSelection],
        stickerSelections: [UUID: StickerSelection],
        customStickers: [Sticker] = [],
        completedActivityIDs: Set<UUID> = []
    ) {
        self.trip = trip
        self.journalPages = journalPages
        self.journalSelections = journalSelections
        self.stickerSelections = stickerSelections
        self.customStickers = customStickers
        self.completedActivityIDs = completedActivityIDs
    }

    private enum CodingKeys: String, CodingKey {
        case trip
        case journalPages
        case journalSelections
        case stickerSelections
        case customStickers
        case completedActivityIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trip = try container.decode(Trip.self, forKey: .trip)
        journalPages = try container.decode([JournalPage].self, forKey: .journalPages)
        journalSelections = try container.decode([UUID: JournalModuleSelection].self, forKey: .journalSelections)
        stickerSelections = try container.decode([UUID: StickerSelection].self, forKey: .stickerSelections)
        customStickers = try container.decodeIfPresent([Sticker].self, forKey: .customStickers) ?? []
        completedActivityIDs = try container.decodeIfPresent(Set<UUID>.self, forKey: .completedActivityIDs) ?? []
    }
}

struct LocalAppStore {
    var fileURL: URL

    static func live() -> LocalAppStore {
        let supportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        let directory = supportDirectory.appendingPathComponent("AyuWalk", isDirectory: true)
        return LocalAppStore(fileURL: directory.appendingPathComponent("app-state.json"))
    }

    func load() -> AppPersistenceSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        return try? JSONDecoder().decode(AppPersistenceSnapshot.self, from: data)
    }

    func save(_ snapshot: AppPersistenceSnapshot) {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            assertionFailure("Failed to save app state: \(error)")
        }
    }
}
