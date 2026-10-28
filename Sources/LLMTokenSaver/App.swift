import SwiftUI

@main
struct LLMTokenSaverApp: App {
    // Инициализируем наш оркестратор чатов
    @StateObject private var engine = ChatEngine()
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                // Боковая панель со списком веток диалогов
                List(engine.threads, selection: $engine.currentThreadId) { thread in
                    NavigationLink(thread.title, value: thread.id)
                }
                .navigationTitle("Ветки диалогов")
                .toolbar {
                    Button(action: { engine.startNewThread() }) {
                        Label("Новый чат", systemImage: "square.and.pencil")
                    }
                }
            } detail: {
                // Основное окно чата с двухоконным выводом перевода
                if engine.currentThreadId != nil {
                    MainChatInterfaceView(engine: engine)
                } else {
                    ContentUnavailableView(
                        "Выберите чат",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Создайте новую ветку диалога или выберите существующую для экономии токенов.")
                    )
                }
            }
            .onAppear {
                // Инициализируем стартовую ветку при запуске
                if engine.threads.isEmpty {
                    engine.startNewThread()
                }
            }
        }
    }
}

// MARK: - Графический UI интерфейса чата (Окна ответов и перевода)
struct MainChatInterfaceView: View {
    @ObservedObject var engine: ChatEngine
    @State private var inputText: String = ""
    @State private var isPromptTranslated: Bool = false
    @State private var isSending: Bool = false
    
    var body: some View {
        VStack {
            if let threadIndex = engine.threads.firstIndex(where: { $0.id == engine.currentThreadId }) {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(engine.threads[threadIndex].messages) { message in
                            HStack {
                                if message.isUser { Spacer() }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    if message.isUser {
                                        Text(message.displayText)
                                            .padding()
                                            .background(Color.blue.opacity(0.15))
                                            .cornerRadius(12)
                                    } else {
                                        // Двухоконный сплит-вывод для ответа нейросети
                                        VStack(alignment: .leading, spacing: 10) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Локальный перевод (RU)")
                                                    .font(.caption).bold().foregroundColor(.secondary)
                                                Text(message.displayText)
                                                    .font(.body)
                                            }
                                            Divider()
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Оригинал ответа LLM (EN)")
                                                    .font(.caption).bold().foregroundColor(.secondary)
                                                Text(message.englishContextText)
                                                    .font(.body).italic()
                                            }
                                        }
                                        .padding()
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(12)
                                    }
                                }
                                if !message.isUser { Spacer() }
                            }
                        }
                    }
                    .padding()
                }
            }
            
            // Зона ввода и умная кнопка отправки
            VStack(spacing: 10) {
                TextField(isPromptTranslated ? "Проверьте английский текст перед отправкой..." : "Введите промпт на родном языке...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .disabled(isSending)
                
                Button(action: {
                    Task {
                        if !isPromptTranslated {
                            // Этап 1: Переводим текст на английский на проверку пользователю
                            let payload = MarkdownParser.prepareForTranslation(inputText)
                            let translated = try? await engine.onDeviceTranslator(payload.textToTranslate, "ru", "en")
                            inputText = MarkdownParser.restoreCodeBlocks(in: translated ?? inputText, codeBlocks: payload.codeBlocks)
                            isPromptTranslated = true
                        } else {
                            // Этап 2: Отправляем готовый проверенный текст в LLM
                            isSending = true
                            let promptToSend = inputText
                            inputText = ""
                            isPromptTranslated = false
                            await engine.sendMessage(promptToSend)
                            isSending = false
                        }
                    }
                }) {
                    HStack {
                        if isSending { ProgressView().padding(.trailing, 5) }
                        Text(isSending ? "Секунду..." : (isPromptTranslated ? "Отправить промпт" : "Перевести на английский для отправки"))
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isSending ? Color.gray : (isPromptTranslated ? Color.green : Color.blue))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .disabled(inputText.isEmpty || isSending)
            }
            .padding(.bottom)
        }
        .navigationTitle(engine.threads.first(where: { $0.id == engine.currentThreadId })?.title ?? "Чат")
    }
}
