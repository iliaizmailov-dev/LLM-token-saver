// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LLMTokenSaver",

    platforms: [
        .iOS(.v18)
    ],

    products: [
        .executable(
            name: "LLMTokenSaver",
            targets: ["LLMTokenSaver"]
        )
    ],

    dependencies: [],

    targets: [
        .executableTarget(
            name: "LLMTokenSaver",
            dependencies: [],
            path: "Sources/LLMTokenSaver"
        )
    ]
)
