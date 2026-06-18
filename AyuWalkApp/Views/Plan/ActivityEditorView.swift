import AyuWalkCore
import SwiftUI

struct ActivityEditDraft: Equatable {
    var title: String
    var kind: ActivityKind
    var place: Place?
    var targetDayID: UUID
    var isIncludedInRoute: Bool
    var isFixedNode: Bool
    var startTime: String
    var endTime: String
    var notes: String
    var isReminderEnabled: Bool
    var reminderID: UUID?

    var normalizedStartTime: String? {
        normalized(startTime)
    }

    var normalizedEndTime: String? {
        normalized(endTime)
    }

    var normalizedNotes: String? {
        normalized(notes)
    }

    var reminder: Reminder? {
        guard isReminderEnabled else {
            return nil
        }

        let fireTime = normalizedStartTime ?? normalizedEndTime ?? "固定时间"
        return Reminder(
            id: reminderID ?? UUID(),
            fireTime: fireTime,
            note: "固定时间节点提醒"
        )
    }

    private func normalized(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct ActivityEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ActivityEditDraft
    @State private var placeQuery = ""
    @State private var placeResults: [Place] = []
    @State private var isSearchingPlaces = false

    let days: [TripDay]
    let activity: Activity
    let isCreating: Bool
    let onSearchPlaces: (String) async -> [Place]
    let onSave: (ActivityEditDraft) -> Void

    init(
        days: [TripDay],
        day: TripDay,
        activity: Activity,
        isCreating: Bool = false,
        onSearchPlaces: @escaping (String) async -> [Place] = { _ in [] },
        onSave: @escaping (ActivityEditDraft) -> Void
    ) {
        self.days = days
        self.activity = activity
        self.isCreating = isCreating
        self.onSearchPlaces = onSearchPlaces
        self.onSave = onSave
        _draft = State(
            initialValue: ActivityEditDraft(
                title: activity.title,
                kind: activity.kind,
                place: activity.place,
                targetDayID: day.id,
                isIncludedInRoute: activity.routeOrder != nil,
                isFixedNode: activity.isFixedNode,
                startTime: activity.startTime ?? "",
                endTime: activity.endTime ?? "",
                notes: activity.notes ?? "",
                isReminderEnabled: activity.reminder != nil || activity.kind == .transport,
                reminderID: activity.reminder?.id
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AyuWalkTheme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        headerCard
                        fieldCard
                        placementCard
                        reminderCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle(isCreating ? "新增日程" : "编辑日程")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button {
                    onSave(draft)
                    dismiss()
                } label: {
                    Text(isCreating ? "添加日程" : "保存修改")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AyuWalkTheme.mutedInk.opacity(0.35) : AyuWalkTheme.accent)
                        .clipShape(Capsule())
                }
                .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(AyuWalkTheme.pageBackground)
                .accessibilityLabel(isCreating ? "添加日程" : "保存修改")
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(selectedDayLabel)
                .font(.caption.weight(.bold))
                .foregroundStyle(AyuWalkTheme.secondaryAccent)
            Text(isCreating ? "安排新的行程项目" : activity.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(AyuWalkTheme.ink)
        }
        .card()
    }

    private var fieldCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("日程内容")
                .font(.headline.weight(.bold))
                .foregroundStyle(AyuWalkTheme.ink)

            labeledTextField("标题", text: $draft.title, placeholder: "例如 涩谷 City Walk")

            Picker("类型", selection: $draft.kind) {
                ForEach(ActivityKind.allCases, id: \.self) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            .tint(AyuWalkTheme.accent)

            HStack(spacing: 12) {
                labeledTextField("开始", text: $draft.startTime, placeholder: "10:00")
                labeledTextField("结束", text: $draft.endTime, placeholder: "11:30")
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("备注")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AyuWalkTheme.mutedInk)
                TextEditor(text: $draft.notes)
                    .font(.body)
                    .foregroundStyle(AyuWalkTheme.ink)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(10)
                    .awPaperInsetBackground(
                        cornerRadius: 14,
                        fill: AyuWalkTheme.pageBackground,
                        borderTint: AyuWalkTheme.secondaryAccent
                    )
            }
        }
        .card()
    }

    private var placementCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("地点与安排")
                .font(.headline.weight(.bold))
                .foregroundStyle(AyuWalkTheme.ink)

            Picker("所属日期", selection: $draft.targetDayID) {
                ForEach(days) { day in
                    Text("\(day.dateLabel) · \(day.title)").tag(day.id)
                }
            }
            .tint(AyuWalkTheme.accent)

            Toggle("加入当天路线", isOn: $draft.isIncludedInRoute)
                .tint(AyuWalkTheme.accent)
                .disabled(draft.isFixedNode)

