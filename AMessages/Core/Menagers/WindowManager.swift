import SwiftUI

enum WindowKind: Equatable {
    case messages
    case settings
    case history
    case notes
    case independentMessages 
}

struct WindowState: Identifiable, Equatable {
    let id: UUID
    var kind: WindowKind
    var offset: CGSize
    var isDocked: Bool
    var createdAt: Date

    init(
        kind: WindowKind,
        offset: CGSize = .zero,
        isDocked: Bool = false,
        createdAt: Date = Date()
    ) {
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

    // MARK: - Otvaranje / zatvaranje

    func open(kind: WindowKind) {
        // Settings smije postojati samo jedan
        if kind == .settings {
            if let idx = windows.firstIndex(where: { $0.kind == .settings }) {
                windows[idx].isDocked = false
                windows[idx].offset   = .zero
                windows[idx].createdAt = Date()
                return
            }
        }

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

    // MARK: - Dock / undock / swap

    /// Jednostavno izvuci prozor iz docka na ekran
    func undock(id: UUID) {
        guard let idx = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[idx].isDocked   = false
        windows[idx].offset     = .zero
        windows[idx].createdAt  = Date()   // osvježi – postaje "noviji"
        enforceMaxActive()
    }

    /// Dovedi dockani prozor na ekran.
    /// Ako ima ≥ 3 aktivna → najstariji (koji nije settings) ide u dock.
    func bringDockedToActive(id: UUID) {
        guard let idx = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[idx].isDocked   = false
        windows[idx].offset     = .zero
        windows[idx].createdAt  = Date()   // ovaj je sad "najnoviji"

        let actives = activeWindows
        if actives.count >= 3 {
            dockOldestNonSettings()
        }
    }

    /// Klik na item u docku → zamijeni s najstarijim aktivnim.
    /// Ako nema aktivnih → samo undock.
    func swapDockWithOldestActive(dockedId: UUID) {
        guard let dockIdx = windows.firstIndex(where: { $0.id == dockedId }) else { return }
        guard windows[dockIdx].isDocked else { return }

        let active = activeWindows

        // nema aktivnih → samo izvuci
        guard !active.isEmpty else {
            windows[dockIdx].isDocked   = false
            windows[dockIdx].offset     = .zero
            windows[dockIdx].createdAt  = Date()
            return
        }

        // preferiraj ne-settings prozor
        let candidates = active.filter { $0.kind != .settings }
        let pool = candidates.isEmpty ? active : candidates

        guard let target = pool.min(by: { $0.createdAt < $1.createdAt }) else { return }
        guard let targetIdx = windows.firstIndex(where: { $0.id == target.id }) else { return }

        // aktivni ide u dock
        windows[targetIdx].isDocked  = true
        windows[targetIdx].offset    = .zero
        // createdAt ostaje – on je ionako najstariji

        // dockani izlazi na ekran i postaje "najnoviji"
        windows[dockIdx].isDocked    = false
        windows[dockIdx].offset      = .zero
        windows[dockIdx].createdAt   = Date()

        enforceMaxActive()
    }

    /// Reorder unutar dock liste (pomak gore/dolje)
    func moveDocked(id: UUID, direction: Int) {
        guard direction != 0 else { return }

        let dockedIds = dockedWindows.map { $0.id }
        guard let dockPos = dockedIds.firstIndex(of: id) else { return }

        let targetPos = dockPos + direction
        guard targetPos >= 0 && targetPos < dockedIds.count else { return }

        let idA = dockedIds[dockPos]
        let idB = dockedIds[targetPos]

        guard
            let idxA = windows.firstIndex(where: { $0.id == idA }),
            let idxB = windows.firstIndex(where: { $0.id == idB })
        else { return }

        windows.swapAt(idxA, idxB)
    }

    // MARK: - Helperi

    private func dockOldestNonSettings() {
        let candidates = activeWindows.filter { $0.kind != .settings }
        guard let oldest = candidates.sorted(by: { $0.createdAt < $1.createdAt }).first else {
            return
        }
        guard let idx = windows.firstIndex(where: { $0.id == oldest.id }) else { return }
        windows[idx].isDocked = true
        windows[idx].offset   = .zero
        // createdAt ostaje – on je najstariji i sad odlazi u dock
    }

    private func enforceMaxActive() {
        while activeWindows.count > 3 {
            dockOldestNonSettings()
        }
    }

    // MARK: - Drag & drop među AKTIVNIM prozorima

    func updateDrag(id: UUID, translation: CGSize) {
        guard let idx = windows.firstIndex(where: { $0.id == id }) else { return }
        guard !windows[idx].isDocked else { return }
        windows[idx].offset = translation
    }

    func endDrag(id: UUID, translation: CGSize, windowWidth: CGFloat) {
        guard let idx = windows.firstIndex(where: { $0.id == id }) else { return }
        guard !windows[idx].isDocked else { return }

        let activeIndices = windows.indices.filter { !windows[$0].isDocked }
        guard let pos = activeIndices.firstIndex(of: idx) else { return }

        let threshold = windowWidth / 2
        let dx = translation.width
        var newPos = pos

        if dx > threshold && pos < activeIndices.count - 1 {
            newPos = pos + 1
        } else if dx < -threshold && pos > 0 {
            newPos = pos - 1
        }

        if newPos != pos {
            let fromIndex = activeIndices[pos]
            let toIndex   = activeIndices[newPos]
            let win       = windows.remove(at: fromIndex)
            windows.insert(win, at: toIndex)
        }

        for i in windows.indices where !windows[i].isDocked {
            windows[i].offset = .zero
        }
    }
}
