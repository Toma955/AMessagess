import SwiftUI

@main
struct AMessagesApp: App {
    @StateObject private var conversationManager = ConversationManager()
    @StateObject private var session = SessionManager()
    @StateObject private var windowManager = WindowManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if session.isUnlocked {
                    AppView()
                } else {
                    PreloaderView()   // tvoj preloader
                }
            }
            .environmentObject(conversationManager)
            .environmentObject(session)
            .environmentObject(windowManager)
        }
    }
}
