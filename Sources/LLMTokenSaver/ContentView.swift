import SwiftUI

struct ContentView: View {

    @ObservedObject var engine: ChatEngine

    @State private var originalPrompt = ""
    @State private var englishPrompt = ""

    @State private var nativeResponse = ""
    @State private var englishResponse = ""

    @State private var apiKey = ""
    @State private var selectedModel = "gpt-4o-mini"

    @State private var isSettingsPresented = false
    @State private var isTranslating = false
    @State private var isSending = false

    @State private var errorMessage: String?

    private var trimmedOriginalPrompt: String {
        originalPrompt.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var trimmedEnglishPrompt: String {
        englishPrompt.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
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

                    if !nativeResponse.isEmpty ||
                        !englishResponse.isEmpty {
                        responseSection
                    }
                }
                .padding()
            }
            .navigationTitle("LLM Token Saver")
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
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
                    get: {
                        errorMessage != nil
                    },
                    set: { newValue in
                        if !newValue {
                            errorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(
                    errorMessage ??
                    "Неизвестная ошибка"
                )
            }
        }
    }

    // MARK: - Prompt

    private var promptSection: some View {
        VStack(spacing: 16) {

            textEditorCard(
                title: "Оригинальный промпт",
                subtitle:
                    "Введите текст на родном языке",
                text: $originalPrompt,
                emptyText:
                    "Например: объясни этот Swift-код..."
            )

            textEditorCard(
                title: "English",
                subtitle:
                    "Английская версия для LLM",
                text: $englishPrompt,
                emptyText:
                    "Перевод появится здесь..."
            )
        }
    }

    // MARK: - Main action

    private var actionButton: some View {
        Button {
            performPrimaryAction()
        } label: {
            HStack(spacing: 10) {

                if isTranslating || isSending {
                    ProgressView()
                        .tint(.white)
                }

                Text(buttonTitle)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(buttonColor)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )
        }
        .disabled(buttonDisabled)
    }

    private var buttonTitle: String {
        if isTranslating {
            return "Перевод..."
        }

        if isSending {
            return "Отправка..."
        }

        if englishPrompt.isEmpty {
            return "Перевести промпт"
        }

        return "Отправить промпт"
    }

    private var buttonColor: Color {
        if buttonDisabled {
            return .gray
        }

        if englishPrompt.isEmpty {
            return .blue
        }

        return .green
    }

    private var buttonDisabled: Bool {
        if isTranslating || isSending {
            return true
        }

        if englishPrompt.isEmpty {
            return trimmedOriginalPrompt.isEmpty
        }

        return trimmedEnglishPrompt.isEmpty
    }

    // MARK: - Response

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
                readOnlyCard(
                    title: "Перевод",
                    text: nativeResponse
                )
            }

            if !englishResponse.isEmpty {
                readOnlyCard(
                    title: "English",
                    text: englishResponse
                )
            }

            Button {
                startNewPrompt()
            } label: {
                Label(
                    "Новый промпт",
                    systemImage: "plus.bubble"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        HStack(spacing: 10) {
            ProgressView()

            Text(
                isSending
                    ? "Ожидание ответа LLM..."
                    : "Перевод на английский..."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Settings

    private var settingsView: some View {
        NavigationStack {
            Form {

                Section("OpenAI") {

                    SecureField(
                        "API Key",
                        text: $apiKey
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    TextField(
                        "Model",
                        text: $selectedModel
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                }

                Section {
                    Text(
                        "API-ключ будет использоваться " +
                        "для подключения к OpenAI. " +
                        "После добавления KeychainService " +
                        "ключ будет храниться локально."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    Button("Готово") {
                        isSettingsPresented = false
                    }
                }
            }
        }
    }

    // MARK: - Reusable UI

    private func textEditorCard(
        title: String,
        subtitle: String,
        text: Binding<String>,
        emptyText: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

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
            .background(
                Color.secondary.opacity(0.08)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )
        }
    }

    private func readOnlyCard(
        title: String,
        text: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text(title)
                .font(.headline)

            Text(text)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .textSelection(.enabled)
                .padding()
                .background(
                    Color.secondary.opacity(0.08)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                )
        }
    }

    // MARK: - Actions

    private func performPrimaryAction() {

        guard !isTranslating,
              !isSending
        else {
            return
        }

        if englishPrompt.isEmpty {
            translatePrompt()
        } else {
            sendPrompt()
        }
    }

    private func translatePrompt() {

        guard !trimmedOriginalPrompt.isEmpty else {
            return
        }

        isTranslating = true
        errorMessage = nil

        Task {
            do {
                let translated =
                    try await engine.translatePrompt(
                        originalPrompt
                    )

                await MainActor.run {
                    englishPrompt = translated
                    isTranslating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage =
                        error.localizedDescription
                    isTranslating = false
                }
            }
        }
    }

    private func sendPrompt() {

        guard !trimmedEnglishPrompt.isEmpty else {
            return
        }

        guard !apiKey
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
        else {
            errorMessage =
                "Сначала укажите OpenAI API Key " +
                "в настройках."
            isSettingsPresented = true
            return
        }

        isSending = true
        errorMessage = nil

        Task {
            do {
                let response =
                    try await engine.sendPrompt(
                        originalPrompt:
                            originalPrompt,
                        englishPrompt:
                            englishPrompt,
                        apiKey:
                            apiKey,
                        model:
                            selectedModel
                    )

                await MainActor.run {
                    englishResponse =
                        response.english

                    nativeResponse =
                        response.translated

                    isSending = false
                }
            } catch {
                await MainActor.run {
                    errorMessage =
                        error.localizedDescription
                    isSending = false
                }
            }
        }
    }

    private func startNewPrompt() {
        originalPrompt = ""
        englishPrompt = ""
        nativeResponse = ""
        englishResponse = ""
        errorMessage = nil
    }
}
