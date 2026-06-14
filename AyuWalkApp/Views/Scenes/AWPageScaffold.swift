import SwiftUI

struct AWPageScaffold<Content: View>: View {
    var background: Color = AyuWalkTheme.canvas
    var showsPaperTexture = true
    var horizontalPadding: CGFloat = AyuWalkSpacing.lg
    var topPadding: CGFloat = AyuWalkSpacing.md
    var bottomPadding: CGFloat = 132
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.xl) {
                content
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
        }
        .background {
            background
            if showsPaperTexture {
                Image.awPaperTexture
                    .resizable()
                    .scaledToFill()
                    .opacity(AyuWalkTexture.pageOpacity)
                    .blendMode(.multiply)
                    .ignoresSafeArea()
            }
        }
    }
}

struct AWSheetScaffold<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        NavigationStack {
            ZStack {
                AyuWalkTheme.pageBackground
                    .ignoresSafeArea()
                Image.awPaperTexture
                    .resizable()
                    .scaledToFill()
                    .opacity(AyuWalkTexture.sheetOpacity)
                    .blendMode(.multiply)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AyuWalkSpacing.lg) {
                        content
                    }
                    .padding(AyuWalkSpacing.xl)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
