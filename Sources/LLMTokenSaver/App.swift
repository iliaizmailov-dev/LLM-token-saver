import SwiftUI

@main
struct LLMTokenSaverApp: App {

    @StateObject private var engine = ChatEngine()

    var body: some Scene {
        WindowGroup {
            ContentView(engine: engine)
        }
    }
}
