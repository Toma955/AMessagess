import Foundation

final class NotesManager: ObservableObject {
    @Published var notes: [Note] = []
    @Published var selectedNoteID: UUID?

    var selectedNote: Note? {
        notes.first(where: { $0.id == selectedNoteID })
    }

    func createNote() {
        let note = Note()
        notes.insert(note, at: 0)
        selectedNoteID = note.id
    }

    func delete(note: Note) {
        if let idx = notes.firstIndex(of: note) {
            notes.remove(at: idx)
            if selectedNoteID == note.id {
                selectedNoteID = notes.first?.id
            }
        }
    }

    func updateCurrent(title: String, body: String) {
        guard let id = selectedNoteID,
              let idx = notes.firstIndex(where: { $0.id == id }) else { return }

        notes[idx].title = title
        notes[idx].body = body
        notes[idx].updatedAt = Date()
    }
}
