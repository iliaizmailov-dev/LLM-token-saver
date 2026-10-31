import Foundation

enum LLMProvider: String, CaseIterable, Identifiable {
    case openAI
    case copilot

    var id: String { rawValue }

    var title: String {
        switch self {
        case .openAI:
            return "OpenAI"
        case .copilot:
            return "GitHub Copilot"
        }
    }

    var defaultModel: String {
        switch self {
        case .openAI:
            return "gpt-4o-mini"
        case .copilot:
            return "gpt-4o-mini"
        }
    }

    var endpoint: URL {
        switch self {
        case .openAI:
            return URL(string: "https://api.openai.com/v1/chat/completions")!
        case .copilot:
            return URL(string: "https://api.githubcopilot.com/v1/chat/completions")!
        }
    }
}
