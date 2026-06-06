import Foundation

public enum SampleTripFactory {
    public static func trip(for destination: String, dayCount: Int = 1) -> Trip {
        if destination.localizedStandardContains("大阪")
            || destination.localizedCaseInsensitiveContains("osaka") {
            return osakaThreeDayTrip()
        }

        if destination.localizedStandardContains("东京")
            || destination.localizedStandardContains("東京")
            || destination.localizedCaseInsensitiveContains("tokyo") {
            return tokyoFiveDayTrip()
        }

        return unresolvedTrip(destination: destination, dayCount: dayCount)
    }

    public static func tokyoFiveDayTrip() -> Trip {
        let shibuya = Place(
            id: uuid("00000000-0000-0000-0000-000000000101"),
            name: "涩谷",
            address: "Shibuya City, Tokyo",
            latitude: 35.6595,
            longitude: 139.7005,
            providerIDs: [.mapKit: "sample-shibuya"]
        )

        let harajuku = Place(
            id: uuid("00000000-0000-0000-0000-000000000102"),
            name: "原宿",
            address: "Jingumae, Shibuya City, Tokyo",
            latitude: 35.6702,
            longitude: 139.7027,
            providerIDs: [.mapKit: "sample-harajuku"]
        )

        let dayOne = TripDay(
            id: uuid("00000000-0000-0000-0000-000000000201"),
            dayNumber: 1,
            dateLabel: "Day 1",
            title: "涩谷 - 原宿",
            activities: [
                Activity(
                    id: uuid("00000000-0000-0000-0000-000000000301"),
                    title: "涩谷 City Walk",
                    kind: .sight,
                    place: shibuya,
                    startTime: nil,
                    endTime: nil,
                    notes: nil,
                    estimatedCost: nil,
                    routeOrder: 1,
                    reminder: nil
                ),
                Activity(
                    id: uuid("00000000-0000-0000-0000-000000000302"),
                    title: "原宿散步",
                    kind: .sight,
                    place: harajuku,
                    startTime: nil,
                    endTime: nil,
                    notes: nil,
                    estimatedCost: nil,
                    routeOrder: 2,
                    reminder: nil
                )
            ]
        )

        return Trip(
            id: uuid("00000000-0000-0000-0000-000000000001"),
            title: "东京 5 日旅行",
            englishProductName: "Ayu Walk",
            destination: "东京",
            purpose: [.cityWalk, .food],
            duration: .dayCount(5),
            days: [dayOne],
            participants: [
                Participant(
                    id: uuid("00000000-0000-0000-0000-000000000401"),
                    name: "我",
                    role: nil
                ),
                Participant(
                    id: uuid("00000000-0000-0000-0000-000000000402"),
                    name: "朋友",
                    role: nil
                )
            ],
            importedSources: [],
            budgetPlan: BudgetPlan(total: 12000, currencyCode: "JPY"),
            packingList: PackingList(items: [
                PackingItem(
                    id: uuid("00000000-0000-0000-0000-000000000501"),
                    title: "护照",
                    isPacked: false,
                    notes: nil
                ),
                PackingItem(
                    id: uuid("00000000-0000-0000-0000-000000000502"),
                    title: "充电器",
                    isPacked: false,
                    notes: nil
                )
            ]),
            journalPages: [],
            planningScripts: [
                PlanningScript(
                    id: uuid("00000000-0000-0000-0000-000000000601"),
                    name: "编号路线点",
                    summary: "按当天活动顺序给地图点位添加 1、2、3 编号。"
                )
            ]
        )
    }

