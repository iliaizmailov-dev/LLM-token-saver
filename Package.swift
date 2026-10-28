// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LLMTokenSaver",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        // Меняем тип продукта на исполняемое приложение (executable)
        .executable(name: "LLMTokenSaver", targets: ["LLMTokenSaver"])
    ],
    dependencies: [
        .package(url: "https://github.com", from: "0.2.7")
    ],
    targets: [
        // Указываем тип таргета как исполняемый (executableTarget)
        .executableTarget(
            name: "LLMTokenSaver",
            dependencies: ["OpenAI"]
        )
    ]
)
