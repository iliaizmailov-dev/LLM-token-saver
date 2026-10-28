// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LLMTokenSaver",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .executable(name: "LLMTokenSaver", targets: ["LLMTokenSaver"])
    ],
    dependencies: [
        // Заменяем версию на жесткую привязку к ветке, чтобы сбросить забагованный кэш URL
        .package(url: "https://github.com", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "LLMTokenSaver",
            dependencies: ["OpenAI"]
        )
    ]
)
