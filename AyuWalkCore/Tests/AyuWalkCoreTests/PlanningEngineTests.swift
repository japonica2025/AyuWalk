import XCTest
@testable import AyuWalkCore

final class PlanningEngineTests: XCTestCase {
    func testTripStoresDaysActivitiesPlacesAndJournalReadiness() {
        let place = Place(
            id: UUID(),
            name: "涩谷 Scramble Crossing",
            address: "Shibuya City, Tokyo",
            latitude: 35.6595,
            longitude: 139.7005,
            providerIDs: [.mapKit: "mock-shibuya"]
        )

        let activity = Activity(
            id: UUID(),
            title: "涩谷 City Walk",
            kind: .sight,
            place: place,
            startTime: "10:00",
            endTime: "11:30",
            notes: "适合作为第一天轻松开始",
            estimatedCost: 0,
            routeOrder: 1,
            reminder: nil
        )

        let day = TripDay(
            id: UUID(),
            dayNumber: 1,
            dateLabel: "Day 1",
            title: "涩谷 - 原宿",
            activities: [activity]
        )

        let trip = Trip(
            id: UUID(),
            title: "东京 5 日旅行",
            englishProductName: "Ayu Walk",
            destination: "东京",
            purpose: [.cityWalk],
            duration: .dayCount(5),
            days: [day],
            participants: [],
            importedSources: [],
            budgetPlan: nil,
            packingList: nil,
            journalPages: [],
            planningScripts: []
        )

        XCTAssertEqual(trip.destination, "东京")
        XCTAssertEqual(trip.days.first?.activities.first?.routeOrder, 1)
        XCTAssertEqual(trip.days.first?.activities.first?.place?.providerIDs[.mapKit], "mock-shibuya")
    }

    func testCoreEnumsExposeStableRawValues() {
        XCTAssertEqual(TravelPurpose.cityWalk.rawValue, "cityWalk")
        XCTAssertEqual(ActivityKind.freeTime.rawValue, "freeTime")
        XCTAssertEqual(MapProviderKind.mapKit.rawValue, "mapKit")
        XCTAssertEqual(JournalBlockKind.dateLocation.rawValue, "dateLocation")
    }

    func testTripDurationDateRangeStoresDates() {
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 86400)
        let duration = TripDuration.dateRange(start: start, end: end)

        guard case let .dateRange(actualStart, actualEnd) = duration else {
            return XCTFail("Expected date range duration")
        }

