//
//  LogEntry.swift
//  AMessages
//
//  Created by Toma Babić on 25.11.2025..
//

import Foundation

struct LogEntry: Codable, Identifiable {
    let id: UUID
    let conversationId: String
    let rawData: Data   // ovdje će kasnije biti nonce+ciphertext+tag itd.
    let createdAt: Date

    static func from(message: Message) -> LogEntry {
        LogEntry(
            id: UUID(),
            conversationId: message.conversationId,
            rawData: Data(message.text.utf8), // za sada “fake”
            createdAt: Date()
        )
    }
}
