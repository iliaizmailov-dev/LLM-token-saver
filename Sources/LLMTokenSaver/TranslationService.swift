import Foundation
import Translation

enum TranslationDirection {
    case toEnglish
    case fromEnglish
}

struct TranslationRequest: Identifiable {

    let id = UUID()

    let text: String
    let direction: TranslationDirection
}

enum TranslationServiceError:
    LocalizedError {

    case emptyText
    case failed

    var errorDescription: String? {

        switch self {

        case .emptyText:
            return
                "Нет текста для перевода."

        case .failed:
            return
                "Не удалось выполнить перевод."
        }
    }
}

@MainActor
final class TranslationService:
    ObservableObject {

    @Published var pendingRequest:
        TranslationRequest?

    private var continuation:
        CheckedContinuation<String, Error>?

    func requestTranslation(
        text: String,
        direction: TranslationDirection
    ) async throws -> String {

        let cleanText =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanText.isEmpty else {
            throw TranslationServiceError.emptyText
        }

        return try await withCheckedThrowingContinuation {
            continuation in

            if let previous =
                self.continuation {
                previous.resume(
                    throwing:
                        CancellationError()
                )
            }

            self.continuation = continuation

            self.pendingRequest =
                TranslationRequest(
                    text: cleanText,
                    direction: direction
                )
        }
    }

    func complete(
        with translatedText: String
    ) {

        continuation?.resume(
            returning: translatedText
        )

        continuation = nil
        pendingRequest = nil
    }

    func fail(
        with error: Error
    ) {

        continuation?.resume(
            throwing: error
        )

        continuation = nil
        pendingRequest = nil
    }
}
