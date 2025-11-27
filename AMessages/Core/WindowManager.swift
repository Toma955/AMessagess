import SwiftUI

enum WindowKind: Equatable {
    case messages
    case settings
    case history
    case notes
}

struct WindowState: Identifiable, Equatable {
    let id: UUID
    var kind: WindowKind
    var offset: CGSize          // ⬅️ OVDJE se sprema pomak pri dragu
    var isDocked: Bool
    var createdAt: Date

    init(kind: WindowKind,
         offset: CGSize = .zero,
         isDocked: Bool = false,
         createdAt: Date = Date()) {
        self.id = UUID()
        self.kind = kind
        self.offset = offset
        self.isDocked = isDocked
        self.createdAt = createdAt
    }
}

final class WindowManager: ObservableObject {
    @Published var windows: [WindowState] = []
    @Published var pendingHistoryFileURL: URL? = nil

    // aktivni prozori (na sredini)
    var activeWindows: [WindowState] {
        windows.filter { !$0.isDocked }
    }

    // prozori u docku
    var dockedWindows: [WindowState] {
        windows.filter { $0.isDocked }
    }

    // MARK: - Otvaranje

    func open(kind: WindowKind) {
        // Settings smije postojati samo jedan
        if kind == .settings {
            if let idx = windows.firstIndex(where: { $0.kind == .settings }) {
                windows[idx].isDocked = false
                return
            }
        }

        // ostali smiju imati više instanci
        windows.append(WindowState(kind: kind))
        enforceMaxActive()
    }

    func toggleSettings() {
        if let idx = windows.firstIndex(where: { $0.kind == .settings }) {
            windows.remove(at: idx)
        } else {
            open(kind: .settings)
        }
    }

    func closeAll() {
        windows.removeAll()
    }

    // MARK: - Dock / undock

    /// Klik na stavku u docku – samo "undock" (vrati na ekran)
    func undock(id: UUID) {
        guard let idx = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[idx].isDocked = false
        enforceMaxActive()
    }

    /// Drag & drop iz docka u zonu prozora
    /// - ako ima < 3 aktivna → samo ga aktivira
    /// - ako ima >= 3 → najstariji aktivni (koji nije settings) ide u dock, ovaj dolazi na ekran
    func bringDockedToActive(id: UUID) {
        guard let idx = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[idx].isDocked = false

        let actives = activeWindows
        if actives.count > 3 {
            dockOldestNonSettings()
        } else if actives.count == 3 {
            dockOldestNonSettings()
        }
    }

    private func dockOldestNonSettings() {
        let candidates = activeWindows.filter { $0.kind != .settings }
        guard let oldest = candidates.sorted(by: { $0.createdAt < $1.createdAt }).first else {
            return
        }
        guard let idx = windows.firstIndex(where: { $0.id == oldest.id }) else { return }
        windows[idx].isDocked = true
    }

    private func enforceMaxActive() {
        while activeWindows.count > 3 {
            dockOldestNonSettings()
        }
    }

    // MARK: - Drag & drop među AKTIVNIM prozorima

    /// OVO se zove dok dragaš – ovdje prozor dobiva pomak
    func updateDrag(id: UUID, translation: CGSize) {
        guard let idx = windows.firstIndex(where: { $0.id == id }) else { return }
        guard !windows[idx].isDocked else { return }
        windows[idx].offset = translation
    }

    /// OVO se zove kad pustiš – swap logika + reset offseta
    func endDrag(id: UUID, translation: CGSize, windowWidth: CGFloat) {
        guard let idx = windows.firstIndex(where: { $0.id == id }) else { return }
        guard !windows[idx].isDocked else { return }

        let activeIndices = windows.indices.filter { !windows[$0].isDocked }
        guard let pos = activeIndices.firstIndex(of: idx) else { return }

        let threshold = windowWidth / 2
        let dx = translation.width
        var newPos = pos

        if dx > threshold && pos < activeIndices.count - 1 {
            newPos = pos + 1        // zamijeni s desnim
        } else if dx < -threshold && pos > 0 {
            newPos = pos - 1        // zamijeni s lijevim
        }

        if newPos != pos {
            let fromIndex = activeIndices[pos]
            let toIndex   = activeIndices[newPos]
            let win = windows.remove(at: fromIndex)
            windows.insert(win, at: toIndex)
        }

        // reset offset za sve aktivne (da sjednu na nove pozicije)
        for i in windows.indices {
            if !windows[i].isDocked {
                windows[i].offset = .zero
            }
        }
    }
}
