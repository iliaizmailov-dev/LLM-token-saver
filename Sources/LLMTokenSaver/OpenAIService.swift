import Foundation

struct OpenAIChatMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIService {

    func sendChat(
        provider: LLMProvider,
        apiKey: String,
        model: String,
        messages: [OpenAIChatMessage],
        endpointOverride: String? = nil
    ) async throws -> String {

        let payload = ChatRequest(
            model: model,
            messages: messages
        )

        let endpointURL: URL
        if let endpointOverride,
           let url = URL(string: endpointOverride.trimmingCharacters(in: .whitespacesAndNewlines)) {
            endpointURL = url
        } else {
            endpointURL = provider.defaultEndpointURL
        }

        var request = URLRequest(
            url: endpointURL
        )

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.setValue(
            "Bearer \(apiKey)",
            forHTTPHeaderField: "Authorization"
        )

        request.httpBody =
            try JSONEncoder().encode(payload)

        let (data, response) =
            try await URLSession.shared.data(
                for: request
            )

        guard let httpResponse =
            response as? HTTPURLResponse
        else {
            throw OpenAIServiceError.invalidResponse
        }

        guard
            (200...299).contains(
                httpResponse.statusCode
            )
        else {
            throw parseAPIError(
                data: data,
                statusCode: httpResponse.statusCode
            )
        }

        let decoded =
            try JSONDecoder().decode(
                ChatResponse.self,
                from: data
            )

        guard
            let content =
                decoded
                    .choices
                    .first?
                    .message
                    .content?
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
            !content.isEmpty
        else {
            throw OpenAIServiceError.emptyResponse
        }

        return content
    }

    private func parseAPIError(
        data: Data,
        statusCode: Int
    ) -> Error {

        if let decoded =
            try? JSONDecoder().decode(
                APIErrorResponse.self,
                from: data
            ) {

            return OpenAIServiceError.apiError(
                statusCode: statusCode,
                message: decoded.error.message
            )
        }

        return OpenAIServiceError.httpError(
            statusCode
        )
    }
}

private struct ChatRequest: Encodable {
    let model: String
    let messages: [OpenAIChatMessage]
}

private struct ChatResponse: Decodable {
    let choices: [Choice]
}

private struct Choice: Decodable {
    let message: AssistantMessage
}

private struct AssistantMessage: Decodable {
    let content: String?
}

private struct APIErrorResponse: Decodable {
    let error: APIErrorBody
}

private struct APIErrorBody: Decodable {
    let message: String
}

enum OpenAIServiceError: LocalizedError {

    case invalidResponse
    case emptyResponse
    case httpError(Int)
    case apiError(
        statusCode: Int,
        message: String
    )

    var errorDescription: String? {

        switch self {

        case .invalidResponse:
            return "API вернул некорректный ответ."

        case .emptyResponse:
            return "API вернул пустой ответ."

        case .httpError(let statusCode):
            return "Ошибка API. HTTP \(statusCode)."

        case .apiError(let statusCode, let message):
            return "API \(statusCode): \(message)"
        }
    }
}
