import SwiftUI
import Translation

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(configuration.isOn ? .accent : .secondary)
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}

struct ContentView: View {

    @ObservedObject var engine: ChatEngine

    @StateObject private var translationService = TranslationService()

    @State private var originalPrompt = ""
    @State private var englishPrompt = ""

    @State private var nativeResponse = ""
    @State private var englishResponse = ""

    @State private var openAIApiKey = ""
    @State private var microsoft365APIKey = ""
    @State private var microsoft365Endpoint = ""
    @State private var selectedProvider: LLMProvider = .openAI
    @State private var selectedModel = "gpt-4o-mini"

    @State private var isSettingsPresented = false
    @State private var isTranslating = false
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var translationConfiguration: TranslationSession.Configuration?
    @State private var activeTranslationDirection: TranslationDirection?

    private var trimmedOriginalPrompt: String {
        originalPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedEnglishPrompt: String {
        englishPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    promptSection
                    actionButton

                    if isTranslating || isSending {
                        progressSection
                    }

                    if !nativeResponse.isEmpty || !englishResponse.isEmpty {
                        responseSection
                    }
                }
                .padding()
            }
            .navigationTitle("LLM Token Saver")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Настройки")
                }
            }
            .sheet(isPresented: $isSettingsPresented) {
                settingsView
            }
            .alert(
                "Ошибка",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { newValue in
                        if !newValue { errorMessage = nil }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "Неизвестная ошибка")
            }
            .task {
                configureEngine()
                loadSavedAPIKeys()
            }
            .translationTask(translationConfiguration) { session in
                await performSystemTranslation(using: session)
            }
        }
    }

    private var promptSection: some View {
        VStack(spacing: 16) {
            textEditorCard(
                title: "Оригинальный промпт",
                subtitle: "Введите текст на родном языке",
                text: $originalPrompt,
                emptyText: "Например: объясни этот Swift-код..."
            )

            textEditorCard(
                title: "English",
                subtitle: "Английская версия для LLM",
                text: $englishPrompt,
                emptyText: "Перевод появится здесь..."
            )
        }
    }

    private var actionButton: some View {
        Button {
            performPrimaryAction()
        } label: {
            HStack(spacing: 10) {
                if isTranslating || isSending {
                    ProgressView().tint(.white)
                }
                Text(buttonTitle).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(buttonColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(buttonDisabled)
    }

    private var buttonTitle: String {
        if isTranslating { return "Перевод..." }
        if isSending { return "Отправка..." }
        if englishPrompt.isEmpty { return "Перевести промпт" }
        return "Отправить промпт"
    }

    private var buttonColor: Color {
        if buttonDisabled { return .gray }
        if englishPrompt.isEmpty { return .blue }
        return .green
    }

    private var buttonDisabled: Bool {
        if isTranslating || isSending { return true }
        if englishPrompt.isEmpty { return trimmedOriginalPrompt.isEmpty }
        return trimmedEnglishPrompt.isEmpty
    }

    private var responseSection: some View {
        VStack(spacing: 16) {
            Divider()

            HStack {
                Text("Ответ")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }

            if !nativeResponse.isEmpty {
                readOnlyCard(title: "Перевод", text: nativeResponse)
            }

            if !englishResponse.isEmpty {
                readOnlyCard(title: "English", text: englishResponse)
            }

            Button {
                startNewPrompt()
            } label: {
                Label("Новый промпт", systemImage: "plus.bubble")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
        }
    }

    private var progressSection: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text(isSending ? "Ожидание ответа LLM..." : "Локальный перевод...")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var settingsView: some View {
        NavigationStack {
            Form {
                Section("Провайдер") {
                    providerToggle(provider: .openAI, isOn: selectedProvider == .openAI)
                    providerToggle(provider: .microsoft365Copilot, isOn: selectedProvider == .microsoft365Copilot)
                }

                Section("OpenAI") {
                    SecureField("API Key", text: $openAIApiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Model", text: $selectedModel)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Microsoft 365 Copilot") {
                    SecureField("API Key", text: $microsoft365APIKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Endpoint", text: $microsoft365Endpoint)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .placeholder(when: microsoft365Endpoint.isEmpty) {
                            Text("https://graph.microsoft.com")
                        }
                }

                Section {
                    Text("API Key хранится локально в Keychain этого устройства.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        saveAPIKeys()
                        isSettingsPresented = false
                    }
                }
            }
        }
    }

    private func providerToggle(provider: LLMProvider, isOn: Bool) -> some View {
        Toggle(
            isOn: Binding(
                get: { isOn },
                set: { newValue in
                    if newValue {
                        selectedProvider = provider
                    } else if selectedProvider == provider {
                        selectedProvider = .openAI
                    }
                }
            )
        ) {
            Text(provider.title)
        }
        .toggleStyle(CheckboxToggleStyle())
    }

    private func textEditorCard(
        title: String,
        subtitle: String,
        text: Binding<String>,
        emptyText: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)

            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(emptyText)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: text)
                    .frame(minHeight: 130)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .padding(8)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func readOnlyCard(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding()
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func configureEngine() {
        engine.translationHandler = { text, direction in
            let translationTask = Task {
                @MainActor in
                try await translationService.requestTranslation(
                    text: text,
                    direction: direction
                )
            }

            await Task.yield()

            await MainActor.run {
                requestTranslationSession(for: direction)
            }

            return try await translationTask.value
        }
    }

    private func performPrimaryAction() {
        guard !isTranslating, !isSending else { return }

        if englishPrompt.isEmpty {
            translatePrompt()
        } else {
            sendPrompt()
        }
    }

    private func translatePrompt() {
        guard !trimmedOriginalPrompt.isEmpty else { return }

        isTranslating = true
        errorMessage = nil

        Task {
            do {
                let translated = try await engine.translatePrompt(originalPrompt)
                await MainActor.run {
                    englishPrompt = translated
                    isTranslating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isTranslating = false
                }
            }
        }
    }

    private func sendPrompt() {
        guard !trimmedEnglishPrompt.isEmpty else { return }

        let activeKey: String
        switch selectedProvider {
        case .openAI:
            activeKey = openAIApiKey
        case .microsoft365Copilot:
            activeKey = microsoft365APIKey
        }

        let cleanAPIKey = activeKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanAPIKey.isEmpty else {
            errorMessage = "Сначала укажите \(selectedProvider.title) API Key в настройках."
            isSettingsPresented = true
            return
        }

        let cleanModel = selectedModel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanModel.isEmpty else {
            errorMessage = "Укажите модель \(selectedProvider.title) в настройках."
            isSettingsPresented = true
            return
        }

        let endpointOverride: String?
        switch selectedProvider {
        case .openAI:
            endpointOverride = nil
        case .microsoft365Copilot:
            let trimmed = microsoft365Endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
            endpointOverride = trimmed.isEmpty ? selectedProvider.defaultEndpointURL.absoluteString : trimmed
        }

        isSending = true
        errorMessage = nil

        Task {
            do {
                let response = try await engine.sendPrompt(
                    originalPrompt: originalPrompt,
                    englishPrompt: englishPrompt,
                    provider: selectedProvider,
                    apiKey: cleanAPIKey,
                    model: cleanModel,
                    endpointOverride: endpointOverride
                )

                await MainActor.run {
                    englishResponse = response.english
                    nativeResponse = response.translated
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSending = false
                }
            }
        }
    }

    private func performSystemTranslation(using session: TranslationSession) async {
        await Task { @MainActor in
            guard let request = translationService.pendingRequest else { return }

            do {
                let response = try await session.translate(request.text)
                translationService.complete(with: response.targetText)
            } catch {
                translationService.fail(with: error)
            }
        }.value
    }

    @MainActor
    private func requestTranslationSession(for direction: TranslationDirection) {
        if activeTranslationDirection == direction, translationConfiguration != nil {
            translationConfiguration?.invalidate()
            return
        }

        activeTranslationDirection = direction

        let english = Locale.Language(identifier: "en")

        switch direction {
        case .toEnglish:
            translationConfiguration = TranslationSession.Configuration(
                source: nil,
                target: english
            )
        case .fromEnglish:
            translationConfiguration = TranslationSession.Configuration(
                source: english,
                target: nil
            )
        }
    }

    private func loadSavedAPIKeys() {
        do {
            if let savedOpenAIKey = try KeychainService.loadAPIKey(for: .openAI) {
                openAIApiKey = savedOpenAIKey
            }

            if let savedMicrosoftKey = try KeychainService.loadAPIKey(for: .microsoft365Copilot) {
                microsoft365APIKey = savedMicrosoftKey
            }

            if let savedEndpoint = try? loadMicrosoftEndpoint() {
                microsoft365Endpoint = savedEndpoint
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveAPIKeys() {
        let cleanOpenAIKey = openAIApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanMicrosoftKey = microsoft365APIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEndpoint = microsoft365Endpoint.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            if cleanOpenAIKey.isEmpty {
                try KeychainService.deleteAPIKey(for: .openAI)
            } else {
                try KeychainService.saveAPIKey(cleanOpenAIKey, for: .openAI)
            }

            if cleanMicrosoftKey.isEmpty {
                try KeychainService.deleteAPIKey(for: .microsoft365Copilot)
            } else {
                try KeychainService.saveAPIKey(cleanMicrosoftKey, for: .microsoft365Copilot)
            }

            if cleanEndpoint.isEmpty {
                UserDefaults.standard.removeObject(forKey: "microsoft365Endpoint")
            } else {
                UserDefaults.standard.set(cleanEndpoint, forKey: "microsoft365Endpoint")
            }

            openAIApiKey = cleanOpenAIKey
            microsoft365APIKey = cleanMicrosoftKey
            microsoft365Endpoint = cleanEndpoint
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadMicrosoftEndpoint() throws -> String {
        if let value = UserDefaults.standard.string(forKey: "microsoft365Endpoint") {
            return value
        }
        return ""
    }

    private func startNewPrompt() {
        originalPrompt = ""
        englishPrompt = ""
        nativeResponse = ""
        englishResponse = ""
        errorMessage = nil
        isTranslating = false
        isSending = false
    }
}
