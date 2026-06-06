import AyuWalkCore
import Foundation

struct MiniMaxPlaceSuggestion: Decodable, Equatable {
    var name: String
    var address: String?
    var latitude: Double?
    var longitude: Double?
    var countryCode: String?
    var dayNumber: Int?
    var category: String?
    var suggestedDurationMinutes: Int?
    var reason: String?
}

struct MiniMaxPlanningResult: Equatable {
    var suggestions: [MiniMaxPlaceSuggestion]
    var proposal: AIPlanningProposal?
    var statusMessage: String
}

struct MiniMaxItineraryPlanner {
    var runtime: MiniMaxRuntime
    var urlSession: URLSession = .shared

    func suggestPlaces(
        destination: String,
        dayCount: Int,
        purpose: [TravelPurpose],
        notes: String,
        importedSource: ImportedSource?
    ) async -> MiniMaxPlanningResult {
        guard let configuration = runtime.configuration else {
            let fallbackSuggestions = Self.fallbackSuggestions(for: destination)
            return MiniMaxPlanningResult(
                suggestions: fallbackSuggestions,
                proposal: nil,
                statusMessage: fallbackSuggestions.isEmpty
                    ? "MiniMax 未配置，已使用 MapKit 目的地定位生成路线。"
                    : "MiniMax 未配置，已使用内置真实地点候选交给 MapKit 匹配坐标。"
            )
        }

        do {
            let request = try makeRequest(
                configuration: configuration,
                destination: destination,
                dayCount: dayCount,
                purpose: purpose,
                notes: notes,
                importedSource: importedSource
            )
            let (data, response) = try await fetchData(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                let fallbackSuggestions = Self.fallbackSuggestions(for: destination)
                return MiniMaxPlanningResult(
                    suggestions: fallbackSuggestions,
                    proposal: nil,
                    statusMessage: fallbackSuggestions.isEmpty
                        ? "MiniMax 请求失败（HTTP \(statusCode)），已使用 MapKit 目的地定位生成路线。"
                        : "MiniMax 请求失败（HTTP \(statusCode)），已使用内置目的地候选交给 MapKit 匹配坐标。"
                )
            }

            let content = try JSONDecoder().decode(MiniMaxChatResponse.self, from: data)
                .content
                .compactMap(\.text)
                .joined(separator: "\n")

            let proposal = try? AIPlanningResponseDecoder.decode(
                content,
                source: .remoteAI,
                dayCount: dayCount
            )
            let suggestions = proposal.map(Self.suggestions(from:)) ?? parseSuggestions(from: content)
            let finalSuggestions = suggestions.isEmpty ? Self.fallbackSuggestions(for: destination) : suggestions
            return MiniMaxPlanningResult(
                suggestions: finalSuggestions,
                proposal: proposal?.days.isEmpty == false ? proposal : nil,
                statusMessage: proposal?.days.isEmpty == false
                    ? "MiniMax 已生成结构化行程，并交给 MapKit 校验地点坐标。"
                    : suggestions.isEmpty
                    ? "MiniMax 未返回可用地点，已使用内置目的地候选交给 MapKit 匹配坐标。"
                    : "MiniMax 已生成 \(suggestions.count) 个候选地点，并交给 MapKit 匹配坐标。"
            )
        } catch {
            let fallbackSuggestions = Self.fallbackSuggestions(for: destination)
            return MiniMaxPlanningResult(
                suggestions: fallbackSuggestions,
                proposal: nil,
                statusMessage: fallbackSuggestions.isEmpty
                    ? "MiniMax 请求异常，已使用 MapKit 目的地定位生成路线。"
                    : "MiniMax 请求异常，已使用内置目的地候选交给 MapKit 匹配坐标。"
            )
        }
    }

