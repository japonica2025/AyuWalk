import Foundation

public struct PackingTemplate: Equatable, Identifiable, Sendable {
    public let id: PackingTemplateID
    public var title: String
    public var subtitle: String
    public var systemImage: String
    public var items: [PackingTemplateItem]

    public init(
        id: PackingTemplateID,
        title: String,
        subtitle: String,
        systemImage: String,
        items: [PackingTemplateItem]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.items = items
    }
}

public enum PackingTemplateID: String, CaseIterable, Equatable, Hashable, Sendable {
    case shortTrip
    case international
    case weatherReady
    case contentCreator
    case family
}

public struct PackingTemplateItem: Equatable, Sendable {
    public var title: String
    public var notes: String?

    public init(title: String, notes: String?) {
        self.title = title
        self.notes = notes
    }
}

public struct PackingTemplateRecommendation: Equatable, Identifiable, Sendable {
    public var id: PackingTemplateID { template.id }
    public var template: PackingTemplate
    public var reason: String
    public var priority: Int

    public init(template: PackingTemplate, reason: String, priority: Int) {
        self.template = template
        self.reason = reason
        self.priority = priority
    }
}

public enum PackingTemplateLibrary {
    public static let `default`: [PackingTemplate] = [
        PackingTemplate(
            id: .shortTrip,
            title: "基础短途",
            subtitle: "两三天轻装出发",
            systemImage: "backpack.fill",
            items: [
                PackingTemplateItem(title: "身份证件", notes: nil),
                PackingTemplateItem(title: "手机充电器", notes: nil),
                PackingTemplateItem(title: "换洗衣物", notes: "按天数准备"),
                PackingTemplateItem(title: "洗漱用品", notes: nil),
                PackingTemplateItem(title: "常用药", notes: nil)
            ]
        ),
        PackingTemplate(
            id: .international,
            title: "海外旅行",
            subtitle: "证件、支付和网络",
            systemImage: "airplane",
            items: [
                PackingTemplateItem(title: "护照", notes: "检查有效期"),
                PackingTemplateItem(title: "签证或入境材料", notes: nil),
                PackingTemplateItem(title: "转换插头", notes: nil),
                PackingTemplateItem(title: "境外流量卡", notes: nil),
                PackingTemplateItem(title: "银行卡与备用现金", notes: nil),
                PackingTemplateItem(title: "旅行保险资料", notes: nil)
            ]
        ),
        PackingTemplate(
            id: .weatherReady,
            title: "雨天温差",
            subtitle: "应对降雨和冷热变化",
            systemImage: "cloud.rain.fill",
            items: [
                PackingTemplateItem(title: "折叠伞", notes: nil),
                PackingTemplateItem(title: "轻薄外套", notes: nil),
                PackingTemplateItem(title: "防水鞋套", notes: nil),
                PackingTemplateItem(title: "备用袜子", notes: nil),
                PackingTemplateItem(title: "防晒用品", notes: nil)
            ]
        ),
        PackingTemplate(
            id: .contentCreator,
            title: "拍照内容",
            subtitle: "相机、补电和素材整理",
            systemImage: "camera.fill",
            items: [
                PackingTemplateItem(title: "相机", notes: nil),
                PackingTemplateItem(title: "备用电池", notes: nil),
                PackingTemplateItem(title: "存储卡", notes: nil),
                PackingTemplateItem(title: "充电宝", notes: nil),
                PackingTemplateItem(title: "迷你三脚架", notes: nil),
                PackingTemplateItem(title: "读卡器", notes: nil)
            ]
        ),
        PackingTemplate(
            id: .family,
            title: "亲子出行",
            subtitle: "儿童用品与应急准备",
            systemImage: "figure.2.and.child.holdinghands",
            items: [
                PackingTemplateItem(title: "儿童证件", notes: nil),
                PackingTemplateItem(title: "儿童常用药", notes: nil),
                PackingTemplateItem(title: "湿巾与纸巾", notes: nil),
                PackingTemplateItem(title: "零食与饮水", notes: nil),
                PackingTemplateItem(title: "备用衣物", notes: nil),
                PackingTemplateItem(title: "安抚玩具", notes: nil)
            ]
        )
    ]

    public static func applying(_ template: PackingTemplate, to packingList: PackingList) -> PackingList {
        applying([template], to: packingList)
    }

