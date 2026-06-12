import XCTest
@testable import AyuWalkCore

final class TripShareCopyBuilderTests: XCTestCase {
    func testSocialCopyUsesRealItineraryBudgetPackingAndSettlementDetails() {
        let aliceID = UUID()
        let bobID = UUID()
        let trip = Trip(
            id: UUID(),
            title: "大阪 3 日旅行",
            englishProductName: "AyuWalk",
            destination: "Osaka",
            purpose: [.food, .cityWalk],
            duration: .dayCount(3),
            days: [
                TripDay(
                    id: UUID(),
                    dayNumber: 1,
                    dateLabel: "Day 1",
                    title: "城堡和河边散步",
                    activities: [
                        Activity(
                            id: UUID(),
                            title: "Osaka Castle",
                            kind: .sight,
                            place: nil,
                            startTime: "09:30",
                            endTime: nil,
                            notes: nil,
                            estimatedCost: nil,
                            routeOrder: 1,
                            reminder: nil
                        ),
                        Activity(
                            id: UUID(),
                            title: "Nakanoshima Park",
                            kind: .sight,
                            place: nil,
                            startTime: "14:00",
                            endTime: nil,
                            notes: nil,
                            estimatedCost: nil,
                            routeOrder: 2,
                            reminder: nil
                        )
                    ]
                ),
                TripDay(
                    id: UUID(),
                    dayNumber: 2,
                    dateLabel: "Day 2",
                    title: "咖啡和购物",
                    activities: [
                        Activity(
                            id: UUID(),
                            title: "心斋桥",
                            kind: .shopping,
                            place: nil,
                            startTime: "11:00",
                            endTime: nil,
                            notes: nil,
                            estimatedCost: nil,
                            routeOrder: 1,
                            reminder: nil
                        )
                    ]
                )
            ],
            participants: [
                Participant(id: aliceID, name: "小鱼", role: nil),
                Participant(id: bobID, name: "小林", role: nil)
            ],
            importedSources: [],
            budgetPlan: BudgetPlan(
                total: 7500,
                currencyCode: "JPY",
                expenses: [
                    BudgetExpense(
                        id: UUID(),
                        title: "章鱼烧",
                        amount: 2400,
                        category: .food,
                        participantIDs: [aliceID, bobID],
                        payerID: aliceID,
                        currencyCode: "JPY",
                        notes: nil
                    )
                ]
            ),
            packingList: PackingList(items: [
                PackingItem(id: UUID(), title: "护照", isPacked: true, notes: nil),
                PackingItem(id: UUID(), title: "充电器", isPacked: false, notes: nil)
            ]),
            journalPages: [],
            planningScripts: []
        )

        let copy = TripShareCopyBuilder.socialCopy(trip: trip)

        XCTAssertTrue(copy.contains("大阪 3 日旅行"))
        XCTAssertTrue(copy.contains("Osaka Castle"))
        XCTAssertTrue(copy.contains("Nakanoshima Park"))
        XCTAssertTrue(copy.contains("心斋桥"))
        XCTAssertTrue(copy.contains("预算 JPY 7500"))
        XCTAssertTrue(copy.contains("已记录 JPY 2400"))
        XCTAssertTrue(copy.contains("小林 转给 小鱼：JPY 1200"))
        XCTAssertTrue(copy.contains("行李 1/2"))
        XCTAssertFalse(copy.contains("初版路线整理好了"))
    }

    func testSocialCopyIncludesEverySettlementTransfer() {
        let aliceID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let bobID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let chikaID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        let trip = Trip(
            id: UUID(),
            title: "巴黎 4 日旅行",
            englishProductName: "AyuWalk",
            destination: "Paris",
            purpose: [.food],
            duration: .dayCount(4),
            days: [],
            participants: [
                Participant(id: aliceID, name: "小鱼", role: nil),
                Participant(id: bobID, name: "小林", role: nil),
                Participant(id: chikaID, name: "千夏", role: nil)
            ],
            importedSources: [],
            budgetPlan: BudgetPlan(
                total: 900,
                currencyCode: "EUR",
                expenses: [
                    BudgetExpense(
                        id: UUID(),
                        title: "晚餐",
                        amount: 300,
                        category: .food,
                        participantIDs: [aliceID, bobID, chikaID],
                        payerID: aliceID,
                        currencyCode: "EUR",
                        notes: nil
                    ),
                    BudgetExpense(
                        id: UUID(),
                        title: "博物馆",
                        amount: 90,
                        category: .ticket,
                        participantIDs: [aliceID, bobID, chikaID],
                        payerID: bobID,
                        currencyCode: "EUR",
                        notes: nil
                    )
                ]
            ),
            packingList: nil,
            journalPages: [],
            planningScripts: []
        )

        let copy = TripShareCopyBuilder.socialCopy(trip: trip)

        XCTAssertTrue(copy.contains("小林 转给 小鱼：EUR 40"))
        XCTAssertTrue(copy.contains("千夏 转给 小鱼：EUR 130"))
    }
}
