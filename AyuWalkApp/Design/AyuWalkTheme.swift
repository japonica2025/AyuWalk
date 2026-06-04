import SwiftUI

enum AyuWalkTheme {
    static let pageBackground = Color(red: 0.95, green: 0.93, blue: 0.84)
    static let canvas = Color(red: 0.97, green: 0.95, blue: 0.89)
    static let surface = Color(red: 1.00, green: 0.98, blue: 0.90)
    static let elevated = Color(red: 0.99, green: 0.96, blue: 0.84)
    static let ink = Color(red: 0.11, green: 0.10, blue: 0.08)
    static let mutedInk = Color(red: 0.43, green: 0.37, blue: 0.29)
    static let accent = Color(red: 0.58, green: 0.20, blue: 0.06)
    static let secondaryAccent = Color(red: 0.07, green: 0.33, blue: 0.41)
    static let paper = Color(red: 0.98, green: 0.95, blue: 0.82)
    static let border = Color(red: 0.58, green: 0.20, blue: 0.06).opacity(0.14)
    static let hairline = Color(red: 0.30, green: 0.22, blue: 0.12).opacity(0.12)
    static let softShadow = Color.black.opacity(0.08)

    static let cardRadius: CGFloat = 8
    static let panelRadius: CGFloat = 22
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
    static let smallCard: CGFloat = 8
    static let card: CGFloat = 12
    static let panel: CGFloat = 22
    static let journalPage: CGFloat = 20
}

enum AyuWalkShadow {
    static let card = Color.black.opacity(0.08)
    static let floating = Color.black.opacity(0.12)
    static let journal = AyuWalkTheme.ink.opacity(0.10)
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
    static let screenTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let pageTitle = Font.system(.title2, design: .rounded, weight: .bold)
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
