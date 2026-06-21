import AyuWalkCore
import PhotosUI
import SwiftUI
import UIKit

struct JournalPreviewView: View {
    @Environment(AppState.self) private var appState
    var onBottomToolActiveChanged: (Bool) -> Void = { _ in }
    @State private var selectedPageID: UUID?
    @State private var isChoosingModules = false
    @State private var isStickerTrayVisible = false
    @State private var selectedStickerCategoryID: UUID = StickerLibrary.default.categories.first?.id ?? UUID()
    @State private var isExporting = false
    @State private var selectedStickerPhotoItem: PhotosPickerItem?
    @State private var pageFrames: [UUID: CGRect] = [:]
    @State private var isStickerInteracting = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    AyuWalkTheme.pageBackground
                        .ignoresSafeArea()

                    VStack(alignment: .leading, spacing: 14) {
                        if !isStickerTrayVisible {
                            journalHeader
                            pageSelector
                        }

                        ScrollViewReader { proxy in
                            ScrollView(.horizontal) {
                                LazyHStack(spacing: 18) {
                                    ForEach(appState.journalPages) { page in
                                        JournalPageCard(
                                            page: page,
                                            visibleBlocks: appState.selectedBlocks(for: page),
                                            placedStickers: appState.placedStickers(for: page),
                                            isStickerEditingMode: isStickerTrayVisible,
                                            onDropSticker: { stickerID, xRatio, yRatio in
                                                appState.addStickerPlacement(
                                                    pageID: page.id,
                                                    stickerID: stickerID,
                                                    xRatio: xRatio,
                                                    yRatio: yRatio
                                                )
                                            },
                                            onRemoveSticker: { placementID in
                                                appState.removeStickerPlacement(
                                                    pageID: page.id,
                                                    placementID: placementID
                                                )
                                            },
                                            onMoveSticker: { placementID, xRatio, yRatio in
                                                appState.updateStickerPlacement(
                                                    pageID: page.id,
                                                    placementID: placementID,
                                                    xRatio: xRatio,
                                                    yRatio: yRatio
                                                )
                                            },
                                            onTransformSticker: { placementID, scale, rotationDegrees in
                                                appState.updateStickerTransform(
                                                    pageID: page.id,
                                                    placementID: placementID,
                                                    scale: scale,
                                                    rotationDegrees: rotationDegrees
                                                )
                                            },
                                            onStickerInteractionChanged: { isInteracting in
                                                isStickerInteracting = isInteracting
                                            }
                                        )
                                        .containerRelativeFrame(.horizontal, count: 1, span: 1, spacing: 18)
                                        .background {
                                            GeometryReader { proxy in
                                                Color.clear.preference(
                                                    key: JournalPageFramePreferenceKey.self,
                                                    value: [page.id: proxy.frame(in: .global)]
                                                )
                                            }
                                        }
                                        .rotation3DEffect(
                                            .degrees(selectedPageID == page.id ? 0 : -2),
                                            axis: (x: 0, y: 1, z: 0)
                                        )
                                        .id(page.id)
                                    }
                                }
                                .scrollTargetLayout()
                            }
                            .contentMargins(.horizontal, 18, for: .scrollContent)
                            .scrollTargetBehavior(.viewAligned)
                            .scrollDisabled(isStickerInteracting || isStickerTrayVisible)
                            .onChange(of: selectedPageID) { _, newValue in
                                guard let newValue else { return }

                                withAnimation(.snappy) {
                                    proxy.scrollTo(newValue, anchor: .center)
                                }
                            }
                            .onPreferenceChange(JournalPageFramePreferenceKey.self) { newValue in
                                pageFrames = newValue
                            }
                        }
                    }

