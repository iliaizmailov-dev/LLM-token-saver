import Foundation

enum LLMProvider: String, CaseIterable, Identifiable {
    case openAI
    case microsoft365Copilot

    var id: String { rawValue }

    var title: String {
        switch self {
        case .openAI:
            return "OpenAI"
        case .microsoft365Copilot:
            return "Microsoft 365 Copilot"
        }
    }

    var defaultModel: String {
        switch self {
        case .openAI:
            return "gpt-4o-mini"
        case .microsoft365Copilot:
            return "gpt-4o-mini"
        }
    }

    var defaultEndpointURL: URL {
        switch self {
        case .openAI:
            return URL(string: "https://api.openai.com/v1/chat/completions")!
        case .microsoft365Copilot:
            return URL(string: "https://graph.microsoft.com")!
        }
    }
}
