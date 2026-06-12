import XCTest
@testable import AyuWalkCore

final class PackingTemplateLibraryTests: XCTestCase {
    func testDefaultLibraryContainsExpectedTravelScenarios() {
        let templateIDs = Set(PackingTemplateLibrary.default.map(\.id))

        XCTAssertEqual(templateIDs, [
            .shortTrip,
            .international,
            .weatherReady,
            .contentCreator,
            .family
        ])
    }

    func testApplyingTemplateKeepsExistingItemsAndSkipsDuplicateTitles() {
        let existingPassport = PackingItem(
            id: UUID(),
            title: "护照",
            isPacked: true,
            notes: "已放入随身包"
        )
        let existingList = PackingList(items: [existingPassport])
        let template = PackingTemplate(
            id: .international,
            title: "海外旅行",
            subtitle: "证件、支付和网络",
            systemImage: "airplane",
            items: [
                PackingTemplateItem(title: "护照", notes: "检查有效期"),
                PackingTemplateItem(title: "转换插头", notes: nil)
            ]
        )

        let merged = PackingTemplateLibrary.applying(template, to: existingList)

        XCTAssertEqual(merged.items.count, 2)
        XCTAssertEqual(merged.items.first, existingPassport)
        XCTAssertEqual(merged.items.last?.title, "转换插头")
        XCTAssertEqual(merged.items.last?.isPacked, false)
    }

    func testApplyingTemplatePreservesReminder() {
        let reminder = PackingReminder(
            id: UUID(),
            dayOffsetBeforeTrip: 2,
            fireTime: "20:00",
            note: "检查行李",
            isEnabled: true
        )
        let existingList = PackingList(items: [], reminder: reminder)

        let merged = PackingTemplateLibrary.applying(PackingTemplateLibrary.default[0], to: existingList)

        XCTAssertEqual(merged.reminder, reminder)
    }

    func testApplyingSameTemplateTwiceIsIdempotentAndReportsAppliedState() {
        let template = PackingTemplateLibrary.default[0]
        let firstMerge = PackingTemplateLibrary.applying(template, to: PackingList(items: []))
        let secondMerge = PackingTemplateLibrary.applying(template, to: firstMerge)

        XCTAssertEqual(secondMerge, firstMerge)
        XCTAssertTrue(PackingTemplateLibrary.isApplied(template, to: secondMerge))
    }

    func testAppliedStateUsesSameTitleNormalizationAsMerge() {
        let template = PackingTemplate(
            id: .international,
            title: "海外旅行",
            subtitle: "证件、支付和网络",
            systemImage: "airplane",
            items: [PackingTemplateItem(title: "SIM CARD", notes: nil)]
        )
        let list = PackingList(items: [
            PackingItem(id: UUID(), title: "  ＳＩＭ ＣＡＲＤ  ", isPacked: true, notes: nil)
        ])

        XCTAssertTrue(PackingTemplateLibrary.isApplied(template, to: list))
        XCTAssertEqual(PackingTemplateLibrary.applying(template, to: list), list)
    }

    func testApplyingMultipleTemplatesMergesAllSelectionsWithoutDuplicates() {
        let templates = [
            PackingTemplate(
                id: .shortTrip,
                title: "基础短途",
                subtitle: "",
                systemImage: "backpack.fill",
                items: [
                    PackingTemplateItem(title: "充电器", notes: nil),
                    PackingTemplateItem(title: "护照", notes: nil)
                ]
            ),
            PackingTemplate(
                id: .international,
                title: "海外旅行",
                subtitle: "",
                systemImage: "airplane",
                items: [
                    PackingTemplateItem(title: "护照", notes: "检查有效期"),
                    PackingTemplateItem(title: "转换插头", notes: nil)
                ]
            )
        ]

        let merged = PackingTemplateLibrary.applying(templates, to: PackingList(items: []))

        XCTAssertEqual(merged.items.map(\.title), ["充电器", "护照", "转换插头"])
    }

    func testRecommendationsIncludeShortTripAndInternationalForResolvedOverseasShortTrip() {
        let trip = trip(
            destination: "Tokyo",
            duration: .dayCount(3),
            purpose: [.cityWalk],
            activities: []
        )

        let recommendations = PackingTemplateLibrary.recommendations(for: trip, packingList: PackingList(items: []))

        XCTAssertEqual(recommendations.map(\.template.id).prefix(2), [.international, .shortTrip])
        XCTAssertTrue(recommendations.contains { $0.template.id == .international && $0.reason.contains("海外") })
        XCTAssertTrue(recommendations.contains { $0.template.id == .shortTrip && $0.reason.contains("3 天") })
    }

    func testRecommendationsIncludeFamilyForFamilyPurpose() {
        let trip = trip(
            destination: "上海",
            duration: .dayCount(5),
            purpose: [.family],
            activities: []
        )

        let recommendations = PackingTemplateLibrary.recommendations(for: trip, packingList: PackingList(items: []))

        XCTAssertTrue(recommendations.contains { $0.template.id == .family && $0.reason.contains("亲子") })
    }

    func testRecommendationsUseBudgetCurrencyForUnresolvedInternationalTrips() {
        let trip = trip(
            destination: "想去的海边小镇",
            duration: .dayCount(4),
            purpose: [.cityWalk],
            activities: [],
            budgetPlan: BudgetPlan(total: 800, currencyCode: "EUR")
        )

        let recommendations = PackingTemplateLibrary.recommendations(for: trip, packingList: PackingList(items: []))

        XCTAssertTrue(recommendations.contains { $0.template.id == .international && $0.reason.contains("海外") })
    }

    func testRecommendationsSkipTemplatesAlreadyApplied() {
        let template = PackingTemplateLibrary.default.first { $0.id == .international }!
        let trip = trip(
            destination: "Paris",
            duration: .dayCount(5),
            purpose: [.cityWalk],
            activities: []
        )
        let packingList = PackingTemplateLibrary.applying(template, to: PackingList(items: []))

        let recommendations = PackingTemplateLibrary.recommendations(for: trip, packingList: packingList)

        XCTAssertFalse(recommendations.contains { $0.template.id == .international })
    }

    func testRecommendationsIncludeContentCreatorForPhotoActivities() {
        let trip = trip(
            destination: "大阪",
            duration: .dayCount(4),
            purpose: [.cityWalk],
            activities: [
                Activity(
                    id: UUID(),
                    title: "胶片相机拍照散步",
                    kind: .sight,
                    place: nil,
                    startTime: nil,
                    endTime: nil,
                    notes: "准备照片素材",
                    estimatedCost: nil,
                    routeOrder: nil,
                    reminder: nil
                )
            ]
        )

        let recommendations = PackingTemplateLibrary.recommendations(for: trip, packingList: PackingList(items: []))

        XCTAssertTrue(recommendations.contains { $0.template.id == .contentCreator && $0.reason.contains("拍照") })
    }

    private func trip(
        destination: String,
        duration: TripDuration,
        purpose: [TravelPurpose],
        activities: [Activity],
        budgetPlan: BudgetPlan? = nil
    ) -> Trip {
        Trip(
            id: UUID(),
            title: "\(destination) Test",
            englishProductName: "AyuWalk",
            destination: destination,
            purpose: purpose,
            duration: duration,
            days: [
                TripDay(
                    id: UUID(),
                    dayNumber: 1,
                    dateLabel: "Day 1",
                    title: "第一天",
                    activities: activities
                )
            ],
            participants: [],
            importedSources: [],
            budgetPlan: budgetPlan,
            packingList: nil,
            journalPages: [],
            planningScripts: []
        )
    }
}
