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

        return PackingList(items: mergedItems)
    }

    public static func isApplied(_ template: PackingTemplate, to packingList: PackingList) -> Bool {
        let existingTitles = Set(packingList.items.map { normalizedTitle($0.title) })
        return template.items.allSatisfy { existingTitles.contains(normalizedTitle($0.title)) }
    }

    private static func normalizedTitle(_ title: String) -> String {
        title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .widthInsensitive], locale: .current)
    }
}
