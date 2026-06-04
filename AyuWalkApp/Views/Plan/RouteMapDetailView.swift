import AyuWalkCore
import MapKit
import SwiftUI
import UniformTypeIdentifiers

struct RouteMapDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let days: [TripDay]
    let travelMinutesBeforeActivityID: [UUID: Int]
    let onReorder: ([UUID]) -> Void
    @State private var cameraPosition: MapCameraPosition
    @State private var routeItems: [RouteMapDetailItem]
    @State private var selectedDayNumber: Int
    @State private var draggingRouteItemID: UUID?

    init(
        days: [TripDay],
        initialDayNumber: Int? = nil,
        travelMinutesBeforeActivityID: [UUID: Int] = [:],
        onReorder: @escaping ([UUID]) -> Void = { _ in }
    ) {
        let items = Self.items(for: days, travelMinutesBeforeActivityID: travelMinutesBeforeActivityID)
        let selectedDayNumber = initialDayNumber ?? items.first?.dayNumber ?? 1
        let selectedItems = items.filter { $0.dayNumber == selectedDayNumber }
        self.days = days
        self.travelMinutesBeforeActivityID = travelMinutesBeforeActivityID
        self.onReorder = onReorder
        _routeItems = State(initialValue: items)
        _cameraPosition = State(initialValue: .region(Self.region(for: selectedItems.isEmpty ? items : selectedItems)))
        _selectedDayNumber = State(initialValue: selectedDayNumber)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $cameraPosition) {
                    if routeCoordinates.count > 1 {
                        MapPolyline(coordinates: routeCoordinates)
                            .stroke(AyuWalkTheme.secondaryAccent, lineWidth: 4)
                    }

                    ForEach(displayedRouteItems) { item in
                        if let coordinate = item.coordinate {
                            Annotation(item.title, coordinate: coordinate) {
                                mapMarker(for: item)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic, emphasis: .muted))
                .ignoresSafeArea(edges: .bottom)

                routeDrawer
            }
            .navigationTitle("路线地图")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func mapMarker(for item: RouteMapDetailItem) -> some View {
        VStack(spacing: 4) {
            markerBadge(for: item)

            Text(item.title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AyuWalkTheme.ink)
                .lineLimit(1)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(AyuWalkTheme.surface.opacity(0.94))
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private func markerBadge(for item: RouteMapDetailItem) -> some View {
        if item.isLocked {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(AyuWalkTheme.accent)
                .clipShape(Circle())
                .shadow(color: AyuWalkTheme.ink.opacity(0.18), radius: 8, y: 4)
        } else {
            Text(String(item.order ?? 0))
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(AyuWalkTheme.secondaryAccent)
                .clipShape(Circle())
                .shadow(color: AyuWalkTheme.ink.opacity(0.18), radius: 8, y: 4)
        }
    }

    private var routeDrawer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Capsule()
                .fill(AyuWalkTheme.hairline)
                .frame(width: 44, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 2)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day \(selectedDayNumber) 路线")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AyuWalkTheme.ink)
                    Text("普通点位可拖动排序，锁定节点保留固定时间")
                        .font(.caption)
                        .foregroundStyle(AyuWalkTheme.mutedInk)
                }

                Spacer()

                AWStatusPill(
                    text: "\(displayedRouteItems.filter { $0.coordinate != nil }.count) 点",
                    systemImage: "mappin.circle.fill",
                    tint: AyuWalkTheme.secondaryAccent
                )
            }

            dayPicker

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(displayedRouteItems) { item in
                        routeDraggableRow(item)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: 292)
        }
        .padding(16)
        .background(AyuWalkTheme.surface.opacity(0.98))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AyuWalkTheme.hairline, lineWidth: 1)
        }
        .shadow(color: AyuWalkTheme.softShadow, radius: 20, x: 0, y: 10)
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }

    private var dayPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(dayNumbers, id: \.self) { dayNumber in
                    Button {
                        selectedDayNumber = dayNumber
                        cameraPosition = .region(Self.region(for: routeItems.filter { $0.dayNumber == dayNumber }))
                    } label: {
                        Text("Day \(dayNumber)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(selectedDayNumber == dayNumber ? .white : AyuWalkTheme.secondaryAccent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedDayNumber == dayNumber ? AyuWalkTheme.accent : AyuWalkTheme.secondaryAccent.opacity(0.10))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func routeRow(_ item: RouteMapDetailItem) -> some View {
        HStack(spacing: 12) {
            routeRowBadge(for: item)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AyuWalkTheme.ink)
                    .lineLimit(1)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(AyuWalkTheme.mutedInk)
                    .lineLimit(1)
                if let travelText = item.travelText {
                    Label(travelText, systemImage: "figure.walk.motion")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AyuWalkTheme.secondaryAccent)
                        .lineLimit(1)
                }
            }

            Spacer()

            if item.isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AyuWalkTheme.accent)
            } else {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AyuWalkTheme.mutedInk)
            }
        }
        .padding(12)
        .background(item.isLocked ? AyuWalkTheme.accent.opacity(0.08) : AyuWalkTheme.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(item.isLocked ? AyuWalkTheme.accent : AyuWalkTheme.secondaryAccent)
                .frame(width: 4)
                .padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private func routeDraggableRow(_ item: RouteMapDetailItem) -> some View {
        let row = routeRow(item)
            .opacity(draggingRouteItemID == item.id ? 0.55 : 1)
            .animation(.easeInOut(duration: 0.16), value: draggingRouteItemID)

        if item.isLocked {
            row
        } else {
            row
                .onDrag {
                    draggingRouteItemID = item.id
                    return NSItemProvider(object: item.id.uuidString as NSString)
                } preview: {
                    routeRow(item)
                        .frame(width: 300)
                }
                .onDrop(of: [UTType.text], isTargeted: nil) { providers in
                    moveRouteItem(from: providers, before: item.id)
                }
        }
    }

    @ViewBuilder
    private func routeRowBadge(for item: RouteMapDetailItem) -> some View {
        if item.isLocked {
            Image(systemName: "lock.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(AyuWalkTheme.accent)
                .clipShape(Circle())
        } else {
            Text(String(item.order ?? 0))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(item.coordinate == nil ? AyuWalkTheme.mutedInk : AyuWalkTheme.secondaryAccent)
                .clipShape(Circle())
        }
    }

    private var displayedRouteItems: [RouteMapDetailItem] {
        var nextOrder = 1
        return routeItems.filter { $0.dayNumber == selectedDayNumber }.map { item in
            var updated = item
            if item.isLocked {
                updated.order = nil
            } else {
                updated.order = nextOrder
                nextOrder += 1
            }
            return updated
        }
    }

    private var routeCoordinates: [CLLocationCoordinate2D] {
        displayedRouteItems.compactMap(\.coordinate)
    }

    private var dayNumbers: [Int] {
        Array(Set(routeItems.map(\.dayNumber))).sorted()
    }

    private func moveRouteItem(from providers: [NSItemProvider], before targetID: UUID) -> Bool {
        guard let itemProvider = providers.first else {
            draggingRouteItemID = nil
            return false
        }

        itemProvider.loadObject(ofClass: NSString.self) { object, _ in
            guard let rawID = object as? String,
                  let draggedID = UUID(uuidString: rawID) else {
                DispatchQueue.main.async {
                    draggingRouteItemID = nil
                }
                return
            }

            DispatchQueue.main.async {
                moveRouteItem(draggedID: draggedID, before: targetID)
                draggingRouteItemID = nil
            }
        }

        return true
    }

    private func moveRouteItem(draggedID: UUID, before targetID: UUID) {
        guard draggedID != targetID else {
            return
        }

        var selectedItems = displayedRouteItems
        guard let sourceIndex = selectedItems.firstIndex(where: { $0.id == draggedID }),
              let destinationIndex = selectedItems.firstIndex(where: { $0.id == targetID }),
              !selectedItems[sourceIndex].isLocked,
              !selectedItems[destinationIndex].isLocked else {
            return
        }

        let movedItem = selectedItems.remove(at: sourceIndex)
        let adjustedDestinationIndex = sourceIndex < destinationIndex
            ? destinationIndex - 1
            : destinationIndex
        selectedItems.insert(movedItem, at: adjustedDestinationIndex)

        var nextOrder = 1
        selectedItems = selectedItems.map { item in
            var updated = item
            if updated.isLocked {
                updated.order = nil
            } else {
                updated.order = nextOrder
                nextOrder += 1
            }
            return updated
        }

        routeItems = dayNumbers.flatMap { dayNumber in
            dayNumber == selectedDayNumber
                ? selectedItems
                : routeItems.filter { $0.dayNumber == dayNumber }
        }
        onReorder(selectedItems.filter { !$0.isLocked }.map(\.id))
    }

    private static func items(
        for days: [TripDay],
        travelMinutesBeforeActivityID: [UUID: Int]
    ) -> [RouteMapDetailItem] {
        var pairs: [(day: TripDay, activity: Activity)] = []
        for day in days {
            for activity in DayRouteSequence.activities(in: day) {
                pairs.append((day: day, activity: activity))
            }
        }

        var items: [RouteMapDetailItem] = []
        for pair in pairs {
            let activity = pair.activity
            let coordinate: CLLocationCoordinate2D?
            if let latitude = activity.place?.latitude,
               let longitude = activity.place?.longitude {
                coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            } else {
                coordinate = nil
            }
            let timeText = activity.startTime ?? "时间待定"
            let subtitle = "\(pair.day.dateLabel) · \(timeText)"
            let title = activity.place?.name ?? activity.title
            let isLocked = ScheduleConflictDetector.isLockedFixedNode(activity)
            let travelText = travelMinutesBeforeActivityID[activity.id].map {
                TravelTimeFormatter.routeSegmentText(minutes: $0)
            }

            items.append(
                RouteMapDetailItem(
                    id: activity.id,
                    dayNumber: pair.day.dayNumber,
                    order: isLocked ? nil : activity.routeOrder,
                    title: title,
                    subtitle: subtitle,
                    travelText: travelText,
                    isLocked: isLocked,
                    coordinate: coordinate
                )
            )
        }

        return items
    }

    private static func region(for items: [RouteMapDetailItem]) -> MKCoordinateRegion {
        let routeItems = items.filter { !$0.isLocked && $0.coordinate != nil }
        let focusItems = routeItems.isEmpty ? items : routeItems
        let coordinates = focusItems.compactMap(\.coordinate)
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 35.6595, longitude: 139.7005),
                span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
            )
        }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        let minLatitude = latitudes.min() ?? 0
        let maxLatitude = latitudes.max() ?? 0
        let minLongitude = longitudes.min() ?? 0
        let maxLongitude = longitudes.max() ?? 0
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLatitude - minLatitude) * 3.6, 0.024),
            longitudeDelta: max((maxLongitude - minLongitude) * 3.6, 0.024)
        )
        let center = visibleRouteCenter(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2,
            span: span
        )

        return MKCoordinateRegion(center: center, span: span)
    }

    private static func visibleRouteCenter(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        span: MKCoordinateSpan
    ) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitude - span.latitudeDelta * 0.45,
            longitude: longitude
        )
    }
}

private struct RouteMapDetailItem: Identifiable, Equatable {
    let id: UUID
    let dayNumber: Int
    var order: Int?
    let title: String
    let subtitle: String
    let travelText: String?
    let isLocked: Bool
    let coordinate: CLLocationCoordinate2D?

    static func == (lhs: RouteMapDetailItem, rhs: RouteMapDetailItem) -> Bool {
        lhs.id == rhs.id
            && lhs.dayNumber == rhs.dayNumber
            && lhs.order == rhs.order
            && lhs.title == rhs.title
            && lhs.subtitle == rhs.subtitle
            && lhs.travelText == rhs.travelText
            && lhs.isLocked == rhs.isLocked
            && lhs.coordinate?.latitude == rhs.coordinate?.latitude
            && lhs.coordinate?.longitude == rhs.coordinate?.longitude
    }
}

#Preview {
    RouteMapDetailView(days: SampleTripFactory.tokyoFiveDayTrip().days)
}
