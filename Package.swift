// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LLMTokenSaver",
    platforms: [
        .iOS(.v18) // Конфигурация под современную iOS
    ],
    products: [
        .library(name: "LLMTokenSaver", targets: ["LLMTokenSaver"]),
    ],
    dependencies: [
        // Подключаем официальную библиотеку MacPaw OpenAI
        .package(url: "https://github.com", from: "0.2.7")
    ],
    targets: [
        .target(
            name: "LLMTokenSaver",
            dependencies: ["OpenAI"]
        )
    ]
)
