import SwiftUI

enum AyuWalkDecorAssets {
    static let paperTexture = "AWPaperTexture"
    static let paperCardSurface = "AWPaperCardSurface"
    static let washiTapeStrips = "AWWashiTapeStrips"
}

extension Image {
    static var awPaperTexture: Image {
        Image(AyuWalkDecorAssets.paperTexture)
    }

    static var awPaperCardSurface: Image {
        Image(AyuWalkDecorAssets.paperCardSurface)
    }

    static var awWashiTapeStrips: Image {
        Image(AyuWalkDecorAssets.washiTapeStrips)
    }
}
