import Foundation

struct TranslationPayload {

    let textToTranslate: String
    let codeBlocks: [String]
}

enum MarkdownParser {

    static func prepareForTranslation(
        _ text: String
    ) -> TranslationPayload {

        guard !text.isEmpty else {
            return TranslationPayload(
                textToTranslate: text,
                codeBlocks: []
            )
        }

        let pattern = #"```[\s\S]*?```"#

        guard let regex = try? NSRegularExpression(
            pattern: pattern
        ) else {
            return TranslationPayload(
                textToTranslate: text,
                codeBlocks: []
            )
        }

        let fullRange = NSRange(
            text.startIndex..<text.endIndex,
            in: text
        )

        let matches = regex.matches(
            in: text,
            range: fullRange
        )

        guard !matches.isEmpty else {
            return TranslationPayload(
                textToTranslate: text,
                codeBlocks: []
            )
        }

        var codeBlocks: [String] = []

        for match in matches {

            guard let range = Range(
                match.range,
                in: text
            ) else {
                continue
            }

            codeBlocks.append(
                String(text[range])
            )
        }

        var protectedText = text

        for index in matches.indices.reversed() {

            let match = matches[index]

            guard let range = Range(
                match.range,
                in: protectedText
            ) else {
                continue
            }

            let placeholder =
                "\n[[LLM_TOKEN_SAVER_CODE_\(index)]]\n"

            protectedText.replaceSubrange(
                range,
                with: placeholder
            )
        }

        return TranslationPayload(
            textToTranslate: protectedText,
            codeBlocks: codeBlocks
        )
    }

    static func restoreCodeBlocks(
        in translatedText: String,
        codeBlocks: [String]
    ) -> String {

        guard !codeBlocks.isEmpty else {
            return translatedText
        }

        var result = translatedText

        for (
            index,
            codeBlock
        ) in codeBlocks.enumerated() {

            let placeholder =
                "[[LLM_TOKEN_SAVER_CODE_\(index)]]"

            result = result.replacingOccurrences(
                of: placeholder,
                with: codeBlock
            )
        }

        return result
    }
}
