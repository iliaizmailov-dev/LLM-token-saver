import Foundation

struct MessageModel: Identifiable, Codable, Hashable {

    let id: UUID
    let isUser: Bool

    /// Текст на родном языке пользователя.
    let displayText: String

    /// Английская версия, используемая для контекста LLM.
    let englishContextText: String

    init(
        id: UUID = UUID(),
        isUser: Bool,
        displayText: String,
        englishContextText: String
    ) {
        self.id = id
        self.isUser = isUser
        self.displayText = displayText
        self.englishContextText = englishContextText
    }
}

struct ChatThread: Identifiable, Codable, Hashable {

    let id: UUID
    var title: String
    var messages: [MessageModel]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String = "Новый чат",
        messages: [MessageModel] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
    }
}
