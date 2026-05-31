import Foundation

public enum SampleTripFactory {
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
            budgetPlan: BudgetPlan(total: 12000, currencyCode: "CNY"),
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

    private static func uuid(_ value: String) -> UUID {
        UUID(uuidString: value)!
    }
}
