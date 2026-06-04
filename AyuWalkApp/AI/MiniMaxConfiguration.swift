import Foundation

struct MiniMaxConfiguration: Equatable {
    enum Source: Equatable {
        case localEnvironment
        case backendProxy
    }

    var apiKey: String
    var baseURL: URL
    var model: String
    var source: Source

    var redactedDescription: String {
        guard apiKey.count > 8 else {
            return "MiniMax key: configured"
        }

        return "MiniMax key: \(apiKey.prefix(4))...\(apiKey.suffix(4))"
    }

    static func localDevelopment(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> MiniMaxConfiguration? {
        guard let apiKey = firstValue(
            for: "MINIMAX_API_KEY",
            environment: environment
        )?.trimmingCharacters(in: .whitespacesAndNewlines),
              !apiKey.isEmpty else {
            return nil
        }

        let baseURL = firstValue(for: "MINIMAX_API_HOST", environment: environment)
            .flatMap(URL.init(string:))
            ?? URL(string: "https://api.minimaxi.com/anthropic")!
        let model = firstValue(for: "MINIMAX_MODEL", environment: environment)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return MiniMaxConfiguration(
            apiKey: apiKey,
            baseURL: baseURL,
            model: model?.isEmpty == false ? model! : "MiniMax-M2.7",
            source: .localEnvironment
        )
    }

    private static func firstValue(for key: String, environment: [String: String]) -> String? {
        if let value = environment[key], !value.isEmpty {
            return value
        }

        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
           !value.isEmpty {
            return value
        }

        let bundleKey: String
        switch key {
        case "MINIMAX_API_KEY":
            bundleKey = "AyuWalkMiniMaxAPIKey"
        case "MINIMAX_API_HOST":
            bundleKey = "AyuWalkMiniMaxAPIHost"
        case "MINIMAX_MODEL":
            bundleKey = "AyuWalkMiniMaxModel"
        default:
            bundleKey = key
        }

        return Bundle.main.object(forInfoDictionaryKey: bundleKey) as? String
    }
}

struct MiniMaxRuntime {
    var configuration: MiniMaxConfiguration?

    static let live = MiniMaxRuntime(
        configuration: .localDevelopment()
    )

    var isConfigured: Bool {
        configuration != nil
    }
}
