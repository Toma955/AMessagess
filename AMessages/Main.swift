import SwiftUI

@main
struct AMessagesApp: App {
    @StateObject private var conversationManager = ConversationManager()
    @StateObject private var session = SessionManager()
    @StateObject private var windowManager = WindowManager()
    @StateObject private var themeManager = ThemeManager()   // ⬅️ NOVO

    var body: some Scene {
        WindowGroup {
            Group {
                if session.isUnlocked {
                    AppView()
                } else {
                    PreloaderView()
                }
            }
            .environmentObject(conversationManager)
            .environmentObject(session)
            .environmentObject(windowManager)
            .environmentObject(themeManager)                 // ⬅️ NOVO
        }
    }
}