    public static func osakaThreeDayTrip() -> Trip {
        let kuromonMarket = Place(
            id: uuid("00000000-0000-0000-0000-000000000111"),
            name: "黑门市场",
            address: "Nippombashi, Chuo Ward, Osaka",
            latitude: 34.6653,
            longitude: 135.5061,
            providerIDs: [.mapKit: "sample-kuromon-market"]
        )

        let dotonbori = Place(
            id: uuid("00000000-0000-0000-0000-000000000112"),
            name: "道顿堀",
            address: "Dotonbori, Chuo Ward, Osaka",
            latitude: 34.6687,
            longitude: 135.5013,
            providerIDs: [.mapKit: "sample-dotonbori"]
        )

        let umedaSkyBuilding = Place(
            id: uuid("00000000-0000-0000-0000-000000000113"),
            name: "梅田蓝天大厦",
            address: "Oyodonaka, Kita Ward, Osaka",
            latitude: 34.7053,
            longitude: 135.4896,
            providerIDs: [.mapKit: "sample-umeda-sky-building"]
        )

        let dayOne = TripDay(
            id: uuid("00000000-0000-0000-0000-000000000211"),
            dayNumber: 1,
            dateLabel: "Day 1",
            title: "黑门市场 - 道顿堀",
            activities: [
                Activity(
                    id: uuid("00000000-0000-0000-0000-000000000311"),
                    title: "黑门市场午餐",
                    kind: .meal,
                    place: kuromonMarket,
                    startTime: "11:30",
                    endTime: "13:00",
                    notes: "适合作为抵达后的轻松美食起点",
                    estimatedCost: 300,
                    routeOrder: 1,
                    reminder: nil
                ),
                Activity(
                    id: uuid("00000000-0000-0000-0000-000000000312"),
                    title: "道顿堀散步",
                    kind: .sight,
                    place: dotonbori,
                    startTime: "15:00",
                    endTime: "17:30",
                    notes: "晚餐前保留拍照和逛街时间",
                    estimatedCost: 0,
                    routeOrder: 2,
                    reminder: nil
                ),
                Activity(
                    id: uuid("00000000-0000-0000-0000-000000000313"),
                    title: "梅田夜景",
                    kind: .sight,
                    place: umedaSkyBuilding,
                    startTime: "19:00",
                    endTime: "20:30",
                    notes: "如果当天太累，可以和第二天行程互换",
                    estimatedCost: 150,
                    routeOrder: 3,
                    reminder: nil
                )
            ]
        )

        return Trip(
            id: uuid("00000000-0000-0000-0000-000000000011"),
            title: "大阪 3 日旅行",
            englishProductName: "Ayu Walk",
            destination: "大阪",
            purpose: [.friends, .food],
            duration: .dayCount(3),
            days: [dayOne],
            participants: [
                Participant(
                    id: uuid("00000000-0000-0000-0000-000000000411"),
                    name: "我",
                    role: nil
                ),
                Participant(
                    id: uuid("00000000-0000-0000-0000-000000000412"),
                    name: "朋友",
                    role: nil
                )
            ],
            importedSources: [],
            budgetPlan: BudgetPlan(total: 9000, currencyCode: "JPY"),
            packingList: PackingList(items: [
                PackingItem(
                    id: uuid("00000000-0000-0000-0000-000000000511"),
                    title: "护照",
                    isPacked: false,
                    notes: nil
                ),
                PackingItem(
                    id: uuid("00000000-0000-0000-0000-000000000512"),
                    title: "充电器",
                    isPacked: false,
                    notes: nil
                ),
                PackingItem(
                    id: uuid("00000000-0000-0000-0000-000000000513"),
                    title: "零钱包",
                    isPacked: false,
                    notes: "适合市场和小店支付"
                )
            ]),
            journalPages: [],
            planningScripts: [
                PlanningScript(
                    id: uuid("00000000-0000-0000-0000-000000000611"),
                    name: "目的地样例定位",
                    summary: "根据用户输入目的地切换地图样例点，避免显示错误城市。"
                ),
                PlanningScript(
                    id: uuid("00000000-0000-0000-0000-000000000612"),
                    name: "编号路线点",
                    summary: "按当天活动顺序给地图点位添加 1、2、3 编号。"
                )
            ]
        )
    }

    public static func localizedTrip(
        destination: String,
        dayCount: Int,
        location: DestinationLocation
    ) -> Trip {
        let normalizedDayCount = TripPlanningLimits.normalizedDayCount(dayCount)
        let safeDestination = destination.isEmpty ? location.displayName : destination
        let days = (1...normalizedDayCount).map { dayNumber in
            localizedDay(
                destination: safeDestination,
                dayNumber: dayNumber,
                location: location
            )
        }

        return Trip(
            id: uuid("00000000-0000-0000-0000-000000000021"),
            title: "\(safeDestination) \(normalizedDayCount) 日旅行",
            englishProductName: "Ayu Walk",
            destination: safeDestination,
            purpose: [.cityWalk],
            duration: .dayCount(normalizedDayCount),
            days: days,
            participants: [
                Participant(
                    id: uuid("00000000-0000-0000-0000-000000000421"),
                    name: "我",
                    role: nil
                )
            ],
            importedSources: [],
            budgetPlan: BudgetPlan(total: Decimal(normalizedDayCount * 2500), currencyCode: location.currencyCode),
            packingList: PackingList(items: [
                PackingItem(
                    id: uuid("00000000-0000-0000-0000-000000000521"),
                    title: "证件",
                    isPacked: false,
                    notes: nil
                ),
                PackingItem(
                    id: uuid("00000000-0000-0000-0000-000000000522"),
                    title: "充电器",
                    isPacked: false,
                    notes: nil
                )
            ]),
            journalPages: [],
            planningScripts: [
                PlanningScript(
                    id: uuid("00000000-0000-0000-0000-000000000621"),
                    name: "目的地定位",
                    summary: "先解析用户输入目的地坐标，再围绕该坐标生成路线点。"
                ),
                PlanningScript(
                    id: uuid("00000000-0000-0000-0000-000000000622"),
                    name: "编号路线点",
                    summary: "按当天活动顺序给地图点位添加 1、2、3 编号。"
                )
            ]
        )
    }