            HStack(spacing: 8) {
                TextField("搜索地点", text: $placeQuery)
                    .textInputAutocapitalization(.never)
                    .padding(.vertical, 11)
                    .padding(.horizontal, 12)
                    .awPaperInsetBackground(
                        cornerRadius: AyuWalkRadii.card,
                        fill: AyuWalkTheme.pageBackground,
                        borderTint: AyuWalkTheme.secondaryAccent
                    )

                Button {
                    Task {
                        isSearchingPlaces = true
                        placeResults = await onSearchPlaces(placeQuery)
                        isSearchingPlaces = false
                    }
                } label: {
                    Image(systemName: isSearchingPlaces ? "hourglass" : "magnifyingglass")
                        .frame(width: AyuWalkSize.iconButton, height: AyuWalkSize.iconButton)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AyuWalkTheme.accent)
                .disabled(placeQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearchingPlaces)
                .accessibilityLabel("搜索地点")
            }

            if let place = draft.place {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(place.name)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AyuWalkTheme.ink)
                        if let address = place.address {
                            Text(address)
                                .font(.caption)
                                .foregroundStyle(AyuWalkTheme.mutedInk)
                        }
                    }
                    Spacer()
                    Button {
                        draft.place = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AyuWalkTheme.mutedInk)
                    .accessibilityLabel("移除地点")
                }
            }

            ForEach(placeResults) { place in
                Button {
                    draft.place = place
                    placeResults = []
                    placeQuery = place.name
                } label: {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(AyuWalkTheme.secondaryAccent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(place.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AyuWalkTheme.ink)
                            if let address = place.address {
                                Text(address)
                                    .font(.caption)
                                    .foregroundStyle(AyuWalkTheme.mutedInk)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .card()
    }

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "bell.badge")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AyuWalkTheme.secondaryAccent)
                    .frame(width: 32, height: 32)
                    .background {
                        Circle()
                            .fill(AyuWalkTheme.pageBackground)

                        Image.awPaperCardSurface
                            .resizable()
                            .scaledToFill()
                            .opacity(AyuWalkTexture.cardOpacity)
                            .blendMode(.multiply)
                            .clipShape(Circle())
                    }
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(AyuWalkTheme.secondaryAccent.opacity(0.10), lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text("固定时间提醒")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AyuWalkTheme.ink)
                    Text("适合机票、火车票、演唱会、餐厅预约这类不能随意移动的节点。")
                        .font(.caption)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                }

                Spacer()

                Toggle("", isOn: $draft.isReminderEnabled)
                    .labelsHidden()
                    .tint(AyuWalkTheme.accent)
            }

            Toggle("固定节点，不参与路线重排", isOn: $draft.isFixedNode)
                .tint(AyuWalkTheme.secondaryAccent)
                .onChange(of: draft.isFixedNode) { _, isFixed in
                    if isFixed {
                        draft.isIncludedInRoute = false
                        draft.isReminderEnabled = true
                    }
                }

            if draft.isReminderEnabled {
                Text("有具体出行日期时会安排系统通知；如果还没有日期，会先显示 App 内固定时间提示。")
                    .font(.caption)
                    .foregroundStyle(AyuWalkTheme.secondaryAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .awPaperInsetBackground(
                        cornerRadius: 12,
                        fill: AyuWalkTheme.pageBackground,
                        borderTint: AyuWalkTheme.secondaryAccent,
                        borderOpacity: 0.06
                    )
            }
        }
        .card()
    }

    private var selectedDayLabel: String {
        guard let day = days.first(where: { $0.id == draft.targetDayID }) else {
            return "选择日期"
        }
        return "\(day.dateLabel) · \(day.title)"
    }

    private func labeledTextField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(AyuWalkTheme.mutedInk)
            TextField(placeholder, text: text)
                .font(.body.weight(.semibold))
                .foregroundStyle(AyuWalkTheme.ink)
                .textInputAutocapitalization(.never)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .awPaperInsetBackground(
                    cornerRadius: 14,
                    fill: AyuWalkTheme.pageBackground,
                    borderTint: AyuWalkTheme.secondaryAccent
                )
        }
    }
}

private extension View {
    func card() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                AyuWalkTheme.paper

                Image.awPaperCardSurface
                    .resizable()
                    .scaledToFill()
                    .opacity(AyuWalkTexture.cardOpacity)
                    .blendMode(.multiply)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AyuWalkTheme.border, lineWidth: 1)
            }
    }
}

#Preview {
    let trip = SampleTripFactory.tokyoFiveDayTrip()
    ActivityEditorView(days: trip.days, day: trip.days[0], activity: trip.days[0].activities[0]) { _ in }
}

private extension ActivityKind {
    static var allCases: [ActivityKind] {
        [.sight, .meal, .hotel, .transport, .shopping, .concert, .freeTime, .note]
    }

    var displayName: String {
        switch self {
        case .sight: "景点"
        case .meal: "用餐"
        case .hotel: "酒店"
        case .transport: "交通"
        case .shopping: "购物"
        case .concert: "演出"
        case .freeTime: "自由时间"
        case .note: "备注"
        }
    }
}