                    if isStickerTrayVisible, let currentPage {
                        stickerTray(for: currentPage, height: max(geometry.size.height * 0.25, 178))
                            .padding(.horizontal, 14)
                            .padding(.bottom, 8)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.32, dampingFraction: 0.88), value: isStickerTrayVisible)
            }
            .navigationTitle("电子手帐")
            .sheet(isPresented: $isChoosingModules) {
                if let page = currentPage {
                    JournalModulePickerView(
                        page: page,
                        isSelected: { blockID in
                            appState.isJournalBlockSelected(pageID: page.id, blockID: blockID)
                        },
                        onToggle: { blockID in
                            appState.toggleJournalBlock(pageID: page.id, blockID: blockID)
                        }
                    )
                    .presentationDetents([.medium, .large])
                }
            }
            .sheet(isPresented: $isExporting) {
                ShareExportView(
                    markdown: ShareExportBuilder.markdown(
                        trip: appState.trip,
                        journalPages: appState.journalPages,
                        selectedBlocks: appState.selectedBlocks(for:),
                        selectedStickers: appState.selectedStickers(for:)
                    ),
                    socialCopy: ShareExportBuilder.socialCopy(trip: appState.trip)
                )
                .presentationDetents([.large])
            }
            .onAppear {
                selectedPageID = selectedPageID ?? appState.journalPages.first?.id
            }
            .onChange(of: isStickerTrayVisible) { _, isVisible in
                onBottomToolActiveChanged(isVisible)
            }
            .onDisappear {
                onBottomToolActiveChanged(false)
            }
        }
    }

    private var currentPage: JournalPage? {
        if let selectedPageID,
           let selected = appState.journalPages.first(where: { $0.id == selectedPageID }) {
            return selected
        }

        return appState.journalPages.first
    }

    private var journalHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("每日页面")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AyuWalkTheme.ink)
                Text("横向滑动翻页，选择每页需要保留的模块")
                    .font(.caption)
                    .foregroundStyle(AyuWalkTheme.mutedInk)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    AWActionCapsuleButton(
                        title: "导出",
                        systemImage: "square.and.arrow.up.fill",
                        tint: AyuWalkTheme.accent
                    ) {
                        isExporting = true
                    }
                    .accessibilityLabel("分享导出")

                    AWActionCapsuleButton(
                        title: "贴纸",
                        systemImage: "seal.fill",
                        tint: AyuWalkTheme.accent
                    ) {
                        isStickerTrayVisible.toggle()
                    }
                    .accessibilityLabel("选择贴纸")

                    AWActionCapsuleButton(
                        title: "模块",
                        systemImage: "square.grid.2x2.fill",
                        tint: AyuWalkTheme.accent,
                        isProminent: true
                    ) {
                        isChoosingModules = true
                    }
                    .accessibilityLabel("选择模块")
                }
            }

            templateSelector
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var templateSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(JournalTemplateLibrary.default) { template in
                    AWSelectableChip(
                        title: template.name,
                        isSelected: appState.journalTemplateID == template.id,
                        tint: AyuWalkTheme.accent
                    ) {
                        appState.applyJournalTemplate(id: template.id)
                    }
                    .accessibilityLabel("手帐模板 \(template.name)")
                    .accessibilityHint(template.description)
                }
            }
        }
    }

    private var pageSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(appState.journalPages) { page in
                    AWSelectableChip(
                        title: pageLabel(for: page),
                        isSelected: selectedPageID == page.id,
                        tint: AyuWalkTheme.secondaryAccent
                    ) {
                        selectedPageID = page.id
                    }
                    .accessibilityLabel(pageLabel(for: page))
                }
            }
            .padding(.horizontal, 18)
        }
    }

    private func pageLabel(for page: JournalPage) -> String {
        switch page.kind {
        case .cover:
            return "封面"
        case .overview:
            return "总览"
        case .day:
            return page.title
        case .summary:
            return "总结"
        }
    }

    private func stickerTray(for page: JournalPage, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("贴纸")
                        .font(AyuWalkTypography.sectionTitle)
                        .foregroundStyle(AyuWalkTheme.ink)
                    Text("点按添加到当前页面，再在纸面上移动、旋转或缩放")
                        .font(AyuWalkTypography.micro)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                }

                Spacer()

                Text("\(appState.placedStickers(for: page).count) 个")
                    .font(AyuWalkTypography.microStrong)
                    .foregroundStyle(AyuWalkTheme.secondaryAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(AyuWalkTheme.secondaryAccent.opacity(0.10))
                    .clipShape(Capsule())

                Button {
                    isStickerInteracting = false
                    isStickerTrayVisible = false
                } label: {
                    Label("完成", systemImage: "checkmark.circle.fill")
                        .font(AyuWalkTypography.captionStrong)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(AyuWalkTheme.secondaryAccent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("退出贴纸编辑")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(stickerCategories) { category in
                        Button {
                            selectedStickerCategoryID = category.id
                        } label: {
                            Text(category.title)
                                .font(AyuWalkTypography.captionStrong)
                                .foregroundStyle(selectedStickerCategoryID == category.id ? .white : AyuWalkTheme.secondaryAccent)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background {
                                    if selectedStickerCategoryID == category.id {
                                        Capsule()
                                            .fill(AyuWalkTheme.secondaryAccent)
                                    } else {
                                        Capsule()
                                            .fill(AyuWalkTheme.pageBackground)

                                        Image.awPaperCardSurface
                                            .resizable(resizingMode: .tile)
                                            .opacity(AyuWalkTexture.cardOpacity)
                                            .blendMode(.multiply)
                                            .clipShape(Capsule())
                                    }
                                }
                                .clipShape(Capsule())
                                .overlay {
                                    Capsule()
                                        .stroke(
                                            selectedStickerCategoryID == category.id
                                                ? Color.clear
                                                : AyuWalkTheme.secondaryAccent.opacity(0.10),
                                            lineWidth: 1
                                        )
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(selectedStickerCategory?.stickers ?? []) { sticker in
                        stickerSource(sticker, page: page)
                    }

                    uploadStickerPicker
                }
                .padding(.vertical, 2)
            }
        }
        .padding(14)
        .frame(height: height, alignment: .top)
        .frame(maxWidth: .infinity)
        .background {
            AyuWalkTheme.surface.opacity(0.96)

            Image.awPaperCardSurface
                .resizable(resizingMode: .tile)
                .opacity(AyuWalkTexture.cardOpacity)
                .blendMode(.multiply)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AyuWalkTheme.hairline, lineWidth: 1)
        }
        .shadow(color: AyuWalkShadow.floating, radius: 20, x: 0, y: 10)
    }

    private var selectedStickerCategory: StickerCategory? {
        stickerCategories.first { $0.id == selectedStickerCategoryID }
            ?? stickerCategories.first
    }

    private var stickerCategories: [StickerCategory] {
        if let customStickerCategory = appState.customStickerCategory {
            return StickerLibrary.default.categories + [customStickerCategory]
        }

        return StickerLibrary.default.categories
    }

    private func stickerSource(_ sticker: Sticker, page: JournalPage) -> some View {
        Button {
            addStickerToCenter(sticker, on: page)
        } label: {
            VStack(spacing: 7) {
                stickerArtwork(for: sticker, size: 30)
                Text(sticker.title)
                    .font(AyuWalkTypography.microStrong)
                    .lineLimit(1)
            }
            .foregroundStyle(AyuWalkTheme.ink)
            .frame(width: 86, height: 70)
            .awPaperInsetBackground(
                cornerRadius: AyuWalkRadii.card,
                fill: AyuWalkTheme.surface.opacity(0.95),
                borderTint: AyuWalkTheme.accent,
                borderOpacity: 0.10
            )
            .shadow(color: AyuWalkShadow.journal, radius: 8, x: 0, y: 4)
            .contentShape(RoundedRectangle(cornerRadius: AyuWalkRadii.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 3, coordinateSpace: .global)
                .onEnded { value in
                    addSticker(sticker, to: page, at: value.location)
                }
        )
        .accessibilityLabel("添加\(sticker.title)贴纸")
    }

    private func addSticker(_ sticker: Sticker, to page: JournalPage, at location: CGPoint) {
        guard let frame = pageFrames[page.id], frame.contains(location) else {
            return
        }

        appState.addStickerPlacement(
            pageID: page.id,
            stickerID: sticker.id,
            xRatio: (location.x - frame.minX) / max(frame.width, 1),
            yRatio: (location.y - frame.minY) / max(frame.height, 1)
        )
    }

    private func addStickerToCenter(_ sticker: Sticker, on page: JournalPage) {
        appState.addStickerPlacement(
            pageID: page.id,
            stickerID: sticker.id,
            xRatio: 0.5,
            yRatio: 0.5
        )
    }

    private var uploadStickerPicker: some View {
        PhotosPicker(selection: $selectedStickerPhotoItem, matching: .images) {
            VStack(spacing: 7) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 22, weight: .bold))
                Text("上传")
                    .font(AyuWalkTypography.microStrong)
            }
            .foregroundStyle(AyuWalkTheme.mutedInk)
            .frame(width: 86, height: 70)
            .background {
                AyuWalkTheme.pageBackground.opacity(0.8)

                Image.awPaperCardSurface
                    .resizable(resizingMode: .tile)
                    .opacity(AyuWalkTexture.cardOpacity)
                    .blendMode(.multiply)
            }
            .clipShape(RoundedRectangle(cornerRadius: AyuWalkRadii.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AyuWalkRadii.card, style: .continuous)
                    .stroke(AyuWalkTheme.border, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("上传图片贴纸")
        .onChange(of: selectedStickerPhotoItem) { _, newValue in
            guard let newValue else {
                return
            }

            Task {
                await importStickerPhoto(newValue)
            }
        }
    }

    private func stickerArtwork(for sticker: Sticker, size: CGFloat) -> some View {
        Group {
            if let imageDataBase64 = sticker.imageDataBase64,
               let imageData = Data(base64Encoded: imageDataBase64),
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                Image(systemName: sticker.symbol)
                    .font(.system(size: 22, weight: .bold))
            }
        }
    }

    @MainActor
    private func importStickerPhoto(_ item: PhotosPickerItem) async {
        defer {
            selectedStickerPhotoItem = nil
        }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let compressedData = Self.compressedStickerData(from: data) else {
            return
        }

        appState.addCustomSticker(title: "自定义", imageData: compressedData)
        if let customStickerCategory = appState.customStickerCategory {
            selectedStickerCategoryID = customStickerCategory.id
        }
    }

    private static func compressedStickerData(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else {
            return nil
        }

        let maxSide: CGFloat = 320
        let longestSide = max(image.size.width, image.size.height)
        let scale = min(maxSide / max(longestSide, 1), 1)
        let targetSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resizedImage.pngData()
    }
}

#Preview {
    JournalPreviewView()
        .environment(AppState())
}

private struct JournalPageFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, newValue in newValue })
    }
}