    public static func trip(destination: String, dayCount: Int, places: [Place]) -> Trip {
        let normalizedDayCount = TripPlanningLimits.normalizedDayCount(dayCount)
        let safeDestination = destination.isEmpty ? "未命名目的地" : destination
        let dayPlaceGroups = split(places, into: normalizedDayCount).enumerated().map { dayIndex, dayPlaces in
            dayPlaces.isEmpty
                ? [placeholderPlace(destination: safeDestination, dayNumber: dayIndex + 1, slotName: "上午活动", anchorPlaces: places)]
                : dayPlaces
        }
        let days = dayPlaceGroups.enumerated().map { dayIndex, dayPlaces in
            let dayNumber = dayIndex + 1
            let activities = dailyTemplateActivities(
                destination: safeDestination,
                dayNumber: dayNumber,
                dayPlaces: dayPlaces,
                anchorPlaces: places
            )

            let dayTitle = dayPlaces
                .prefix(3)
                .map(\.name)
                .joined(separator: " - ")

            return TripDay(
                id: deterministicUUID(namespace: "resolved-day", value: "\(safeDestination)-\(dayIndex + 1)"),
                dayNumber: dayNumber,
                dateLabel: "Day \(dayNumber)",
                title: dayTitle.isEmpty ? "\(safeDestination) Day \(dayNumber)" : dayTitle,
                activities: activities
            )
        }

        return Trip(
            id: deterministicUUID(namespace: "resolved-trip", value: "\(safeDestination)-\(normalizedDayCount)"),
            title: "\(safeDestination) \(normalizedDayCount) 日旅行",
            englishProductName: "Ayu Walk",
            destination: safeDestination,
            purpose: [.cityWalk],
            duration: .dayCount(normalizedDayCount),
            days: days,
            participants: [
                Participant(
                    id: deterministicUUID(namespace: "resolved-participant", value: safeDestination),
                    name: "我",
                    role: nil
                )
            ],
            importedSources: [],
            budgetPlan: BudgetPlan(total: Decimal(normalizedDayCount * 2500), currencyCode: currencyCode(for: safeDestination)),
            packingList: PackingList(items: [
                PackingItem(
                    id: deterministicUUID(namespace: "resolved-packing", value: "\(safeDestination)-id"),
                    title: "证件",
                    isPacked: false,
                    notes: nil
                ),
                PackingItem(
                    id: deterministicUUID(namespace: "resolved-packing", value: "\(safeDestination)-charger"),
                    title: "充电器",
                    isPacked: false,
                    notes: nil
                )
            ]),
            journalPages: [],
            planningScripts: [
                PlanningScript(
                    id: deterministicUUID(namespace: "resolved-script", value: "\(safeDestination)-mapkit"),
                    name: "MapKit 坐标匹配",
                    summary: "将 AI 候选地点交给 MapKit 搜索，使用匹配后的坐标生成路线。"
                ),
                PlanningScript(
                    id: deterministicUUID(namespace: "resolved-script", value: "\(safeDestination)-route-order"),
                    name: "编号路线点",
                    summary: "按当天活动顺序给地图点位添加 1、2、3 编号。"
                )
            ]
        )
    }

