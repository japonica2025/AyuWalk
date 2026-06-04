import AyuWalkCore
import SwiftUI

struct CreateTripDraft: Equatable {
    var destination: String
    var destinationLocation: DestinationLocation?
    var dayCount: Int
    var duration: TripDuration
    var purpose: TravelPurpose
    var notes: String
    var importedSource: ImportedSource?
}

struct CreateTripView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var destination = "大阪"
    @State private var dayCount = 3
    @State private var durationMode: CreateDurationMode = .dayCount
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
    @State private var purpose: TravelPurpose = .food
    @State private var notes = "想轻松吃喝逛街，节奏不要太赶"
    @State private var mode: CreateTripMode = .manual
    @State private var importedText = """
6月2日 航班到达关西机场 09:00
6月2日 酒店入住 15:00
6月4日 酒店退房 11:00
6月4日 返程航班从关西机场出发 19:30
黑门市场、道顿堀、梅田夜景，想要美食和轻松 city walk
"""
    @State private var ambiguousDestinations: [DestinationLocation] = []

    let onGenerate: (CreateTripDraft) -> Void

    var body: some View {
        ZStack {
            AyuWalkTheme.pageBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        heroCard
                        modeCard
                        tripBasicsCard
                        purposeCard
                        if mode == .manual {
                            notesCard
                        } else {
                            importCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                generateButton
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
            }
            .background(.ultraThinMaterial)
        }
        .confirmationDialog("请选择目的地", isPresented: ambiguousDestinationBinding, titleVisibility: .visible) {
            ForEach(ambiguousDestinations, id: \.displayName) { option in
                Button(option.displayName) {
                    generate(with: option.displayName, destinationLocation: option)
                }
            }

            Button("取消", role: .cancel) {
                ambiguousDestinations = []
            }
        } message: {
            Text("这个目的地可能指向国家或省级地区，需要先确认。")
        }
        .onChange(of: dayCount) { _, newValue in
            let normalized = TripPlanningLimits.normalizedDayCount(newValue)
            if normalized != newValue {
                dayCount = normalized
            }
        }
        .onChange(of: startDate) { _, _ in
            normalizeDateRange()
        }
        .onChange(of: endDate) { _, _ in
            normalizeDateRange()
        }
    }

    private var normalizedDestination: String {
        destination.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var ambiguousDestinationBinding: Binding<Bool> {
        Binding(
            get: { !ambiguousDestinations.isEmpty },
            set: { isPresented in
                if !isPresented {
                    ambiguousDestinations = []
                }
            }
        )
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("创建新行程")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AyuWalkTheme.ink)
                Text("先生成一个可调整的初版")
                    .font(.subheadline)
                    .foregroundStyle(AyuWalkTheme.mutedInk)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AyuWalkTheme.ink)
                    .frame(width: 36, height: 36)
                    .background(AyuWalkTheme.paper)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(AyuWalkTheme.border, lineWidth: 1)
                    }
            }
            .accessibilityLabel("取消")
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 14)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ayu Walk")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AyuWalkTheme.secondaryAccent)
            Text("把零散想法先织成一段路线")
                .font(.title3.weight(.bold))
                .foregroundStyle(AyuWalkTheme.ink)
            Text("AI 会结合目的地、天数、导入资料和 MapKit 坐标，先生成可编辑的初版路线。")
                .font(.subheadline)
                .foregroundStyle(AyuWalkTheme.mutedInk)
                .lineSpacing(3)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AyuWalkTheme.paper)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AyuWalkTheme.border, lineWidth: 1)
        }
    }

    private var modeCard: some View {
        HStack(spacing: 10) {
            modeButton(.manual, title: "手动 + AI", systemImage: "pencil.and.scribble")
            modeButton(.importMaterial, title: "导入资料", systemImage: "doc.text.image.fill")
        }
        .cardStyle()
    }

    private var tripBasicsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("旅行信息")

            VStack(alignment: .leading, spacing: 8) {
                Text("目的地")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AyuWalkTheme.mutedInk)
                HStack(spacing: 8) {
                    TextField("例如 大阪、北京、蒙古", text: $destination)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AyuWalkTheme.ink)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled()
                        .submitLabel(.done)

                    if !destination.isEmpty {
                        Button {
                            destination = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(AyuWalkTheme.mutedInk)
                        }
                        .accessibilityLabel("清空目的地")
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(AyuWalkTheme.pageBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                HStack(spacing: 8) {
                    destinationButton(label: "大阪", value: "Osaka, Japan")
                    destinationButton(label: "巴黎", value: "Paris, France")
                    destinationButton(label: "伦敦", value: "London, United Kingdom")
                    destinationButton(label: "蒙古", value: "蒙古")
                }
            }

            HStack(spacing: 12) {
                durationModeButton(.dayCount, title: "按天数")
                durationModeButton(.dateRange, title: "按日期")
            }

            if durationMode == .dayCount {
                dayCountControl
            } else {
                dateRangeControl
            }

            Text("最多 \(TripPlanningLimits.maximumDayCount) 天")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AyuWalkTheme.mutedInk)
        }
        .cardStyle()
    }

    private var dayCountControl: some View {
        HStack(spacing: 12) {
            Text("旅行天数")
                .font(.body.weight(.semibold))
                .foregroundStyle(AyuWalkTheme.ink)

            Spacer()

            dayButton(
                systemImage: "minus",
                isDisabled: dayCount <= TripPlanningLimits.minimumDayCount
            ) {
                dayCount = max(TripPlanningLimits.minimumDayCount, dayCount - 1)
            }

            Text("\(effectiveDayCount) 天")
                .font(.title3.weight(.bold))
                .foregroundStyle(AyuWalkTheme.ink)
                .frame(width: 68)

            dayButton(
                systemImage: "plus",
                isDisabled: dayCount >= TripPlanningLimits.maximumDayCount
            ) {
                dayCount = min(TripPlanningLimits.maximumDayCount, dayCount + 1)
            }
        }
    }

    private var dateRangeControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            DatePicker(
                "出发日期",
                selection: $startDate,
                displayedComponents: .date
            )
            .font(.body.weight(.semibold))
            .foregroundStyle(AyuWalkTheme.ink)

            DatePicker(
                "结束日期",
                selection: $endDate,
                displayedComponents: .date
            )
            .font(.body.weight(.semibold))
            .foregroundStyle(AyuWalkTheme.ink)

            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.caption.weight(.bold))
                Text("将生成 \(effectiveDayCount) 天行程，并启用真实倒计时计算")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(AyuWalkTheme.secondaryAccent)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(AyuWalkTheme.pageBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var effectiveDayCount: Int {
        switch durationMode {
        case .dayCount:
            return TripPlanningLimits.normalizedDayCount(dayCount)
        case .dateRange:
            return TripPlanningLimits.normalizedDayCount(rawDateRangeDayCount)
        }
    }

    private var rawDateRangeDayCount: Int {
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.startOfDay(for: endDate)
        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
        return days + 1
    }

    private var effectiveDuration: TripDuration {
        switch durationMode {
        case .dayCount:
            return .dayCount(effectiveDayCount)
        case .dateRange:
            return .dateRange(
                start: Calendar.current.startOfDay(for: startDate),
                end: Calendar.current.startOfDay(for: endDate)
            )
        }
    }

    private func normalizeDateRange() {
        let calendar = Calendar.current
        let normalizedStart = calendar.startOfDay(for: startDate)
        let normalizedEnd = calendar.startOfDay(for: endDate)
        if normalizedEnd < normalizedStart {
            endDate = normalizedStart
            return
        }

        let maxEndDate = calendar.date(
            byAdding: .day,
            value: TripPlanningLimits.maximumDayCount - 1,
            to: normalizedStart
        ) ?? normalizedStart

        if normalizedEnd > maxEndDate {
            endDate = maxEndDate
        }
    }

    private func durationModeButton(_ item: CreateDurationMode, title: String) -> some View {
        Button {
            durationMode = item
            if item == .dateRange {
                normalizeDateRange()
            }
        } label: {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(durationMode == item ? .white : AyuWalkTheme.secondaryAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(durationMode == item ? AyuWalkTheme.secondaryAccent : AyuWalkTheme.pageBackground)
                .clipShape(Capsule())
        }
    }

    private var purposeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("旅行目的")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10) {
                ForEach(TravelPurpose.allCases, id: \.self) { item in
                    Button {
                        purpose = item
                    } label: {
                        Text(item.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(purpose == item ? .white : AyuWalkTheme.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(purpose == item ? AyuWalkTheme.accent : AyuWalkTheme.pageBackground)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .cardStyle()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("简单想法")

            TextEditor(text: $notes)
                .font(.body)
                .foregroundStyle(AyuWalkTheme.ink)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 128)
                .padding(10)
                .background(AyuWalkTheme.pageBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .cardStyle()
    }

    private var importCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("导入资料")
                Spacer()
                Text("AI 辅助")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AyuWalkTheme.secondaryAccent)
                    .clipShape(Capsule())
            }

            Text("先支持粘贴攻略、订单、酒店或航程文本；截图和链接识别会继续接入多模态流程。")
                .font(.caption)
                .foregroundStyle(AyuWalkTheme.mutedInk)

            TextEditor(text: $importedText)
                .font(.body)
                .foregroundStyle(AyuWalkTheme.ink)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 150)
                .padding(10)
                .background(AyuWalkTheme.pageBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            HStack(spacing: 8) {
                Label("文本攻略", systemImage: "text.alignleft")
                Label("截图识别预留", systemImage: "camera.viewfinder")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(AyuWalkTheme.secondaryAccent)
        }
        .cardStyle()
    }


    private var generateButton: some View {
        Button {
            submit()
        } label: {
            Text("生成行程")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(normalizedDestination.isEmpty ? AyuWalkTheme.mutedInk.opacity(0.35) : AyuWalkTheme.accent)
                .clipShape(Capsule())
                .shadow(color: AyuWalkTheme.accent.opacity(normalizedDestination.isEmpty ? 0 : 0.18), radius: 16, y: 8)
        }
        .disabled(normalizedDestination.isEmpty)
        .accessibilityLabel("生成行程")
    }

    private func submit() {
        switch DestinationResolver.resolve(normalizedDestination) {
        case let .resolved(location):
            generate(with: location.displayName, destinationLocation: location)
        case let .ambiguous(options):
            ambiguousDestinations = options
        case .unresolved:
            generate(with: normalizedDestination, destinationLocation: nil)
        }
    }

    private func generate(with destination: String, destinationLocation: DestinationLocation?) {
        onGenerate(
            CreateTripDraft(
                destination: destination,
                destinationLocation: destinationLocation,
                dayCount: effectiveDayCount,
                duration: effectiveDuration,
                purpose: purpose,
                notes: effectiveNotes,
                importedSource: importedSource
            )
        )
        dismiss()
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(AyuWalkTheme.ink)
    }

    private var effectiveNotes: String {
        switch mode {
        case .manual:
            return notes.trimmingCharacters(in: .whitespacesAndNewlines)
        case .importMaterial:
            return "根据导入资料生成初版行程"
        }
    }

    private var importedSource: ImportedSource? {
        guard mode == .importMaterial else {
            return nil
        }

        let text = importedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return nil
        }

        return ImportedSource(
            id: UUID(),
            kind: .pastedText,
            title: "导入资料",
            url: nil,
            extractedText: text
        )
    }

    private func modeButton(_ item: CreateTripMode, title: String, systemImage: String) -> some View {
        Button {
            mode = item
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(mode == item ? .white : AyuWalkTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(mode == item ? AyuWalkTheme.accent : AyuWalkTheme.pageBackground)
            .clipShape(Capsule())
        }
    }

    private func dayButton(
        systemImage: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isDisabled ? AyuWalkTheme.mutedInk.opacity(0.45) : AyuWalkTheme.secondaryAccent)
                .frame(width: 34, height: 34)
                .background(AyuWalkTheme.pageBackground)
                .clipShape(Circle())
        }
        .disabled(isDisabled)
    }

    private func destinationButton(label: String, value: String) -> some View {
        Button {
            destination = value
        } label: {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(destination == value ? .white : AyuWalkTheme.secondaryAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(destination == value ? AyuWalkTheme.secondaryAccent : AyuWalkTheme.pageBackground)
                .clipShape(Capsule())
        }
    }
}

private enum CreateTripMode: Equatable {
    case manual
    case importMaterial
}

private enum CreateDurationMode: Equatable {
    case dayCount
    case dateRange
}

private extension View {
    func cardStyle() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AyuWalkTheme.paper)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AyuWalkTheme.border, lineWidth: 1)
            }
    }
}

private extension TravelPurpose {
    var displayName: String {
        switch self {
        case .concert:
            return "演唱会"
        case .honeymoon:
            return "蜜月"
        case .family:
            return "亲子游"
        case .friends:
            return "好友出行"
        case .cityWalk:
            return "City Walk"
        case .shopping:
            return "购物"
        case .food:
            return "美食"
        }
    }
}

#Preview {
    CreateTripView { _ in }
}