    private func makeRequest(
        configuration: MiniMaxConfiguration,
        destination: String,
        dayCount: Int,
        purpose: [TravelPurpose],
        notes: String,
        importedSource: ImportedSource?
    ) throws -> URLRequest {
        let endpoint = configuration.baseURL.appending(path: "v1/messages")
        let normalizedDayCount = TripPlanningLimits.normalizedDayCount(dayCount)
        let minimumPlaceCount = max(normalizedDayCount * 3, 8)
        let maximumPlaceCount = max(normalizedDayCount * 4, 12)
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 12
        request.setValue(configuration.apiKey, forHTTPHeaderField: "X-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let userPrompt = """
        目的地：\(destination)
        天数：\(normalizedDayCount)
        旅行目的：\(purpose.map(\.rawValue).joined(separator: ", "))
        用户想法：\(notes)
        导入资料：\(importedSource?.extractedText ?? "无")

        请只返回 JSON，不要 Markdown。格式：
        {
          "confidence":0.85,
          "questions":[{"id":"pace","prompt":"希望行程节奏如何？","options":["轻松","均衡","充实"],"isRequired":false}],
          "assumptions":[{"id":"pace","text":"未指定节奏，默认使用均衡安排"}],
          "adjustmentReason":null,
          "days":[{
            "dayNumber":1,
            "title":"当天主题",
            "activities":[{
              "title":"活动标题",
              "kind":"sight",
              "place":{"name":"真实地点名","address":"完整地址或城市国家","latitude":48.8566,"longitude":2.3522},
              "startTime":"10:00",
              "endTime":"11:30",
              "notes":"推荐原因和安排说明",
              "estimatedCost":0,
              "isFixedNode":false
            }]
          }]
        }
        规则：
        - 先判断信息是否足够；仅在确实影响规划时返回最多 3 个简短 questions，否则返回空数组并在 assumptions 说明合理假设。
        - confidence 必须在 0 到 1 之间，反映地点、时间和用户意图的可靠程度。
        - 必须返回 \(normalizedDayCount) 个 days；每天安排 2 到 4 个活动，并保留合理休息时间。
        - 每个 place 必须包含 latitude、longitude，且坐标必须落在目的地所在国家和城市附近。
        - 地点必须真实存在，适合 Apple MapKit 搜索。
        - 地点必须在目的地定位结果所在城市，不要跨城市，不要返回同名城市或其他国家/地区的地点。
        - 地点名优先使用当地官方名称或英文名称，例如大阪使用 Dotonbori / Osaka Castle / Kuromon Market。
        - kind 只能用 sight、meal、shopping、hotel、transport、concert、freeTime、note 之一。
        - 不要把不确定的航班、酒店或活动时间标记为 isFixedNode。
        - 如果用户导入资料里有地点，优先保留。
        - 总活动地点数量建议在 \(minimumPlaceCount) 到 \(maximumPlaceCount) 之间。
        """

        let body = MiniMaxChatRequest(
            model: configuration.model,
            maxTokens: 4_096,
            messages: [
                MiniMaxChatMessage(role: "user", content: userPrompt)
            ],
            system: "你是旅行规划助手。你的任务是生成可执行、可编辑的结构化日程，并清楚表达置信度、必要问题和假设。最终 text 块必须只返回有效 JSON，不要 Markdown，不要解释。",
            temperature: 0.3
        )
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func fetchData(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withThrowingTaskGroup(of: (Data, URLResponse).self) { group in
            group.addTask {
                try await urlSession.data(for: request)
            }
            group.addTask {
                try await Task.sleep(for: .seconds(12))
                throw URLError(.timedOut)
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    private func parseSuggestions(from content: String) -> [MiniMaxPlaceSuggestion] {
        let trimmed = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonText = extractJSONObject(from: trimmed) ?? trimmed

        guard let data = jsonText.data(using: .utf8),
              let response = try? JSONDecoder().decode(MiniMaxPlaceSuggestionResponse.self, from: data) else {
            return []
        }

        return response.places
            .map { suggestion in
                MiniMaxPlaceSuggestion(
                    name: suggestion.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    address: suggestion.address,
                    latitude: suggestion.latitude,
                    longitude: suggestion.longitude,
                    countryCode: suggestion.countryCode,
                    dayNumber: suggestion.dayNumber,
                    category: suggestion.category,
                    suggestedDurationMinutes: suggestion.suggestedDurationMinutes,
                    reason: suggestion.reason
                )
            }
            .filter { !$0.name.isEmpty }
    }

    private func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start <= end else {
            return nil
        }

        return String(text[start...end])
    }

    private static func suggestions(from proposal: AIPlanningProposal) -> [MiniMaxPlaceSuggestion] {
        proposal.days.flatMap { day in
            day.activities.compactMap { activity in
                guard let place = activity.place else {
                    return nil
                }
                return MiniMaxPlaceSuggestion(
                    name: place.name,
                    address: place.address,
                    latitude: place.latitude,
                    longitude: place.longitude,
                    countryCode: nil,
                    dayNumber: day.dayNumber,
                    category: activity.kind.rawValue,
                    suggestedDurationMinutes: nil,
                    reason: activity.notes
                )
            }
        }
    }

    private static func fallbackSuggestions(for destination: String) -> [MiniMaxPlaceSuggestion] {
        let normalized = destination
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        let candidates: [(keywords: [String], places: [MiniMaxPlaceSuggestion])] = [
            (
                ["paris", "巴黎"],
                [
                    MiniMaxPlaceSuggestion(name: "Place des Vosges", address: "Paris, France", latitude: 48.8556, longitude: 2.3655, countryCode: "FR", dayNumber: 1, category: "sight", suggestedDurationMinutes: 75, reason: "适合轻松散步和咖啡休息"),
                    MiniMaxPlaceSuggestion(name: "Le Marais", address: "Paris, France", latitude: 48.8575, longitude: 2.3583, countryCode: "FR", dayNumber: 1, category: "shopping", suggestedDurationMinutes: 120, reason: "适合逛店、吃甜点和 city walk"),
                    MiniMaxPlaceSuggestion(name: "Centre Pompidou", address: "Paris, France", latitude: 48.8606, longitude: 2.3522, countryCode: "FR", dayNumber: 1, category: "sight", suggestedDurationMinutes: 120, reason: "艺术和建筑都适合作为城市路线节点"),
                    MiniMaxPlaceSuggestion(name: "Canal Saint-Martin", address: "Paris, France", latitude: 48.8707, longitude: 2.3650, countryCode: "FR", dayNumber: 2, category: "sight", suggestedDurationMinutes: 90, reason: "河岸路线轻松，适合拍照记录"),
                    MiniMaxPlaceSuggestion(name: "Galeries Lafayette Haussmann", address: "Paris, France", latitude: 48.8738, longitude: 2.3320, countryCode: "FR", dayNumber: 2, category: "shopping", suggestedDurationMinutes: 120, reason: "购物和屋顶观景都方便"),
                    MiniMaxPlaceSuggestion(name: "Opéra Garnier", address: "Paris, France", latitude: 48.8719, longitude: 2.3316, countryCode: "FR", dayNumber: 2, category: "sight", suggestedDurationMinutes: 90, reason: "和百货区域顺路"),
                    MiniMaxPlaceSuggestion(name: "Marché d'Aligre", address: "Paris, France", latitude: 48.8497, longitude: 2.3789, countryCode: "FR", dayNumber: 3, category: "meal", suggestedDurationMinutes: 90, reason: "适合体验本地市场和小吃"),
                    MiniMaxPlaceSuggestion(name: "Coulée Verte René-Dumont", address: "Paris, France", latitude: 48.8464, longitude: 2.3716, countryCode: "FR", dayNumber: 3, category: "sight", suggestedDurationMinutes: 90, reason: "轻松散步路线"),
                    MiniMaxPlaceSuggestion(name: "Bastille", address: "Paris, France", latitude: 48.8530, longitude: 2.3690, countryCode: "FR", dayNumber: 3, category: "sight", suggestedDurationMinutes: 60, reason: "和东部路线衔接自然"),
                    MiniMaxPlaceSuggestion(name: "Musée d'Orsay", address: "Paris, France", latitude: 48.8600, longitude: 2.3266, countryCode: "FR", dayNumber: 4, category: "sight", suggestedDurationMinutes: 150, reason: "经典艺术馆"),
                    MiniMaxPlaceSuggestion(name: "Saint-Germain-des-Prés", address: "Paris, France", latitude: 48.8543, longitude: 2.3330, countryCode: "FR", dayNumber: 4, category: "sight", suggestedDurationMinutes: 90, reason: "咖啡馆和街区散步"),
                    MiniMaxPlaceSuggestion(name: "Jardin du Luxembourg", address: "Paris, France", latitude: 48.8462, longitude: 2.3372, countryCode: "FR", dayNumber: 4, category: "freeTime", suggestedDurationMinutes: 75, reason: "适合休息和手帐记录"),
                    MiniMaxPlaceSuggestion(name: "Montmartre", address: "Paris, France", latitude: 48.8867, longitude: 2.3431, countryCode: "FR", dayNumber: 5, category: "sight", suggestedDurationMinutes: 150, reason: "适合半日慢逛"),
                    MiniMaxPlaceSuggestion(name: "Sacré-Cœur", address: "Paris, France", latitude: 48.8867, longitude: 2.3431, countryCode: "FR", dayNumber: 5, category: "sight", suggestedDurationMinutes: 75, reason: "和蒙马特同区"),
                    MiniMaxPlaceSuggestion(name: "Rue des Martyrs", address: "Paris, France", latitude: 48.8797, longitude: 2.3375, countryCode: "FR", dayNumber: 5, category: "meal", suggestedDurationMinutes: 90, reason: "适合咖啡甜点和小店")
                ]
            ),
            (
                ["london", "伦敦"],
                [
                    MiniMaxPlaceSuggestion(name: "Covent Garden", address: "London, United Kingdom", latitude: 51.5117, longitude: -0.1240, countryCode: "GB", dayNumber: 1, category: "shopping", suggestedDurationMinutes: 90, reason: "适合轻松逛街和看街头表演"),
                    MiniMaxPlaceSuggestion(name: "Neal's Yard", address: "London, United Kingdom", latitude: 51.5144, longitude: -0.1268, countryCode: "GB", dayNumber: 1, category: "meal", suggestedDurationMinutes: 60, reason: "适合拍照、咖啡和短暂停留"),
                    MiniMaxPlaceSuggestion(name: "British Museum", address: "London, United Kingdom", latitude: 51.5194, longitude: -0.1270, countryCode: "GB", dayNumber: 1, category: "sight", suggestedDurationMinutes: 150, reason: "经典室内景点，天气不好也可安排"),
                    MiniMaxPlaceSuggestion(name: "South Bank", address: "London, United Kingdom", latitude: 51.5067, longitude: -0.1163, countryCode: "GB", dayNumber: 2, category: "sight", suggestedDurationMinutes: 120, reason: "沿泰晤士河散步，路线清晰"),
                    MiniMaxPlaceSuggestion(name: "Borough Market", address: "London, United Kingdom", latitude: 51.5055, longitude: -0.0910, countryCode: "GB", dayNumber: 2, category: "meal", suggestedDurationMinutes: 90, reason: "适合饭点和小吃探索"),
                    MiniMaxPlaceSuggestion(name: "Tate Modern", address: "London, United Kingdom", latitude: 51.5076, longitude: -0.0994, countryCode: "GB", dayNumber: 2, category: "sight", suggestedDurationMinutes: 120, reason: "和南岸路线顺路"),
                    MiniMaxPlaceSuggestion(name: "Hyde Park", address: "London, United Kingdom", latitude: 51.5073, longitude: -0.1657, countryCode: "GB", dayNumber: 3, category: "freeTime", suggestedDurationMinutes: 90, reason: "适合休息和散步"),
                    MiniMaxPlaceSuggestion(name: "Kensington Palace", address: "London, United Kingdom", latitude: 51.5050, longitude: -0.1877, countryCode: "GB", dayNumber: 3, category: "sight", suggestedDurationMinutes: 90, reason: "和海德公园同区"),
                    MiniMaxPlaceSuggestion(name: "Harrods", address: "London, United Kingdom", latitude: 51.4994, longitude: -0.1632, countryCode: "GB", dayNumber: 3, category: "shopping", suggestedDurationMinutes: 90, reason: "购物和室内停留"),
                    MiniMaxPlaceSuggestion(name: "Camden Market", address: "London, United Kingdom", latitude: 51.5416, longitude: -0.1469, countryCode: "GB", dayNumber: 4, category: "meal", suggestedDurationMinutes: 120, reason: "适合小吃和街区探索"),
                    MiniMaxPlaceSuggestion(name: "Regent's Park", address: "London, United Kingdom", latitude: 51.5313, longitude: -0.1569, countryCode: "GB", dayNumber: 4, category: "freeTime", suggestedDurationMinutes: 90, reason: "适合放慢节奏"),
                    MiniMaxPlaceSuggestion(name: "Primrose Hill", address: "London, United Kingdom", latitude: 51.5390, longitude: -0.1607, countryCode: "GB", dayNumber: 4, category: "sight", suggestedDurationMinutes: 60, reason: "适合看城市景观")
                ]
            ),
            (
                ["osaka", "大阪"],
                [
                    MiniMaxPlaceSuggestion(name: "Osaka Castle", address: "Osaka, Japan", latitude: 34.6873, longitude: 135.5262, countryCode: "JP", dayNumber: 1, category: "sight", suggestedDurationMinutes: 120, reason: "经典地标，适合作为路线起点"),
                    MiniMaxPlaceSuggestion(name: "Nakanoshima Park", address: "Osaka, Japan", latitude: 34.6937, longitude: 135.5034, countryCode: "JP", dayNumber: 1, category: "freeTime", suggestedDurationMinutes: 75, reason: "适合轻松散步"),
                    MiniMaxPlaceSuggestion(name: "Umeda Sky Building", address: "Osaka, Japan", latitude: 34.7053, longitude: 135.4896, countryCode: "JP", dayNumber: 1, category: "sight", suggestedDurationMinutes: 90, reason: "适合夜景"),
                    MiniMaxPlaceSuggestion(name: "Dotonbori", address: "Osaka, Japan", latitude: 34.6687, longitude: 135.5013, countryCode: "JP", dayNumber: 2, category: "meal", suggestedDurationMinutes: 120, reason: "适合美食和夜景记录"),
                    MiniMaxPlaceSuggestion(name: "Kuromon Market", address: "Osaka, Japan", latitude: 34.6647, longitude: 135.5065, countryCode: "JP", dayNumber: 2, category: "meal", suggestedDurationMinutes: 90, reason: "适合饭点和小吃探索"),
                    MiniMaxPlaceSuggestion(name: "Shinsaibashi Shopping Arcade", address: "Osaka, Japan", latitude: 34.6740, longitude: 135.5011, countryCode: "JP", dayNumber: 2, category: "shopping", suggestedDurationMinutes: 120, reason: "适合购物和 city walk"),
                    MiniMaxPlaceSuggestion(name: "Shinsekai", address: "Osaka, Japan", latitude: 34.6525, longitude: 135.5063, countryCode: "JP", dayNumber: 3, category: "meal", suggestedDurationMinutes: 90, reason: "大阪本地风味明显"),
                    MiniMaxPlaceSuggestion(name: "Tsutenkaku", address: "Osaka, Japan", latitude: 34.6525, longitude: 135.5063, countryCode: "JP", dayNumber: 3, category: "sight", suggestedDurationMinutes: 60, reason: "和新世界同区"),
                    MiniMaxPlaceSuggestion(name: "Tennoji Park", address: "Osaka, Japan", latitude: 34.6500, longitude: 135.5110, countryCode: "JP", dayNumber: 3, category: "freeTime", suggestedDurationMinutes: 75, reason: "适合休息和拍照")
                ]
            )
        ]

        return candidates.first { candidate in
            candidate.keywords.contains { normalized.contains($0) }
        }?.places ?? []
    }
}

private struct MiniMaxChatRequest: Encodable {
    var model: String
    var maxTokens: Int
    var messages: [MiniMaxChatMessage]
    var system: String
    var temperature: Double

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
        case system
        case temperature
    }
}

private struct MiniMaxChatMessage: Codable {
    var role: String
    var content: String
}

private struct MiniMaxChatResponse: Decodable {
    var content: [ContentBlock]

    struct ContentBlock: Decodable {
        var type: String
        var text: String?
    }
}

private struct MiniMaxPlaceSuggestionResponse: Decodable {
    var places: [MiniMaxPlaceSuggestion]
}