    public static func unresolvedTrip(destination: String, dayCount: Int) -> Trip {
        let normalizedDayCount = TripPlanningLimits.normalizedDayCount(dayCount)
        let safeDestination = destination.isEmpty ? "未命名目的地" : destination
        let days = (1...normalizedDayCount).map { dayNumber in
            unresolvedDay(destination: safeDestination, dayNumber: dayNumber)
        }

        return Trip(
            id: uuid("00000000-0000-0000-0000-000000000031"),
            title: "\(safeDestination) \(normalizedDayCount) 日旅行",
            englishProductName: "Ayu Walk",
            destination: safeDestination,
            purpose: [.cityWalk],
            duration: .dayCount(normalizedDayCount),
            days: days,
            participants: [
                Participant(
                    id: uuid("00000000-0000-0000-0000-000000000431"),
                    name: "我",
                    role: nil
                )
            ],
            importedSources: [],
            budgetPlan: BudgetPlan(total: Decimal(normalizedDayCount * 2000), currencyCode: currencyCode(for: safeDestination)),
            packingList: PackingList(items: [
                PackingItem(
                    id: uuid("00000000-0000-0000-0000-000000000531"),
                    title: "证件",
                    isPacked: false,
                    notes: nil
                ),
                PackingItem(
                    id: uuid("00000000-0000-0000-0000-000000000532"),
                    title: "充电器",
                    isPacked: false,
                    notes: nil
                )
            ]),
            journalPages: [],
            planningScripts: [
                PlanningScript(
                    id: uuid("00000000-0000-0000-0000-000000000631"),
                    name: "定位失败保护",
                    summary: "目的地无法定位时保留用户输入，不退回无关城市。"
                )
            ]
        )
    }

    private static func uuid(_ value: String) -> UUID {
        UUID(uuidString: value)!
    }

    private static func currencyCode(for destination: String) -> String {
        switch DestinationResolver.resolve(destination) {
        case let .resolved(location):
            return location.currencyCode
        case let .ambiguous(options):
            return options.first?.currencyCode ?? "CNY"
        case .unresolved:
            return "CNY"
        }
    }

    private static func localizedDay(
        destination: String,
        dayNumber: Int,
        location: DestinationLocation
    ) -> TripDay {
        let routeBase = (dayNumber - 1) * 4
        let dayOffset = Double(dayNumber - 1) * 0.006
        let places = [
            localizedPlace(
                id: deterministicUUIDString(namespace: "localized-place", value: "\(destination)-\(dayNumber)-center"),
                destination: destination,
                suffix: "Day \(dayNumber) 中心散步",
                location: location,
                latitudeOffset: dayOffset,
                longitudeOffset: dayOffset
            ),
            localizedPlace(
                id: deterministicUUIDString(namespace: "localized-place", value: "\(destination)-\(dayNumber)-food"),
                destination: destination,
                suffix: "Day \(dayNumber) 午餐街区",
                location: location,
                latitudeOffset: dayOffset + 0.008,
                longitudeOffset: dayOffset + 0.009
            ),
            localizedPlace(
                id: deterministicUUIDString(namespace: "localized-place", value: "\(destination)-\(dayNumber)-evening"),
                destination: destination,
                suffix: "Day \(dayNumber) 傍晚记录点",
                location: location,
                latitudeOffset: dayOffset - 0.007,
                longitudeOffset: dayOffset + 0.011
            ),
            localizedPlace(
                id: deterministicUUIDString(namespace: "localized-place", value: "\(destination)-\(dayNumber)-dinner"),
                destination: destination,
                suffix: "Day \(dayNumber) 晚餐街区",
                location: location,
                latitudeOffset: dayOffset - 0.004,
                longitudeOffset: dayOffset + 0.009
            )
        ]

        return TripDay(
            id: deterministicUUID(namespace: "localized-day", value: "\(destination)-\(dayNumber)"),
            dayNumber: dayNumber,
            dateLabel: "Day \(dayNumber)",
            title: "\(destination) Day \(dayNumber) 初步路线",
            activities: [
                Activity(
                    id: deterministicUUID(namespace: "localized-activity", value: "\(destination)-\(dayNumber)-center"),
                    title: "\(destination) Day \(dayNumber) 中心散步",
                    kind: .sight,
                    place: places[0],
                    startTime: "10:00",
                    endTime: "11:30",
                    notes: "根据目的地定位生成的起点，后续可替换成真实景点搜索结果",
                    estimatedCost: 0,
                    routeOrder: routeBase + 1,
                    reminder: nil
                ),
                Activity(
                    id: deterministicUUID(namespace: "localized-activity", value: "\(destination)-\(dayNumber)-food"),
                    title: "午饭：\(destination) Day \(dayNumber) 午餐街区",
                    kind: .meal,
                    place: places[1],
                    startTime: "12:00",
                    endTime: "13:30",
                    notes: "先按定位附近保留饭点，后续接餐厅推荐",
                    estimatedCost: 300,
                    routeOrder: routeBase + 2,
                    reminder: nil
                ),
                Activity(
                    id: deterministicUUID(namespace: "localized-activity", value: "\(destination)-\(dayNumber)-evening"),
                    title: "\(destination) Day \(dayNumber) 傍晚记录",
                    kind: .sight,
                    place: places[2],
                    startTime: "15:00",
                    endTime: "17:00",
                    notes: "适合生成手帐照片和文字记录",
                    estimatedCost: 0,
                    routeOrder: routeBase + 3,
                    reminder: nil
                ),
                Activity(
                    id: deterministicUUID(namespace: "localized-activity", value: "\(destination)-\(dayNumber)-dinner"),
                    title: "晚饭：\(destination) Day \(dayNumber) 晚餐街区",
                    kind: .meal,
                    place: places[3],
                    startTime: "18:30",
                    endTime: "20:00",
                    notes: "先保留晚餐时间，后续可按预算和评分推荐餐厅",
                    estimatedCost: 500,
                    routeOrder: routeBase + 4,
                    reminder: nil
                )
            ]
        )
    }

