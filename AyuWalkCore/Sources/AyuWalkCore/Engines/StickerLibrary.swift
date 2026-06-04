import Foundation

public struct StickerLibrary: Codable, Equatable, Sendable {
    public var categories: [StickerCategory]

    public init(categories: [StickerCategory]) {
        self.categories = categories
    }

    public static let `default` = StickerLibrary(categories: [
        StickerCategory(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000701")!,
            title: "天气",
            stickers: [
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000801")!, title: "晴天", symbol: "sun.max.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000802")!, title: "小雨", symbol: "cloud.rain.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000811")!, title: "多云", symbol: "cloud.sun.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000812")!, title: "夜景", symbol: "moon.stars.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000813")!, title: "很热", symbol: "thermometer.sun.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000814")!, title: "有风", symbol: "wind")
            ]
        ),
        StickerCategory(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000702")!,
            title: "美食",
            stickers: [
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000803")!, title: "咖啡", symbol: "cup.and.saucer.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000804")!, title: "甜点", symbol: "birthday.cake.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000815")!, title: "午餐", symbol: "fork.knife"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000816")!, title: "晚餐", symbol: "wineglass.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000817")!, title: "拉面", symbol: "takeoutbag.and.cup.and.straw.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000818")!, title: "好吃", symbol: "hand.thumbsup.fill")
            ]
        ),
        StickerCategory(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000703")!,
            title: "景点",
            stickers: [
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000805")!, title: "城市散步", symbol: "figure.walk"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000806")!, title: "拍照点", symbol: "camera.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000819")!, title: "博物馆", symbol: "building.columns.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000820")!, title: "购物", symbol: "bag.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000821")!, title: "公园", symbol: "tree.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000822")!, title: "地标", symbol: "mappin.and.ellipse")
            ]
        ),
        StickerCategory(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000704")!,
            title: "心情",
            stickers: [
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000807")!, title: "开心", symbol: "heart.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000808")!, title: "放松", symbol: "sparkles"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000823")!, title: "惊喜", symbol: "party.popper.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000824")!, title: "疲惫", symbol: "bed.double.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000825")!, title: "治愈", symbol: "leaf.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000826")!, title: "收藏", symbol: "bookmark.fill")
            ]
        ),
        StickerCategory(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000705")!,
            title: "演唱会",
            stickers: [
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000809")!, title: "现场", symbol: "music.mic"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000810")!, title: "应援", symbol: "star.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000827")!, title: "舞台", symbol: "theatermasks.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000828")!, title: "灯牌", symbol: "lightbulb.max.fill"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000829")!, title: "歌单", symbol: "music.note.list"),
                Sticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000830")!, title: "合照", symbol: "person.2.fill")
            ]
        )
    ])
}

public struct StickerCategory: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var stickers: [Sticker]

    public init(id: UUID, title: String, stickers: [Sticker]) {
        self.id = id
        self.title = title
        self.stickers = stickers
    }
}

public struct Sticker: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var symbol: String
    public var imageDataBase64: String?

    public init(id: UUID, title: String, symbol: String, imageDataBase64: String? = nil) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.imageDataBase64 = imageDataBase64
    }
}

public struct JournalStickerPlacement: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var stickerID: UUID
    public var xRatio: Double
    public var yRatio: Double
    public var scale: Double
    public var rotationDegrees: Double

    public init(
        id: UUID,
        stickerID: UUID,
        xRatio: Double,
        yRatio: Double,
        scale: Double = 1,
        rotationDegrees: Double = 0
    ) {
        self.id = id
        self.stickerID = stickerID
        self.xRatio = xRatio
        self.yRatio = yRatio
        self.scale = scale
        self.rotationDegrees = rotationDegrees
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case stickerID
        case xRatio
        case yRatio
        case scale
        case rotationDegrees
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        stickerID = try container.decode(UUID.self, forKey: .stickerID)
        xRatio = try container.decode(Double.self, forKey: .xRatio)
        yRatio = try container.decode(Double.self, forKey: .yRatio)
        scale = try container.decodeIfPresent(Double.self, forKey: .scale) ?? 1
        rotationDegrees = try container.decodeIfPresent(Double.self, forKey: .rotationDegrees) ?? 0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(stickerID, forKey: .stickerID)
        try container.encode(xRatio, forKey: .xRatio)
        try container.encode(yRatio, forKey: .yRatio)
        try container.encode(scale, forKey: .scale)
        try container.encode(rotationDegrees, forKey: .rotationDegrees)
    }
}

public struct StickerSelection: Codable, Equatable, Sendable {
    public private(set) var selectedStickerIDs: Set<UUID>
    public private(set) var placements: [JournalStickerPlacement]

    public init(
        selectedStickerIDs: Set<UUID>,
        placements: [JournalStickerPlacement] = []
    ) {
        self.selectedStickerIDs = selectedStickerIDs
        self.placements = placements
    }

    public func contains(_ stickerID: UUID) -> Bool {
        selectedStickerIDs.contains(stickerID) || placements.contains { $0.stickerID == stickerID }
    }

    public mutating func toggle(_ stickerID: UUID) {
        if selectedStickerIDs.contains(stickerID) {
            selectedStickerIDs.remove(stickerID)
        } else {
            selectedStickerIDs.insert(stickerID)
        }
    }

    public mutating func addPlacement(
        stickerID: UUID,
        xRatio: Double,
        yRatio: Double,
        id: UUID = UUID()
    ) {
        placements.append(
            JournalStickerPlacement(
                id: id,
                stickerID: stickerID,
                xRatio: min(max(xRatio, 0), 1),
                yRatio: min(max(yRatio, 0), 1)
            )
        )
    }

    public mutating func removePlacement(id: UUID) {
        placements.removeAll { $0.id == id }
    }

    public mutating func updatePlacement(id: UUID, xRatio: Double, yRatio: Double) {
        guard let index = placements.firstIndex(where: { $0.id == id }) else {
            return
        }

        placements[index].xRatio = min(max(xRatio, 0), 1)
        placements[index].yRatio = min(max(yRatio, 0), 1)
    }

    public mutating func updatePlacementTransform(id: UUID, scale: Double, rotationDegrees: Double) {
        guard let index = placements.firstIndex(where: { $0.id == id }) else {
            return
        }

        placements[index].scale = min(max(scale, 0.65), 2.2)
        placements[index].rotationDegrees = rotationDegrees
    }

    private enum CodingKeys: String, CodingKey {
        case selectedStickerIDs
        case placements
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedStickerIDs = try container.decodeIfPresent(Set<UUID>.self, forKey: .selectedStickerIDs) ?? []
        placements = try container.decodeIfPresent([JournalStickerPlacement].self, forKey: .placements) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(selectedStickerIDs, forKey: .selectedStickerIDs)
        try container.encode(placements, forKey: .placements)
    }
}
