import SwiftUI

enum AyuWalkTheme {
    static let pageBackground = Color(red: 0.98, green: 0.97, blue: 0.96)
    static let canvas = Color(red: 0.98, green: 0.97, blue: 0.95)
    static let surface = Color(red: 1.00, green: 0.995, blue: 0.98)
    static let elevated = Color(red: 0.96, green: 0.94, blue: 0.92)
    static let ink = Color(red: 0.18, green: 0.15, blue: 0.13)
    static let mutedInk = Color(red: 0.45, green: 0.42, blue: 0.39)
    static let accent = Color(red: 0.54, green: 0.24, blue: 0.28)
    static let secondaryAccent = Color(red: 0.38, green: 0.48, blue: 0.38)
    static let paper = Color(red: 0.99, green: 0.97, blue: 0.94)
    static let chipSurface = Color(red: 0.96, green: 0.94, blue: 0.90)
    static let border = Color(red: 0.54, green: 0.24, blue: 0.28).opacity(0.13)
    static let hairline = Color(red: 0.18, green: 0.15, blue: 0.13).opacity(0.10)
    static let softShadow = Color(red: 0.18, green: 0.15, blue: 0.13).opacity(0.055)

    static let cardRadius: CGFloat = 14
    static let panelRadius: CGFloat = 28
    static let spacing: CGFloat = 16
}

enum AyuWalkSpacing {
    static let xxxs: CGFloat = 3
    static let xxs: CGFloat = 5
    static let xs: CGFloat = 8
    static let sm: CGFloat = 10
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let pageInset: CGFloat = 18
}

enum AyuWalkRadii {
    static let chip: CGFloat = 999
    static let smallCard: CGFloat = 14
    static let card: CGFloat = 18
    static let panel: CGFloat = 28
    static let journalPage: CGFloat = 20
}

enum AyuWalkShadow {
    static let card = AyuWalkTheme.ink.opacity(0.055)
    static let floating = AyuWalkTheme.ink.opacity(0.10)
    static let journal = AyuWalkTheme.ink.opacity(0.08)
}

enum AyuWalkTexture {
    static let pageOpacity: Double = 0.025
    static let sheetOpacity: Double = 0.022
    static let cardOpacity: Double = 0.055
}

enum AyuWalkSize {
    static let iconButton: CGFloat = 40
    static let compactIconButton: CGFloat = 34
    static let largeIconButton: CGFloat = 44
    static let floatingTabWidth: CGFloat = 72
    static let floatingTabHeight: CGFloat = 35
    static let formControlHeight: CGFloat = 44
    static let stickerControl: CGFloat = 22
    static let stickerHandle: CGFloat = 18
}

enum AyuWalkMotion {
    static let quick = Animation.spring(response: 0.28, dampingFraction: 0.88)
    static let standard = Animation.spring(response: 0.45, dampingFraction: 0.88)
}

enum AyuWalkTypography {
    static let brand = Font.caption2.weight(.heavy)
    static let eyebrow = Font.caption.weight(.bold)
    static let screenTitle = Font.system(.largeTitle, design: .serif, weight: .bold)
    static let pageTitle = Font.system(.title2, design: .serif, weight: .bold)
    static let sectionTitle = Font.headline.weight(.bold)
    static let cardTitle = Font.body.weight(.bold)
    static let body = Font.callout
    static let bodyStrong = Font.body.weight(.semibold)
    static let caption = Font.caption
    static let captionStrong = Font.caption.weight(.semibold)
    static let micro = Font.caption2
    static let microStrong = Font.caption2.weight(.bold)
    static let button = Font.headline.weight(.bold)
    static let metric = Font.subheadline.weight(.bold)

    static func icon(size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight)
    }
}
