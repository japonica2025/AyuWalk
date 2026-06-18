import AyuWalkCore
import MapKit
import SwiftUI

struct RouteMapPreviewView: View {
    let days: [TripDay]
    var previewDayNumber: Int?

    private var previewDay: TripDay? {
        if let previewDayNumber,
           let day = days.first(where: { $0.dayNumber == previewDayNumber }) {
            return day
        }

        return days.first { day in
            day.activities.contains { activity in
                activity.routeOrder != nil
                    && activity.place?.latitude != nil
                    && activity.place?.longitude != nil
            }
        } ?? days.first
    }

    private var routeActivities: [Activity] {
        previewDay?
            .activities
            .filter { $0.routeOrder != nil }
            .sorted { ($0.routeOrder ?? Int.max) < ($1.routeOrder ?? Int.max) }
            ?? []
    }

    private var previewRouteActivities: [Activity] {
        routeActivities
    }

    var body: some View {
        AWHomeMapCard(
            title: "路线地图",
            subtitle: routeMapItems.isEmpty ? "缺少坐标时展示路线顺序" : "仅预览当天路线，完整路线点进地图查看"
        ) {
            AWStatusPill(text: routeOrderText, systemImage: "map.fill", tint: AyuWalkTheme.accent)
        } content: {
            if routeMapItems.isEmpty {
                fallbackRoutePreview
                    .frame(height: 168)
            } else {
                mapPreview
                    .frame(height: 188)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(alignment: .bottomLeading) {
                        routeLegend
                    }
            }
        } footer: {
            if let previewDay {
                Text("\(previewDay.dateLabel) · \(previewDay.title)")
                    .font(AyuWalkTypography.bodyStrong)
                    .foregroundStyle(AyuWalkTheme.ink)
            }
        }
    }

    private var mapPreview: some View {
        Map(initialPosition: .region(mapRegion)) {
            if routeCoordinates.count > 1 {
                MapPolyline(coordinates: routeCoordinates)
                    .stroke(AyuWalkTheme.accent, lineWidth: 4)
            }

            ForEach(routeMapItems) { item in
                Annotation(item.title, coordinate: item.coordinate) {
                    VStack(spacing: 4) {
                        AWMapMarkerBadge(text: String(item.order), tint: AyuWalkTheme.accent)
                        AWMapFloatingLabel(text: item.title)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted))
        .allowsHitTesting(false)
    }

    private var routeLegend: some View {
        AWMapFloatingLabel(text: "\(previewDay?.dateLabel ?? "路线") · \(routeMapItems.count) 个点位")
            .padding(10)
    }

    private var fallbackRoutePreview: some View {
        GeometryReader { proxy in
            let points = previewPoints(in: proxy.size)

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AyuWalkTheme.elevated)
                    .overlay {
                        Image.awPaperCardSurface
                            .resizable()
                            .scaledToFill()
                            .opacity(AyuWalkTexture.cardOpacity)
                            .blendMode(.multiply)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .overlay(alignment: .topLeading) {
                        Image.awWashiTapeCream
                            .resizable()
                            .scaledToFit()
                            .frame(width: 58, height: 20)
                            .rotationEffect(.degrees(-7))
                            .opacity(0.42)
                            .offset(x: 18, y: -8)
                            .allowsHitTesting(false)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AyuWalkTheme.border, lineWidth: 1)
                    }

                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(
                    AyuWalkTheme.accent,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [8, 6])
                )

                ForEach(Array(previewRouteActivities.enumerated()), id: \.element.id) { index, activity in
                    routePoint(activity: activity, fallbackIndex: index + 1)
                        .position(points[safe: index] ?? .zero)
                }
            }
        }
    }

    private func routePoint(activity: Activity, fallbackIndex: Int) -> some View {
        VStack(spacing: 5) {
            AWMapMarkerBadge(text: String(fallbackIndex), tint: AyuWalkTheme.accent, size: 28)

            Text(activity.title)
                .font(AyuWalkTypography.microStrong)
                .foregroundStyle(AyuWalkTheme.ink)
                .lineLimit(1)
                .frame(width: 88)
        }
    }

    private var routeMapItems: [RouteMapItem] {
        guard let previewDay else {
            return []
        }

        let mapReadyActivities = previewDay.activities.filter { activity in
            activity.routeOrder != nil
                && activity.place?.latitude != nil
                && activity.place?.longitude != nil
        }
        .sorted { ($0.routeOrder ?? Int.max) < ($1.routeOrder ?? Int.max) }

        return mapReadyActivities.enumerated().compactMap { index, activity in
            guard let latitude = activity.place?.latitude,
                  let longitude = activity.place?.longitude else {
                return nil
            }

            return RouteMapItem(
                id: activity.id,
                order: index + 1,
                title: activity.place?.name ?? activity.title,
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            )
        }
    }

    private var routeCoordinates: [CLLocationCoordinate2D] {
        routeMapItems.map(\.coordinate)
    }

    private var routeOrderText: String {
        guard let previewDay else {
            return "路线"
        }
        return "\(previewDay.dateLabel)"
    }

    private var mapRegion: MKCoordinateRegion {
        guard !routeCoordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 35.6595, longitude: 139.7005),
                span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
            )
        }

        let latitudes = routeCoordinates.map(\.latitude)
        let longitudes = routeCoordinates.map(\.longitude)
        let minLatitude = latitudes.min() ?? 0
        let maxLatitude = latitudes.max() ?? 0
        let minLongitude = longitudes.min() ?? 0
        let maxLongitude = longitudes.max() ?? 0
        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLatitude - minLatitude) * 3.2, 0.018),
            longitudeDelta: max((maxLongitude - minLongitude) * 3.2, 0.018)
        )

        return MKCoordinateRegion(center: center, span: span)
    }

    private func previewPoints(in size: CGSize) -> [CGPoint] {
        let count = max(previewRouteActivities.count, 1)
        guard count > 1 else {
            return [CGPoint(x: 0.5 * size.width, y: 0.5 * size.height)]
        }

        return (0..<count).map { index in
            let progress = CGFloat(index) / CGFloat(count - 1)
            let x = 0.14 + progress * 0.72
            let y = 0.54 + sin(progress * .pi * 3) * 0.22
            return CGPoint(x: x * size.width, y: y * size.height)
        }
    }
}

private struct RouteMapItem: Identifiable {
    let id: UUID
    let order: Int
    let title: String
    let coordinate: CLLocationCoordinate2D
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    RouteMapPreviewView(days: SampleTripFactory.tokyoFiveDayTrip().days)
        .padding()
        .background(AyuWalkTheme.pageBackground)
}