    private static func split(_ places: [Place], into dayCount: Int) -> [[Place]] {
        guard dayCount > 1, !places.isEmpty else {
            return [places]
        }

        let baseCount = places.count / dayCount
        let remainder = places.count % dayCount
        var startIndex = 0

        return (0..<dayCount).map { dayIndex in
            let count = baseCount + (dayIndex < remainder ? 1 : 0)
            guard count > 0 else {
                return []
            }

            let endIndex = startIndex + count
            defer {
                startIndex = endIndex
            }
            return Array(places[startIndex..<endIndex])
        }
    }

    private static func dailyTemplateActivities(
        destination: String,
        dayNumber: Int,
        dayPlaces: [Place],
        anchorPlaces: [Place]
    ) -> [Activity] {
        let morningPlace = dayPlaces[safe: 0] ?? placeholderPlace(
            destination: destination,
            dayNumber: dayNumber,
            slotName: "上午活动",
            anchorPlaces: anchorPlaces
        )
        let lunchPlace = placeholderPlace(
            destination: destination,
            dayNumber: dayNumber,
            slotName: "午饭",
            anchorPlaces: dayPlaces.isEmpty ? anchorPlaces : dayPlaces
        )
        let afternoonPlace = dayPlaces[safe: 1] ?? dayPlaces[safe: 0] ?? placeholderPlace(
            destination: destination,
            dayNumber: dayNumber,
            slotName: "下午活动",
            anchorPlaces: anchorPlaces
        )
        let dinnerPlace = placeholderPlace(
            destination: destination,
            dayNumber: dayNumber,
            slotName: "晚饭",
            anchorPlaces: dayPlaces.isEmpty ? anchorPlaces : dayPlaces
        )
        let slots: [(slotIndex: Int, title: String, kind: ActivityKind, place: Place, start: String, end: String, cost: Decimal)] = [
            (0, morningPlace.name, .sight, morningPlace, "09:30", "11:30", 0),
            (1, "午饭：\(lunchPlace.name)", .meal, lunchPlace, "12:00", "13:30", 300),
            (2, afternoonPlace.name, .sight, afternoonPlace, "15:00", "17:00", 0),
            (3, "晚饭：\(dinnerPlace.name)", .meal, dinnerPlace, "18:30", "20:00", 500)
        ]

        return slots.map { slot in
            let routeOrder = (dayNumber - 1) * 4 + slot.slotIndex + 1
            return Activity(
                id: deterministicUUID(namespace: "resolved-activity", value: "\(destination)-\(dayNumber)-\(slot.slotIndex)-\(slot.title)"),
                title: slot.title,
                kind: slot.kind,
                place: slot.place,
                startTime: slot.start,
                endTime: slot.end,
                notes: "可继续编辑时间、地点和路线顺序",
                estimatedCost: slot.cost,
                routeOrder: routeOrder,
                reminder: nil
            )
        }
    }

