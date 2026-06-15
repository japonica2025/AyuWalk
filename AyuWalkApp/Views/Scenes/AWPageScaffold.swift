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
            AWPaperBackground(
                color: background,
                textureOpacity: showsPaperTexture ? AyuWalkTexture.pageOpacity : 0
            )
        }
    }
}

struct AWPaperBackground: View {
    var color: Color = AyuWalkTheme.canvas
    var textureOpacity: Double = AyuWalkTexture.pageOpacity

    var body: some View {
        ZStack {
            color

            if textureOpacity > 0 {
                Image.awPaperTexture
                    .resizable()
                    .scaledToFill()
                    .opacity(textureOpacity)
                    .blendMode(.multiply)
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }
}

struct AWEditorialPageTitle: View {
    let title: String
    var color: Color = AyuWalkTheme.ink

    var body: some View {
        Text(title)
            .font(AyuWalkTypography.editorialTitle)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
    }
}

struct AWSheetScaffold<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        NavigationStack {
            ZStack {
                AWPaperBackground(
                    color: AyuWalkTheme.pageBackground,
                    textureOpacity: AyuWalkTexture.sheetOpacity
                )

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
