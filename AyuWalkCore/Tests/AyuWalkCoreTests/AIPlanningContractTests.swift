import XCTest
@testable import AyuWalkCore

final class AIPlanningContractTests: XCTestCase {
    func testProposalNormalizationClampsConfidenceAndDayNumbers() {
        let proposal = AIPlanningProposal(
            confidence: 1.4,
            questions: [],
            assumptions: [],
            adjustmentReason: nil,
            days: [
                AIPlannedDay(
                    dayNumber: 9,
                    title: "远超范围的一天",
                    activities: [
                        AIPlannedActivity(
                            title: "大阪城",
                            kind: .sight,
                            place: nil,
                            startTime: "10:00",
                            endTime: "12:00",
                            notes: nil,
                            estimatedCost: nil,
                            isFixedNode: false
                        )
                    ]
                )
            ],
            source: .remoteAI
        )

        let normalized = AIPlanningProposalNormalizer.normalize(proposal, dayCount: 3)

        XCTAssertEqual(normalized.confidence, 1)
        XCTAssertEqual(normalized.days.first?.dayNumber, 3)
    }

    func testProposalNormalizationRemovesEmptyQuestionsAssumptionsAndActivities() {
        let proposal = AIPlanningProposal(
            confidence: -0.2,
            questions: [
                AIPlanningQuestion(id: "pace", prompt: "  ", options: [], isRequired: true),
                AIPlanningQuestion(id: "food", prompt: "想重点吃什么？", options: [" 拉面 ", " "], isRequired: false)
            ],
            assumptions: [
                AIPlanningAssumption(id: "empty", text: " "),
                AIPlanningAssumption(id: "pace", text: "  默认使用轻松节奏 ")
            ],
            adjustmentReason: " ",
            days: [
                AIPlannedDay(
                    dayNumber: 1,
                    title: " ",
                    activities: [
                        AIPlannedActivity(
                            title: " ",
                            kind: .note,
                            place: nil,
                            startTime: nil,
                            endTime: nil,
                            notes: nil,
                            estimatedCost: nil,
                            isFixedNode: false
                        ),
                        AIPlannedActivity(
                            title: " 道顿堀 ",
                            kind: .meal,
                            place: nil,
                            startTime: nil,
                            endTime: nil,
                            notes: nil,
                            estimatedCost: nil,
                            isFixedNode: false
                        )
                    ]
                )
            ],
            source: .remoteAI
        )

        let normalized = AIPlanningProposalNormalizer.normalize(proposal, dayCount: 3)

        XCTAssertEqual(normalized.confidence, 0)
        XCTAssertEqual(normalized.questions.map(\.prompt), ["想重点吃什么？"])
        XCTAssertEqual(normalized.questions.first?.options, ["拉面"])
        XCTAssertEqual(normalized.assumptions.map(\.text), ["默认使用轻松节奏"])
        XCTAssertNil(normalized.adjustmentReason)
        XCTAssertEqual(normalized.days.first?.title, "Day 1")
        XCTAssertEqual(normalized.days.first?.activities.map(\.title), ["道顿堀"])
    }

    func testClarificationPolicyRequestsMissingPlanningPreferences() {
        let request = AIPlanningRequest(
            destination: "大阪",
            dayCount: 3,
            purpose: [],
            notes: "",
            importedText: nil,
            adjustmentRequest: nil
        )

        let questions = AIPlanningClarificationPolicy.questions(for: request)

        XCTAssertTrue(questions.contains { $0.id == "purpose" })
        XCTAssertTrue(questions.contains { $0.id == "pace" })
    }

    func testClarificationPolicySkipsQuestionsWhenIntentIsDetailed() {
        let request = AIPlanningRequest(
            destination: "大阪",
            dayCount: 3,
            purpose: [.food, .cityWalk],
            notes: "每天上午十点后出发，重点吃当地小店，节奏轻松",
            importedText: nil,
            adjustmentRequest: nil
        )

        XCTAssertTrue(AIPlanningClarificationPolicy.questions(for: request).isEmpty)
    }

    func testApplyingAdjustmentPreservesExistingFixedNodes() {
        let fixedNode = Activity(
            id: UUID(),
            title: "酒店入住",
            kind: .hotel,
            place: nil,
            startTime: "15:00",
            endTime: nil,
            notes: nil,
            estimatedCost: nil,
            routeOrder: nil,
            reminder: nil,
            isFixedNode: true
        )
        var trip = MockPlanningEngine().generateTrip(
            destination: "大阪",
            dayCount: 2,
            purpose: [.food],
            notes: ""
        )
        trip.days[0].activities.append(fixedNode)
        let proposal = AIPlanningProposal(
            confidence: 0.8,
            questions: [],
            assumptions: [],
            adjustmentReason: "减少购物，增加美食",
            days: [
                AIPlannedDay(
                    dayNumber: 1,
                    title: "美食散步",
                    activities: [
                        AIPlannedActivity(
                            title: "黑门市场",
                            kind: .meal,
                            place: nil,
                            startTime: "10:00",
                            endTime: "12:00",
                            notes: nil,
                            estimatedCost: nil,
                            isFixedNode: false
                        )
                    ]
                )
            ],
            source: .remoteAI
        )

        let adjusted = AITripProposalApplier.apply(proposal, to: trip)

        XCTAssertTrue(adjusted.days[0].activities.contains { $0.id == fixedNode.id })
        XCTAssertTrue(adjusted.days[0].activities.contains { $0.title == "黑门市场" })
    }

