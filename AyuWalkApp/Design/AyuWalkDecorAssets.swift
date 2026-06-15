import SwiftUI

enum AyuWalkDecorAssets {
    static let paperTexture = "AWReferencePaperTexture"
    static let paperCardSurface = "AWPaperCardSurface"
    static let washiTapeStrips = "AWWashiTapeStrips"
    static let washiTapeRose = "AWWashiTapeRose"
    static let washiTapeSage = "AWWashiTapeSage"
    static let washiTapeCream = "AWWashiTapeCream"
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

    static var awWashiTapeRose: Image {
        Image(AyuWalkDecorAssets.washiTapeRose)
    }

    static var awWashiTapeSage: Image {
        Image(AyuWalkDecorAssets.washiTapeSage)
    }

    static var awWashiTapeCream: Image {
        Image(AyuWalkDecorAssets.washiTapeCream)
    }
}