    private static func placeholderPlace(
        destination: String,
        dayNumber: Int,
        slotName: String,
        anchorPlaces: [Place]
    ) -> Place {
        let anchor = anchorPlaces.first { $0.latitude != nil && $0.longitude != nil }
        let slotOffset: Double
        switch slotName {
        case "午饭":
            slotOffset = 0.0015
        case "下午活动":
            slotOffset = 0.003
        case "晚饭":
            slotOffset = 0.0045
        default:
            slotOffset = 0
        }
        let offset = Double(dayNumber) * 0.0025 + slotOffset
        return Place(
            id: deterministicUUID(namespace: "resolved-placeholder-place", value: "\(destination)-\(dayNumber)-\(slotName)"),
            name: "\(destination) Day \(dayNumber) \(slotName)",
            address: anchor?.address ?? destination,
            latitude: anchor?.latitude.map { $0 + offset },
            longitude: anchor?.longitude.map { $0 - offset },
            providerIDs: anchor == nil ? [:] : [.mapKit: "placeholder-\(destination)-day-\(dayNumber)-\(slotName)"]
        )
    }

    private static func unresolvedDay(destination: String, dayNumber: Int) -> TripDay {
        let routeOrder = (dayNumber - 1) * 2
        let confirmationPlace = unresolvedPlace(
            id: deterministicUUIDString(namespace: "unresolved-place", value: "\(destination)-\(dayNumber)-confirm"),
            destination: destination,
            suffix: "Day \(dayNumber) 目的地确认"
        )
        let planningPlace = unresolvedPlace(
            id: deterministicUUIDString(namespace: "unresolved-place", value: "\(destination)-\(dayNumber)-plan"),
            destination: destination,
            suffix: "Day \(dayNumber) 初步安排"
        )

        return TripDay(
            id: deterministicUUID(namespace: "unresolved-day", value: "\(destination)-\(dayNumber)"),
            dayNumber: dayNumber,
            dateLabel: "Day \(dayNumber)",
            title: "\(destination) Day \(dayNumber) 待定位路线",
            activities: [
                Activity(
                    id: deterministicUUID(namespace: "unresolved-activity", value: "\(destination)-\(dayNumber)-confirm"),
                    title: "\(destination) Day \(dayNumber) 目的地确认",
                    kind: .note,
                    place: confirmationPlace,
                    startTime: nil,
                    endTime: nil,
                    notes: "定位失败时保留用户目的地和天数，不退回其他城市",
                    estimatedCost: nil,
                    routeOrder: routeOrder + 1,
                    reminder: nil
                ),
                Activity(
                    id: deterministicUUID(namespace: "unresolved-activity", value: "\(destination)-\(dayNumber)-plan"),
                    title: "\(destination) Day \(dayNumber) 初步安排",
                    kind: .note,
                    place: planningPlace,
                    startTime: nil,
                    endTime: nil,
                    notes: "重新输入更具体的城市或景点后可获得地图点位",
                    estimatedCost: nil,
                    routeOrder: routeOrder + 2,
                    reminder: nil
                )
            ]
        )
    }

    private static func localizedPlace(
        id: String,
        destination: String,
        suffix: String,
        location: DestinationLocation,
        latitudeOffset: Double,
        longitudeOffset: Double
    ) -> Place {
        Place(
            id: uuid(id),
            name: "\(destination) \(suffix)",
            address: location.displayName,
            latitude: location.latitude + latitudeOffset,
            longitude: location.longitude + longitudeOffset,
            providerIDs: [.mapKit: "resolved-\(destination)-\(suffix)"]
        )
    }

    private static func unresolvedPlace(id: String, destination: String, suffix: String) -> Place {
        Place(
            id: uuid(id),
            name: "\(destination) \(suffix)",
            address: destination,
            latitude: nil,
            longitude: nil,
            providerIDs: [:]
        )
    }

    private static func deterministicUUID(namespace: String, value: String) -> UUID {
        let scalars = "\(namespace)-\(value)".unicodeScalars.map(\.value)
        let hash = scalars.reduce(UInt64(14_695_981_039_346_656_037)) { partial, scalar in
            (partial ^ UInt64(scalar)).multipliedReportingOverflow(by: 1_099_511_628_211).partialValue
        }
        let hex = String(format: "%012llx", hash)
        return UUID(uuidString: "00000000-0000-0000-0000-\(String(hex.suffix(12)))")!
    }

    private static func deterministicUUIDString(namespace: String, value: String) -> String {
        deterministicUUID(namespace: namespace, value: value).uuidString
    }

    private static func defaultStartTime(for index: Int) -> String? {
        ["10:00", "12:00", "15:00", "17:30", "19:00", "20:30"][safe: index]
    }

    private static func defaultEndTime(for index: Int) -> String? {
        ["11:30", "13:30", "16:30", "18:30", "20:00", "21:30"][safe: index]
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
