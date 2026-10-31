import SwiftUI
import Translation

struct CheckboxToggleStyle: ToggleStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {

        Button {
            configuration.isOn.toggle()
        } label: {

            HStack(spacing: 10) {

                Image(
                    systemName:
                        configuration.isOn
                        ? "checkmark.square.fill"
                        : "square"
                )
                .foregroundStyle(
                    configuration.isOn
                    ? Color.accentColor
                    : Color.secondary
                )

                configuration.label

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ContentView: View {

    @ObservedObject var engine: ChatEngine

    @StateObject private var translationService =
        TranslationService()

    @State private var originalPrompt = ""
    @State private var englishPrompt = ""

    @State private var nativeResponse = ""
    @State private var englishResponse = ""

    @State private var openAIApiKey = ""
    @State private var microsoft365APIKey = ""
    @State private var microsoft365Endpoint = ""

    @State private var selectedProvider:
        LLMProvider = .openAI

    @State private var selectedModel =
        "gpt-4o-mini"

    @State private var isSettingsPresented =
        false

    @State private var isTranslating =
        false

    @State private var isSending =
        false

    @State private var errorMessage:
        String?

    @State private var translationConfiguration:
        TranslationSession.Configuration?

    @State private var activeTranslationDirection:
        TranslationDirection?

    // MARK: - Computed Properties

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

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 20) {

                    promptSection

                    actionButton

                    if isTranslating ||
                        isSending {

                        progressSection
                    }

                    if !nativeResponse.isEmpty ||
                        !englishResponse.isEmpty {

                        responseSection
                    }
                }
                .padding()
            }

            .navigationTitle(
                "LLM Token Saver"
            )

            .toolbar {

                ToolbarItem(
                    placement:
                        .topBarTrailing
                ) {

                    Button {

                        isSettingsPresented =
                            true

                    } label: {

                        Image(
                            systemName:
                                "gearshape"
                        )
                    }
                    .accessibilityLabel(
                        "Настройки"
                    )
                }
            }

            .sheet(
                isPresented:
                    $isSettingsPresented
            ) {

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

                Button(
                    "OK",
                    role: .cancel
                ) {

                    errorMessage = nil
                }

            } message: {

                Text(
                    errorMessage ??
                    "Неизвестная ошибка"
                )
            }

            .task {

                configureEngine()

                loadSavedAPIKeys()
            }

            .translationTask(
                translationConfiguration
            ) { session in

                await performSystemTranslation(
                    using: session
                )
            }
        }
    }

    // MARK: - Prompt Section

    private var promptSection: some View {

        VStack(spacing: 16) {

            textEditorCard(
                title:
                    "Оригинальный промпт",

                subtitle:
                    "Введите текст на родном языке",

                text:
                    $originalPrompt,

                emptyText:
                    "Например: объясни этот Swift-код..."
            )

            textEditorCard(
                title:
                    "English",

                subtitle:
                    "Английская версия для LLM",

                text:
                    $englishPrompt,

                emptyText:
                    "Перевод появится здесь..."
            )
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {

        Button {

            performPrimaryAction()

        } label: {

            HStack(spacing: 10) {

                if isTranslating ||
                    isSending {

                    ProgressView()
                        .tint(.white)
                }

                Text(buttonTitle)
                    .fontWeight(.semibold)
            }

            .frame(
                maxWidth: .infinity
            )

            .padding(
                .vertical,
                14
            )

            .foregroundStyle(
                .white
            )

            .background(
                buttonColor
            )

            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )
        }

        .disabled(
            buttonDisabled
        )
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
            return
