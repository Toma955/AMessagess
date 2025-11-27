import Foundation

final class LogStorage {
    static let shared = LogStorage()
    private init() {}

    private func url(for conversationId: String) -> URL? {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return docs.appendingPathComponent("log_\(conversationId).json")
    }

    func loadLog(for conversationId: String) -> [LogEntry] {
        guard let url = url(for: conversationId),
              let data = try? Data(contentsOf: url) else {
            return []
        }

        let decoder = JSONDecoder()
        return (try? decoder.decode([LogEntry].self, from: data)) ?? []
    }

    func saveLog(_ entries: [LogEntry], for conversationId: String) {
        guard let url = url(for: conversationId) else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: url)
    }

    func append(_ entry: LogEntry, to conversationId: String) {
        var current = loadLog(for: conversationId)
        current.append(entry)
        saveLog(current, for: conversationId)
    }
}
