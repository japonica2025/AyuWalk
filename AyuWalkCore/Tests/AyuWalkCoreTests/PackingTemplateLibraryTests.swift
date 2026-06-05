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
}
