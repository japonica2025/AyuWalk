import CoreText
import SwiftUI

@main
struct AyuWalkApp: App {
    @State private var appState = AppState()

    init() {
        AyuWalkFontRegistrar.registerFonts()
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.largeTitleTextAttributes = [
            .font: UIFont(name: AyuWalkTypography.fontName, size: 34) ?? .systemFont(ofSize: 34, weight: .bold),
            .foregroundColor: UIColor(AyuWalkTheme.ink)
        ]
        appearance.titleTextAttributes = [
            .font: UIFont(name: AyuWalkTypography.fontName, size: 18) ?? .systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: UIColor(AyuWalkTheme.ink)
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}

private enum AyuWalkFontRegistrar {
    static func registerFonts() {
        guard let fontURL = Bundle.main.url(forResource: "CorpSrcWinSong", withExtension: "ttf") else {
            return
        }

        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }
}
