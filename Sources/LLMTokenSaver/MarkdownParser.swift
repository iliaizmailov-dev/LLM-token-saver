import Foundation

struct TranslationPayload {
    let textToTranslate: String
    let codeBlocks: [String]
}

class MarkdownParser {
    // Вырезает блоки кода и возвращает текст для перевода + массив оригинального кода
    static func prepareForTranslation(_ text: String) -> TranslationPayload {
        // Используем #""# синтаксис для безопасного написания регулярных выражений без лишних слешей
        let pattern = #"```[\s\(\S\)]*?```"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return TranslationPayload(textToTranslate: text, codeBlocks: [])
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        var textToTranslate = text
        var codeBlocks: [String] = []
        
        // Обходим совпадения с конца, чтобы индексы строк при замене не плыли
        for match in matches.reversed() {
            let block = nsString.substring(with: match.range)
            codeBlocks.insert(block, at: 0)
            
            let index = codeBlocks.count - 1
            let placeholder = " [[BLOCK_\(index)]] "
            if let range = Range(match.range, in: textToTranslate) {
                textToTranslate.replaceSubrange(range, with: placeholder)
            }
        }
        
        return TranslationPayload(textToTranslate: textToTranslate, codeBlocks: codeBlocks)
    }
    
    // Возвращает оригинальный код на место токенов-заглушек после перевода
    static func restoreCodeBlocks(in translatedText: String, codeBlocks: [String]) -> String {
        var result = translatedText
        for (index, block) in codeBlocks.enumerated() {
            let placeholder = "[[BLOCK_\(index)]]"
            result = result.replacingOccurrences(of: " " + placeholder + " ", with: block)
            result = result.replacingOccurrences(of: placeholder, with: block)
        }
        return result
    }
}
