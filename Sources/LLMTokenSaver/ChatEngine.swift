import Foundation
import OpenAI

@MainActor
class ChatEngine: ObservableObject {
    @Published var threads: [ChatThread] = []
    @Published var currentThreadId: UUID?
    
    private var openAIClient: OpenAI?
    
    // Протокол заглушка для локального переводчика на устройстве (Apple/Google)
    var onDeviceTranslator: (String, String, String) async throws -> String = { text, _, _ in text }
    
    func initializeOpenAI(apiKey: String) {
        self.openAIClient = OpenAI(apiToken: apiKey)
    }
    
    func startNewThread() {
        let newThread = ChatThread(id: UUID(), title: "Новый чат", messages: [], createdAt: Date())
        threads.append(newThread)
        currentThreadId = newThread.id
    }
    
    func sendMessage(_ rawUserPrompt: String) async {
        guard let threadIndex = threads.firstIndex(where: { $0.id == currentThreadId }),
              let client = openAIClient else { return }
        
        // 1. Локальный перевод промпта на английский с защитой кода
        let payloadEN = MarkdownParser.prepareForTranslation(rawUserPrompt)
        let translatedTextEN = (try? await onDeviceTranslator(payloadEN.textToTranslate, "ru", "en")) ?? payloadEN.textToTranslate
        let finalUserPromptEN = MarkdownParser.restoreCodeBlocks(in: translatedTextEN, codeBlocks: payloadEN.codeBlocks)
        
        let userMessage = MessageModel(id: UUID(), isUser: true, displayText: rawUserPrompt, englishContextText: finalUserPromptEN)
        threads[threadIndex].messages.append(userMessage)
        
        if threads[threadIndex].title == "Новый чат" {
            threads[threadIndex].title = String(rawUserPrompt.prefix(20)) + "..."
        }
        
        // 2. Формирование истории сообщений строго на английском (Совместимо с OpenAI SDK 0.6.0)
        let openAIMessages = threads[threadIndex].messages.map { msg in
            ChatQuery.ChatCompletionMessageParam(role: msg.isUser ? .user : .assistant, content: msg.englishContextText)!
        }
        
        let query = ChatQuery(messages: openAIMessages, model: "gpt-4o")
        
        do {
            // 3. Сетевой запрос к LLM
            let result = try await client.chats(query: query)
            // Прямо извлекаем опциональную строку ответа, убирая ломающий вызов .string
            guard let aiResponseEN = result.choices.first?.message.content else { return }
            
            // 4. Обратный локальный перевод ответа на русский с защитой кода
            let payloadRU = MarkdownParser.prepareForTranslation(aiResponseEN)
            let translatedTextRU = (try? await onDeviceTranslator(payloadRU.textToTranslate, "en", "ru")) ?? payloadRU.textToTranslate
            let finalAiResponseRU = MarkdownParser.restoreCodeBlocks(in: translatedTextRU, codeBlocks: payloadRU.codeBlocks)
            
            // 5. Запись ответа в историю ветки
            let aiMessage = MessageModel(
                id: UUID(),
                isUser: false,
                displayText: finalAiResponseRU,
                englishContextText: aiResponseEN
            )
            threads[threadIndex].messages.append(aiMessage)
            
        } catch {
            print("OpenAI API Error: \(error)")
        }
    }
}
