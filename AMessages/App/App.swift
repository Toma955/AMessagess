// App/App.swift
import Foundation

final class AppController: ObservableObject {
    @Published var selectedConversation: Conversation?

    func open(conversation: Conversation) {
        selectedConversation = conversation
    }

    func closeConversation() {
        selectedConversation = nil
    }
}
