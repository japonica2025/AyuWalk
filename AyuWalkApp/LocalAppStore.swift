import AyuWalkCore
import Foundation

struct AppPersistenceSnapshot: Codable, Equatable {
    var tripLibrary: TripLibrary

    init(tripLibrary: TripLibrary) {
        self.tripLibrary = tripLibrary
    }

    private enum CodingKeys: String, CodingKey {
        case activeTripID
        case workspaces
        case trip
        case journalPages
        case journalSelections
        case stickerSelections
        case customStickers
        case completedActivityIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let workspaces = try container.decodeIfPresent([TripWorkspace].self, forKey: .workspaces) {
            tripLibrary = TripLibrary(
                activeTripID: try container.decodeIfPresent(UUID.self, forKey: .activeTripID),
                workspaces: workspaces
            )
            return
        }

        let trip = try container.decode(Trip.self, forKey: .trip)
        let workspace = TripWorkspace(
            trip: trip,
            journalPages: try container.decodeIfPresent([JournalPage].self, forKey: .journalPages) ?? trip.journalPages,
            journalSelections: try container.decodeIfPresent([UUID: JournalModuleSelection].self, forKey: .journalSelections) ?? [:],
            stickerSelections: try container.decodeIfPresent([UUID: StickerSelection].self, forKey: .stickerSelections) ?? [:],
            customStickers: try container.decodeIfPresent([Sticker].self, forKey: .customStickers) ?? [],
            completedActivityIDs: try container.decodeIfPresent(Set<UUID>.self, forKey: .completedActivityIDs) ?? []
        )
        tripLibrary = TripLibrary(activeTripID: workspace.id, workspaces: [workspace])
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(tripLibrary.activeTripID, forKey: .activeTripID)
        try container.encode(tripLibrary.workspaces, forKey: .workspaces)
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

        guard let snapshot = try? JSONDecoder().decode(AppPersistenceSnapshot.self, from: data) else {
            return nil
        }
        save(snapshot)
        return snapshot
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