    public static func applying(_ templates: [PackingTemplate], to packingList: PackingList) -> PackingList {
        var mergedItems = packingList.items
        var existingTitles = Set(mergedItems.map { normalizedTitle($0.title) })

        for template in templates {
            for templateItem in template.items {
                let normalized = normalizedTitle(templateItem.title)
                guard !existingTitles.contains(normalized) else {
                    continue
                }

                mergedItems.append(
                    PackingItem(
                        id: UUID(),
                        title: templateItem.title,
                        isPacked: false,
                        notes: templateItem.notes
                    )
                )
                existingTitles.insert(normalized)
            }
        }

        return PackingList(items: mergedItems, reminder: packingList.reminder)
    }

    public static func isApplied(_ template: PackingTemplate, to packingList: PackingList) -> Bool {
        let existingTitles = Set(packingList.items.map { normalizedTitle($0.title) })
        return template.items.allSatisfy { existingTitles.contains(normalizedTitle($0.title)) }
    }

    public static func recommendations(for trip: Trip, packingList: PackingList?) -> [PackingTemplateRecommendation] {
        let currentPackingList = packingList ?? PackingList(items: [])
        let templatesByID = Dictionary(uniqueKeysWithValues: Self.default.map { ($0.id, $0) })
        var recommendations: [PackingTemplateRecommendation] = []

        func append(_ templateID: PackingTemplateID, reason: String, priority: Int) {
            guard let template = templatesByID[templateID],
                  !isApplied(template, to: currentPackingList),
                  !recommendations.contains(where: { $0.template.id == templateID }) else {
                return
            }
            recommendations.append(PackingTemplateRecommendation(template: template, reason: reason, priority: priority))
        }

        let dayCount = dayCount(for: trip)
        if isLikelyInternational(trip) {
            append(.international, reason: "海外目的地，建议先补齐证件、网络和支付材料。", priority: 10)
        }

        if dayCount <= 3 {
            append(.shortTrip, reason: "\(dayCount) 天短途行程，适合先生成基础轻装清单。", priority: 20)
        }

        if dayCount >= 4 || destinationSuggestsWeatherPrep(trip.destination) {
            append(.weatherReady, reason: "\(dayCount) 天行程可能遇到天气和温差变化。", priority: 30)
        }

        if suggestsPhotoGear(trip) {
            append(.contentCreator, reason: "行程里包含拍照或素材记录，建议准备补电和存储用品。", priority: 40)
        }

        if trip.purpose.contains(.family) {
            append(.family, reason: "亲子出行，建议补充儿童用品和应急准备。", priority: 50)
        }

        return recommendations.sorted { lhs, rhs in
            if lhs.priority != rhs.priority {
                return lhs.priority < rhs.priority
            }
            return lhs.template.title < rhs.template.title
        }
    }

    private static func normalizedTitle(_ title: String) -> String {
        title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .widthInsensitive], locale: .current)
    }

    private static func dayCount(for trip: Trip) -> Int {
        switch trip.duration {
        case .dayCount(let count):
            return TripPlanningLimits.normalizedDayCount(count)
        case .dateRange(let start, let end):
            let calendar = Calendar(identifier: .gregorian)
            let startOfDay = calendar.startOfDay(for: start)
            let endOfDay = calendar.startOfDay(for: end)
            let days = calendar.dateComponents([.day], from: startOfDay, to: endOfDay).day ?? 0
            return TripPlanningLimits.normalizedDayCount(days + 1)
        }
    }

    private static func isLikelyInternational(_ trip: Trip) -> Bool {
        if let budgetCurrencyCode = trip.budgetPlan?.currencyCode,
           !budgetCurrencyCode.isEmpty,
           budgetCurrencyCode.uppercased() != "CNY" {
            return true
        }

        switch DestinationResolver.resolve(trip.destination) {
        case .resolved(let location):
            return location.countryCode?.uppercased() != "CN"
        case .ambiguous, .unresolved:
            return false
        }
    }

    private static func destinationSuggestsWeatherPrep(_ destination: String) -> Bool {
        let normalized = normalizedTitle(destination)
        let weatherKeywords = [
            "伦敦", "london", "巴黎", "paris", "东京", "東京", "tokyo", "大阪", "osaka",
            "北海道", "雪", "海边", "海島", "海岛", "山", "雨"
        ]
        return weatherKeywords.contains { normalized.contains($0) }
    }

    private static func suggestsPhotoGear(_ trip: Trip) -> Bool {
        let photoKeywords = ["拍照", "摄影", "相机", "照片", "素材", "photo", "camera", "vlog", "胶片"]
        let activityText = trip.days
            .flatMap(\.activities)
            .map { [$0.title, $0.notes ?? "", $0.place?.name ?? ""].joined(separator: " ") }
            .joined(separator: " ")
        let normalized = normalizedTitle(activityText)
        return photoKeywords.contains { normalized.contains($0) }
    }
}
