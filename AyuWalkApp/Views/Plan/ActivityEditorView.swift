import AyuWalkCore
import SwiftUI

struct ActivityEditDraft: Equatable {
    var title: String
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

    let day: TripDay
    let activity: Activity
    let onSave: (ActivityEditDraft) -> Void

    init(day: TripDay, activity: Activity, onSave: @escaping (ActivityEditDraft) -> Void) {
        self.day = day
        self.activity = activity
        self.onSave = onSave
        _draft = State(
            initialValue: ActivityEditDraft(
                title: activity.title,
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
                        reminderCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle("编辑日程")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button {
                    onSave(draft)
                    dismiss()
                } label: {
                    Text("保存修改")
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
                .accessibilityLabel("保存修改")
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(day.dateLabel) · \(day.title)")
                .font(.caption.weight(.bold))
                .foregroundStyle(AyuWalkTheme.secondaryAccent)
            Text(activity.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(AyuWalkTheme.ink)
            Text("先支持标题、时间和备注，后续再接地点搜索与地图顺序调整。")
                .font(.callout)
                .foregroundStyle(AyuWalkTheme.mutedInk)
        }
        .card()
    }

    private var fieldCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("日程内容")
                .font(.headline.weight(.bold))
                .foregroundStyle(AyuWalkTheme.ink)

            labeledTextField("标题", text: $draft.title, placeholder: "例如 涩谷 City Walk")

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
                    .background(AyuWalkTheme.pageBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                    .background(AyuWalkTheme.pageBackground)
                    .clipShape(Circle())

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

            if draft.isReminderEnabled {
                Text("有具体出行日期时会安排系统通知；如果还没有日期，会先显示 App 内固定时间提示。")
                    .font(.caption)
                    .foregroundStyle(AyuWalkTheme.secondaryAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(AyuWalkTheme.pageBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .card()
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
                .background(AyuWalkTheme.pageBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

private extension View {
    func card() -> some View {
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

#Preview {
    let trip = SampleTripFactory.tokyoFiveDayTrip()
    ActivityEditorView(day: trip.days[0], activity: trip.days[0].activities[0]) { _ in }
}
