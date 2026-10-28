import Foundation

// Одиночная реплика в базе данных приложения
struct MessageModel: Identifiable, Codable {
    let id: UUID
    let isUser: Bool
    let displayText: String       // То, что видит пользователь на экране (RU или EN)
    let englishContextText: String // То, что уходит в LLM для контекста (Строго EN)
}

// Ветка диалога (Чат)
struct ChatThread: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [MessageModel]
    let createdAt: Date
}