    func testApplyingProposalUsesResolvedPlaceBeforeRawAIPlace() {
        var trip = MockPlanningEngine().generateTrip(
            destination: "大阪",
            dayCount: 1,
            purpose: [.cityWalk],
            notes: ""
        )
        trip.days[0].activities.removeAll()
        let resolvedPlace = Place(
            id: UUID(),
            name: "Osaka Castle",
            address: "1-1 Osakajo, Chuo Ward, Osaka",
            latitude: 34.6873,
            longitude: 135.5262,
            providerIDs: [.mapKit: "verified-osaka-castle"]
        )
        let proposal = AIPlanningProposal(
            confidence: 0.8,
            questions: [],
            assumptions: [],
            adjustmentReason: nil,
            days: [
                AIPlannedDay(
                    dayNumber: 1,
                    title: "大阪初见",
                    activities: [
                        AIPlannedActivity(
                            title: "大阪城",
                            kind: .sight,
                            place: AIPlannedPlace(
                                name: "Osaka Castle",
                                address: "AI raw address",
                                latitude: 0,
                                longitude: 0
                            ),
                            startTime: nil,
                            endTime: nil,
                            notes: nil,
                            estimatedCost: nil,
                            isFixedNode: false
                        )
                    ]
                )
            ],
            source: .remoteAI
        )

        let adjusted = AITripProposalApplier.apply(proposal, to: trip, resolvedPlaces: [resolvedPlace])

        XCTAssertEqual(adjusted.days[0].activities.first?.place, resolvedPlace)
    }

    func testApplyingAdjustmentCanPreserveExistingOrdinaryActivities() {
        var trip = MockPlanningEngine().generateTrip(
            destination: "大阪",
            dayCount: 1,
            purpose: [.food],
            notes: ""
        )
        let existing = Activity(
            id: UUID(),
            title: "用户手动添加的咖啡店",
            kind: .meal,
            place: nil,
            startTime: nil,
            endTime: nil,
            notes: "不要丢失",
            estimatedCost: nil,
            routeOrder: 1,
            reminder: nil,
            isFixedNode: false
        )
        trip.days[0].activities = [existing]
        let proposal = AIPlanningProposal(
            confidence: 0.7,
            questions: [],
            assumptions: [],
            adjustmentReason: "增加晚餐",
            days: [
                AIPlannedDay(
                    dayNumber: 1,
                    title: "调整后",
                    activities: [
                        AIPlannedActivity(
                            title: "黑门市场",
                            kind: .meal,
                            place: nil,
                            startTime: nil,
                            endTime: nil,
                            notes: nil,
                            estimatedCost: nil,
                            isFixedNode: false
                        )
                    ]
                )
            ],
            source: .remoteAI
        )

        let adjusted = AITripProposalApplier.apply(
            proposal,
            to: trip,
            mode: .preserveExistingOrdinaryActivities
        )

        XCTAssertTrue(adjusted.days[0].activities.contains { $0.id == existing.id })
        XCTAssertTrue(adjusted.days[0].activities.contains { $0.title == "黑门市场" })
    }

    func testApplyingAdjustmentIgnoresNewFixedNodesFromProposal() {
        var trip = MockPlanningEngine().generateTrip(
            destination: "大阪",
            dayCount: 1,
            purpose: [.food],
            notes: ""
        )
        trip.days[0].activities.removeAll()
        let proposal = AIPlanningProposal(
            confidence: 0.7,
            questions: [],
            assumptions: [],
            adjustmentReason: "调整路线",
            days: [
                AIPlannedDay(
                    dayNumber: 1,
                    title: "调整后",
                    activities: [
                        AIPlannedActivity(
                            title: "AI 猜测的航班",
                            kind: .transport,
                            place: nil,
                            startTime: "09:00",
                            endTime: nil,
                            notes: nil,
                            estimatedCost: nil,
                            isFixedNode: true
                        )
                    ]
                )
            ],
            source: .remoteAI
        )

        let adjusted = AITripProposalApplier.apply(proposal, to: trip)

        XCTAssertTrue(adjusted.days[0].activities.isEmpty)
    }

    func testResponseDecoderExtractsStructuredProposalFromMarkdownFence() throws {
        let response = """
        ```json
        {
          "confidence": 0.82,
          "questions": [],
          "assumptions": [{"id":"pace","text":"默认轻松节奏"}],
          "adjustmentReason": null,
          "days": [{
            "dayNumber": 1,
            "title": "大阪初见",
            "activities": [{
              "title": "大阪城",
              "kind": "sight",
              "place": {"name":"Osaka Castle","address":"Osaka, Japan","latitude":34.6873,"longitude":135.5262},
              "startTime": "10:00",
              "endTime": "12:00",
              "notes": "上午游览",
              "estimatedCost": 600,
              "isFixedNode": false
            }]
          }]
        }
        ```
        """

        let proposal = try AIPlanningResponseDecoder.decode(response, source: .remoteAI, dayCount: 3)

        XCTAssertEqual(proposal.confidence, 0.82)
        XCTAssertEqual(proposal.assumptions.first?.text, "默认轻松节奏")
        XCTAssertEqual(proposal.days.first?.activities.first?.kind, .sight)
        XCTAssertEqual(proposal.days.first?.activities.first?.place?.name, "Osaka Castle")
    }

    func testResponseDecoderUsesSafeDefaultsForUnknownActivityKindAndMissingCollections() throws {
        let response = """
        {
          "confidence": 0.6,
          "days": [{
            "dayNumber": 1,
            "title": "自由安排",
            "activities": [{"title":"临时活动","kind":"unexpected"}]
          }]
        }
        """

        let proposal = try AIPlanningResponseDecoder.decode(response, source: .remoteAI, dayCount: 2)

        XCTAssertEqual(proposal.questions, [])
        XCTAssertEqual(proposal.assumptions, [])
        XCTAssertEqual(proposal.days.first?.activities.first?.kind, .note)
        XCTAssertFalse(proposal.days.first?.activities.first?.isFixedNode ?? true)
    }
}
