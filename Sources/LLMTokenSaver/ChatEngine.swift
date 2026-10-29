import Foundation

@MainActor
final class ChatEngine: ObservableObject {

    @Published private(set) var threads: [ChatThread] = []
    @Published var currentThreadId: UUID?

    private let openAIService: OpenAIService

    var translationHandler: ((String, TranslationDirection) async throws -> String)?

    init(
        openAIService: OpenAIService = OpenAIService()
    ) {
        self.openAIService = openAIService
    }

    func startNewThread() {
        let thread = ChatThread(
            id: UUID(),
            title: "Новый чат",
            messages: [],
            createdAt: Date()
        )

        threads.append(thread)
        currentThreadId = thread.id
    }

    func translatePrompt(
        _ originalPrompt: String
    ) async throws -> String {

        let trimmed = originalPrompt.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else {
            throw ChatEngineError.emptyPrompt
        }

        guard let translationHandler else {
            throw ChatEngineError.translationUnavailable
        }

        let payload = MarkdownParser.prepareForTranslation(
            trimmed
        )

        let translated = try await translationHandler(
            payload.textToTranslate,
            .toEnglish
        )

        return MarkdownParser.restoreCodeBlocks(
            in: translated,
            codeBlocks: payload.codeBlocks
        )
    }

    func sendPrompt(
        originalPrompt: String,
        englishPrompt: String,
        apiKey: String,
        model: String
    ) async throws -> PromptResponse {

        let cleanEnglishPrompt =
            englishPrompt.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanEnglishPrompt.isEmpty else {
            throw ChatEngineError.emptyPrompt
        }

        let cleanAPIKey =
            apiKey.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanAPIKey.isEmpty else {
            throw ChatEngineError.missingAPIKey
        }

        let cleanModel =
            model.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanModel.isEmpty else {
            throw ChatEngineError.missingModel
        }

        ensureThreadExists()

        guard let threadIndex = threads.firstIndex(
            where: {
                $0.id == currentThreadId
            }
        ) else {
            throw ChatEngineError.threadUnavailable
        }

        let userMessage = MessageModel(
            id: UUID(),
            isUser: true,
            displayText: originalPrompt,
            englishContextText: cleanEnglishPrompt
        )

        threads[threadIndex]
            .messages
            .append(userMessage)

        if threads[threadIndex].title == "Новый чат" {
            threads[threadIndex].title =
                makeTitle(from: originalPrompt)
        }

        let englishHistory =
            threads[threadIndex].messages.map {
                OpenAIChatMessage(
                    role: $0.isUser
                        ? "user"
                        : "assistant",
                    content: $0.englishContextText
                )
            }

        do {
            let englishResponse =
                try await openAIService.sendChat(
                    apiKey: cleanAPIKey,
                    model: cleanModel,
                    messages: englishHistory
                )

            let translatedResponse =
                try await translateResponse(
                    englishResponse
                )

            let assistantMessage = MessageModel(
                id: UUID(),
                isUser: false,
                displayText: translatedResponse,
                englishContextText: englishResponse
            )

            threads[threadIndex]
                .messages
                .append(assistantMessage)

            return PromptResponse(
                english: englishResponse,
                translated: translatedResponse
            )

        } catch {
            throw error
        }
    }

    private func translateResponse(
        _ englishResponse: String
    ) async throws -> String {

        guard let translationHandler else {
            throw ChatEngineError.translationUnavailable
        }

        let payload =
            MarkdownParser.prepareForTranslation(
                englishResponse
            )

        let translated =
            try await translationHandler(
                payload.textToTranslate,
                .fromEnglish
            )

        return MarkdownParser.restoreCodeBlocks(
            in: translated,
            codeBlocks: payload.codeBlocks
        )
    }

    private func ensureThreadExists() {
        guard currentThreadId == nil else {
            return
        }

        startNewThread()
    }

    private func makeTitle(
        from prompt: String
    ) -> String {

        let trimmed =
            prompt.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if trimmed.count <= 28 {
            return trimmed
        }

        return String(trimmed.prefix(28)) + "…"
    }
}

struct PromptResponse {
    let english: String
    let translated: String
}

enum ChatEngineError: LocalizedError {

    case emptyPrompt
    case missingAPIKey
    case missingModel
    case translationUnavailable
    case threadUnavailable

    var errorDescription: String? {
        switch self {

        case .emptyPrompt:
            return "Промпт пуст."

        case .missingAPIKey:
            return "Не указан OpenAI API Key."

        case .missingModel:
            return "Не указана модель."

        case .translationUnavailable:
            return
                "Сервис перевода ещё не готов."

        case .threadUnavailable:
            return
                "Не удалось создать ветку диалога."
        }
    }
}