        XCTAssertEqual(actualStart, start)
        XCTAssertEqual(actualEnd, end)
    }

    func testActivityAllowsMissingRouteOrder() {
        let activity = Activity(
            id: UUID(),
            title: "自由记录",
            kind: .note,
            place: nil,
            startTime: nil,
            endTime: nil,
            notes: "不参与路线排序",
            estimatedCost: nil,
            routeOrder: nil,
            reminder: nil
        )

        XCTAssertNil(activity.routeOrder)
    }

    func testBudgetPackingAndPlanningExposeStableFieldNames() {
        let budgetPlan = BudgetPlan(total: 12000, currencyCode: "CNY")
        let packingList = PackingList(items: [
            PackingItem(id: UUID(), title: "护照", isPacked: false, notes: nil)
        ])
        let planningScript = PlanningScript(
            id: UUID(),
            name: "Day planner",
            summary: "Builds a simple daily outline"
        )

        XCTAssertEqual(budgetPlan.total, 12000)
        XCTAssertEqual(budgetPlan.currencyCode, "CNY")
        XCTAssertEqual(packingList.items.count, 1)
        XCTAssertEqual(planningScript.name, "Day planner")
        XCTAssertEqual(planningScript.summary, "Builds a simple daily outline")
    }

    func testSampleTripHasOrderedMapReadyActivities() {
        let trip = SampleTripFactory.tokyoFiveDayTrip()

        let routeOrders = trip.days.flatMap { day in
            day.activities.compactMap(\.routeOrder)
        }

        XCTAssertEqual(trip.englishProductName, "Ayu Walk")
        XCTAssertFalse(routeOrders.isEmpty)
        XCTAssertEqual(routeOrders.min(), 1)
        XCTAssertTrue(trip.days.allSatisfy { !$0.activities.isEmpty })
    }

    func testMockPlanningEngineBuildsStructuredTripFromPrompt() {
        let engine = MockPlanningEngine()
        let trip = engine.generateTrip(
            destination: "东京",
            dayCount: 5,
            purpose: [.cityWalk, .food],
            notes: "想要轻松一点，适合发小红书"
        )

        XCTAssertEqual(trip.destination, "东京")
        XCTAssertEqual(trip.duration, .dayCount(5))
        XCTAssertEqual(trip.purpose, [.cityWalk, .food])
        XCTAssertEqual(trip.days.first?.activities.first?.routeOrder, 1)
        XCTAssertTrue(trip.planningScripts.contains { $0.name == "编号路线点" })
        XCTAssertEqual(trip.importedSources.count, 1)
        XCTAssertEqual(trip.importedSources.first?.kind, .pastedText)
        XCTAssertEqual(trip.importedSources.first?.title, "用户想法")
        XCTAssertEqual(trip.importedSources.first?.extractedText, "想要轻松一点，适合发小红书")
    }

    func testMockPlanningEngineIsDeterministicForSameInput() {
        let engine = MockPlanningEngine()

        let first = engine.generateTrip(
            destination: "东京",
            dayCount: 5,
            purpose: [.cityWalk, .food],
            notes: "想要轻松一点，适合发小红书"
        )

        let second = engine.generateTrip(
            destination: "东京",
            dayCount: 5,
            purpose: [.cityWalk, .food],
            notes: "想要轻松一点，适合发小红书"
        )

        XCTAssertEqual(first, second)
    }

    func testMockPlanningEngineReflectsNewTripInputInVisibleFields() {
        let trip = MockPlanningEngine().generateTrip(
            destination: "大阪",
            dayCount: 3,
            purpose: [.friends, .food],
            notes: "想轻松吃喝逛街"
        )

        XCTAssertEqual(trip.title, "大阪 3 日旅行")
        XCTAssertEqual(trip.destination, "大阪")
        XCTAssertEqual(trip.duration, .dayCount(3))
        XCTAssertEqual(trip.purpose, [.friends, .food])
        XCTAssertEqual(trip.importedSources.first?.extractedText, "想轻松吃喝逛街")
    }

    func testMockPlanningEngineUsesDestinationSpecificMapPlaces() {
        let trip = MockPlanningEngine().generateTrip(
            destination: "大阪",
            dayCount: 3,
            purpose: [.friends, .food],
            notes: "想轻松吃喝逛街"
        )

        let places = trip.days.flatMap { day in
            day.activities.compactMap(\.place)
        }

        XCTAssertEqual(trip.destination, "大阪")
        XCTAssertTrue(places.contains { $0.name == "道顿堀" })
        XCTAssertTrue(places.contains { $0.address?.contains("Osaka") == true })
        XCTAssertFalse(places.contains { $0.name == "涩谷" || $0.name == "原宿" })
        XCTAssertFalse(places.contains { $0.address?.contains("Tokyo") == true })
    }

    func testMockPlanningEngineBuildsMapPlacesAroundResolvedDestination() {
        let trip = MockPlanningEngine().generateTrip(
            destination: "巴黎",
            dayCount: 4,
            purpose: [.cityWalk],
            notes: "想轻松散步",
            destinationLocation: DestinationLocation(
                latitude: 48.8566,
                longitude: 2.3522,
                displayName: "Paris, France"
            )
        )

        let places = trip.days.flatMap { day in
            day.activities.compactMap(\.place)
        }

        XCTAssertEqual(trip.destination, "巴黎")
        XCTAssertTrue(places.allSatisfy { $0.name.contains("巴黎") })
        XCTAssertTrue(places.allSatisfy { $0.address?.contains("Paris, France") == true })
        XCTAssertTrue(places.allSatisfy { place in
            guard let latitude = place.latitude, let longitude = place.longitude else {
                return false
            }

            return abs(latitude - 48.8566) < 0.03 && abs(longitude - 2.3522) < 0.03
        })
        XCTAssertFalse(places.contains { $0.address?.contains("Tokyo") == true || $0.address?.contains("Osaka") == true })
    }

    func testMockPlanningEngineUsesDestinationCurrencyForResolvedDestination() {
        let trip = MockPlanningEngine().generateTrip(
            destination: "Paris, France",
            dayCount: 4,
            purpose: [.cityWalk],
            notes: "想轻松散步",
            destinationLocation: DestinationLocation(
                latitude: 48.8566,
                longitude: 2.3522,
                displayName: "Paris, France",
                countryCode: "FR",
                currencyCode: "EUR",
                administrativeLevel: .city
            )
        )

        XCTAssertEqual(trip.budgetPlan?.currencyCode, "EUR")
    }

    func testMockPlanningEngineBuildsRouteFromResolvedPlaces() {
        let louvre = Place(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000009101")!,
            name: "卢浮宫",
            address: "Rue de Rivoli, Paris",
            latitude: 48.8606,
            longitude: 2.3376,
            providerIDs: [.mapKit: "mapkit-louvre"]
        )
        let cafe = Place(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000009102")!,
            name: "花神咖啡馆",
            address: "Boulevard Saint-Germain, Paris",
            latitude: 48.8542,
            longitude: 2.3332,
            providerIDs: [.mapKit: "mapkit-cafe-de-flore"]
        )

        let trip = MockPlanningEngine().generateTrip(
            destination: "巴黎",
            dayCount: 2,
            purpose: [.cityWalk, .food],
            notes: "想看艺术和咖啡馆",
            resolvedPlaces: [louvre, cafe]
        )

        let activities = trip.days.flatMap(\.activities)

        XCTAssertEqual(trip.destination, "巴黎")
        XCTAssertEqual(trip.days.map(\.title), ["卢浮宫", "花神咖啡馆"])
        XCTAssertEqual(trip.days.map { $0.activities.count }, [4, 4])
        XCTAssertEqual(trip.days[0].activities[0].place, louvre)
        XCTAssertEqual(trip.days[1].activities[0].place, cafe)
        XCTAssertEqual(activities.compactMap(\.routeOrder), Array(1...8))
        XCTAssertTrue(trip.days.allSatisfy { day in
            day.activities.map(\.kind) == [.sight, .meal, .sight, .meal]
        })
        XCTAssertTrue(trip.days.allSatisfy { day in
            day.activities[1].title.contains("午饭")
                && day.activities[3].title.contains("晚饭")
        })
        XCTAssertTrue(trip.planningScripts.contains { $0.name == "MapKit 坐标匹配" })
    }

    func testMockPlanningEngineSplitsResolvedPlacesAcrossRequestedDays() {
        let places = (1...5).map { index in
            Place(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000920\(index)")!,
                name: "伦敦地点 \(index)",
                address: "London, United Kingdom",
                latitude: 51.50 + Double(index) * 0.001,
                longitude: -0.12 - Double(index) * 0.001,
                providerIDs: [.mapKit: "mapkit-london-\(index)"]
            )
        }

        let trip = MockPlanningEngine().generateTrip(
            destination: "London, United Kingdom",
            dayCount: 3,
            purpose: [.cityWalk],
            notes: "想轻松逛街",
            resolvedPlaces: places
        )

        XCTAssertEqual(trip.days.map(\.dayNumber), [1, 2, 3])
        XCTAssertEqual(trip.days.map(\.dateLabel), ["Day 1", "Day 2", "Day 3"])
        XCTAssertEqual(trip.days.map { $0.activities.count }, [4, 4, 4])
        XCTAssertTrue(trip.days.allSatisfy { day in
            day.activities.map(\.kind) == [.sight, .meal, .sight, .meal]
        })

        let activityTitles = trip.days.flatMap(\.activities).map(\.title)
        XCTAssertTrue(places.allSatisfy { place in
            activityTitles.contains(place.name)
        })
    }

    func testMockPlanningEngineKeepsRequestedDayCountWhenResolvedPlacesAreFewerThanDays() {
        let places = (1...3).map { index in
            Place(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000930\(index)")!,
                name: "伦敦地点 \(index)",
                address: "London, United Kingdom",
                latitude: 51.50 + Double(index) * 0.001,
                longitude: -0.12 - Double(index) * 0.001,
                providerIDs: [.mapKit: "mapkit-london-short-\(index)"]
            )
        }

        let trip = MockPlanningEngine().generateTrip(
            destination: "London, United Kingdom",
            dayCount: 7,
            purpose: [.cityWalk],
            notes: "想完整安排一周",
            resolvedPlaces: places
        )

        XCTAssertEqual(trip.days.map(\.dayNumber), Array(1...7))
        XCTAssertEqual(trip.days.map(\.dateLabel), (1...7).map { "Day \($0)" })
        XCTAssertTrue(trip.days.allSatisfy { $0.activities.count == 4 })
        XCTAssertEqual(Array(trip.days.prefix(3)).map { $0.activities[0].title }, places.map(\.name))
        XCTAssertTrue(trip.days.suffix(4).allSatisfy { day in
            day.activities.contains { $0.title.contains("London, United Kingdom") }
        })
    }

    func testMockPlanningEngineFillsDailyTemplateSlots() {
        let places = (1...15).map { index in
            Place(
                id: UUID(),
                name: "巴黎地点 \(index)",
                address: "Paris, France",
                latitude: 48.85 + Double(index) * 0.001,
                longitude: 2.33 + Double(index) * 0.001,
                providerIDs: [.mapKit: "mapkit-paris-template-\(index)"]
            )
        }

        let trip = MockPlanningEngine().generateTrip(
            destination: "Paris, France",
            dayCount: 7,
            purpose: [.cityWalk, .food],
            notes: "想要每天完整安排",
            resolvedPlaces: places
        )

        XCTAssertEqual(trip.days.count, 7)
        XCTAssertTrue(trip.days.allSatisfy { $0.activities.count == 4 })
        XCTAssertTrue(trip.days.allSatisfy { day in
            day.activities.map(\.kind) == [.sight, .meal, .sight, .meal]
        })
        XCTAssertTrue(trip.days.allSatisfy { day in
            day.activities.map(\.startTime) == ["09:30", "12:00", "15:00", "18:30"]
        })
        XCTAssertTrue(trip.days.allSatisfy { day in
            day.activities[1].title.contains("午饭") || day.activities[1].title.contains("午餐")
        })
        XCTAssertTrue(trip.days.allSatisfy { day in
            day.activities[3].title.contains("晚饭") || day.activities[3].title.contains("晚餐")
        })
    }

    func testMockPlanningEngineCapsTripLengthAtFourteenDays() {
        let trip = MockPlanningEngine().generateTrip(
            destination: "London, United Kingdom",
            dayCount: 30,
            purpose: [.cityWalk],
            notes: "最多只需要两周"
        )

        XCTAssertEqual(trip.duration, .dayCount(14))
        XCTAssertEqual(trip.days.map(\.dayNumber), Array(1...14))
        XCTAssertEqual(trip.title, "London, United Kingdom 14 日旅行")
    }

    func testMockPlanningEngineCreatesOneLocalizedDayPerRequestedDay() {
        let trip = MockPlanningEngine().generateTrip(
            destination: "蒙古国",
            dayCount: 3,
            purpose: [.cityWalk],
            notes: "想轻松逛",
            destinationLocation: DestinationLocation(
                latitude: 47.9184,
                longitude: 106.9177,
                displayName: "蒙古国",
                countryCode: "MN",
                currencyCode: "MNT",
                administrativeLevel: .country
            )
        )

        XCTAssertEqual(trip.days.map(\.dayNumber), [1, 2, 3])
        XCTAssertEqual(trip.days.map(\.dateLabel), ["Day 1", "Day 2", "Day 3"])
        XCTAssertTrue(trip.days.allSatisfy { !$0.activities.isEmpty })
        XCTAssertEqual(trip.budgetPlan?.currencyCode, "MNT")
    }

    func testMockPlanningEngineKeepsRequestedDayCountForUnresolvedDestination() {
        let trip = MockPlanningEngine().generateTrip(
            destination: "未知目的地",
            dayCount: 7,
            purpose: [.cityWalk],
            notes: "先保留结构"
        )

        XCTAssertEqual(trip.days.map(\.dayNumber), Array(1...7))
        XCTAssertEqual(trip.days.map(\.dateLabel), (1...7).map { "Day \($0)" })
        XCTAssertTrue(trip.days.allSatisfy { !$0.activities.isEmpty })
        XCTAssertTrue(trip.days.allSatisfy { day in
            day.activities.allSatisfy { $0.title.contains("未知目的地") }
        })
    }

    func testMockPlanningEngineDoesNotFallbackToJapanForUnknownDestinationWithoutLocation() {
        let trip = MockPlanningEngine().generateTrip(
            destination: "巴黎",
            dayCount: 4,
            purpose: [.cityWalk],
            notes: "想轻松散步"
        )

        let places = trip.days.flatMap { day in
            day.activities.compactMap(\.place)
        }

        XCTAssertEqual(trip.destination, "巴黎")
        XCTAssertTrue(places.allSatisfy { $0.name.contains("巴黎") })
        XCTAssertFalse(places.contains { $0.address?.contains("Tokyo") == true || $0.address?.contains("Osaka") == true })
        XCTAssertTrue(places.allSatisfy { $0.latitude == nil && $0.longitude == nil })
    }

    func testMockPlanningEnginePreservesImportedSourceWhenProvided() {
        let source = ImportedSource(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000009001")!,
            kind: .pastedText,
            title: "小红书攻略文本",
            url: nil,
            extractedText: "黑门市场、道顿堀、梅田夜景"
        )

        let trip = MockPlanningEngine().generateTrip(
            destination: "大阪",
            dayCount: 3,
            purpose: [.food],
            notes: "根据导入资料安排行程",
            importedSources: [source]
        )

        XCTAssertEqual(trip.importedSources, [source])
    }
}
