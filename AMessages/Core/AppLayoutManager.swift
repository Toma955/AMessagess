import SwiftUI

/// Centralno mjesto gdje app drži SVA pravila kako se layout ponaša
/// ovisno o veličini prozora, fullscreenu i odabranom modu.
final class AppLayoutManager: ObservableObject {

    // MARK: - Public state

    @Published var windowSize: CGSize = .zero {
        didSet { recalcSizeClass() }
    }

    @Published var isFullScreen: Bool = false {
        didSet { recalcSizeClass() }
    }

    /// Move & Resize – 4 scenarija (za kasnije detalje)
    @Published var moveMode: MoveResizeMode = .free

    /// Fill & Arrange – 4 scenarija (za kasnije detalje)
    @Published var fillMode: FillArrangeMode = .floating

    /// Klasa veličine prozora – na temelju dimenzija + aspekta
    @Published private(set) var sizeClass: WindowSizeClass = .normal

    // MARK: - Enum definicije

    /// Kako se prozor ponaša kad ga ručno mijenjaš
    enum MoveResizeMode: String, CaseIterable {
        case free          // slobodno vučeš, kao sada
        case halfScreen    // pola ekrana (Split View)
        case tiled         // kasnije 2×2 raspored
        case focused       // mali lebdeći prozor u sredini
    }

    /// Kako se sadržaj ispunjava prostor
    enum FillArrangeMode: String, CaseIterable {
        case floating      // “glass” prozori, ništa ne puni rub do ruba
        case columns       // više kolona (npr. dock + main)
        case split         // 50/50 layout
        case grid          // raster, npr. više prozora
    }

    /// Klasa veličine prozora prema dimenzijama + aspektu
    enum WindowSizeClass: String {
        case tiny          // jako mali (npr. min. prozor, mali widget)
        case narrow        // usko (pola ekrana u Split Viewu)
        case normal        // “standardno” desktop
        case large         // veliko
        case ultraWide     // ultraširoki monitor (2 prozora komotno)
    }

    // MARK: - Layout za više prozora

    /// Hint za specijalne slučajeve (npr. GlassWindow za najstariji)
    enum LayoutHint {
        case normal
        case useGlassForOldest // npr. 4. prozor ide u GlassWindow
    }

    /// Jedan slot – "ovaj index prozora ide na ovaj relativni frame"
    struct WindowSlot: Identifiable {
        let id = UUID()
        /// index u tvom `windowManager.windows` (ti ga popuniš)
        let windowIndex: Int
        /// Normirani rect (0...1) relativno na glavni app-window
        let frame: CGRect
    }

    /// Rezultat layouta za više prozora
    struct MultiWindowLayout {
        let slots: [WindowSlot]
        let showsDockStrip: Bool
        let dockOnRightSide: Bool
        let hint: LayoutHint
    }

    // MARK: - Public API

    /// Pozivaš kad se glavni macOS prozor promijeni (GeometryReader + WindowStateReader).
    func updateWindow(size: CGSize, isFullScreen: Bool) {
        self.windowSize = size
        self.isFullScreen = isFullScreen
        // recalcSizeClass se zove automatski iz didSet
    }

    /// Glavna funkcija: na temelju broja prozora vrati raspored.
    ///
    /// - windowCount: koliko "unutarnjih" prozora želiš prikazati (Messenger, History, Notes...)
    /// - dockOnRight: preferiraš li dock listu desno (true) ili lijevo (false)
    func layoutForWindows(windowCount: Int, dockOnRight: Bool = true) -> MultiWindowLayout {
        let count = max(0, windowCount)

        switch sizeClass {
        case .narrow:
            // APP u "pola ekrana" (Split View) → tvoja specifična pravila
            return layoutForNarrow(count: count, dockOnRight: dockOnRight)

        case .tiny:
            // JAKO mali prozor → jedan prozor max, bez docka
            return layoutForTiny(count: count)

        case .normal, .large, .ultraWide:
            // full screen / veliki / ultrawide
            return layoutForWide(count: count, dockOnRight: dockOnRight)
        }
    }

    // MARK: - Derived / helper svojstva (koriste view-ovi)

    /// Može li layout komotno prikazati 2 kolone (npr. sidebar + main)?
    var supportsTwoColumns: Bool {
        switch sizeClass {
        case .tiny, .narrow:
            return false
        case .normal, .large, .ultraWide:
            return true
        }
    }

    /// Može li ekran podnijeti 2 odvojena prozora jedan do drugog (ultrawide)?
    var supportsTwoIndependentWindows: Bool {
        return sizeClass == .ultraWide
    }

    /// Koliko “maksimalno” kolona ima smisla u layoutu (dock + history + messages)
    var maxColumns: Int {
        switch sizeClass {
        case .tiny:      return 1
        case .narrow:    return 1
        case .normal:    return 2
        case .large:     return 3
        case .ultraWide: return 4
        }
    }

    /// Treba li sakriti neke teže elemente (npr. povijest, notes panel) radi prostora?
    var shouldHideHeavyPanels: Bool {
        sizeClass == .tiny || sizeClass == .narrow
    }

    /// Predložena širina glavnog “Messenger” prozora
    var preferredMessengerWidth: CGFloat {
        let w = windowSize.width
        guard w > 0 else { return 420 }

        switch sizeClass {
        case .tiny:
            return max(320, w * 0.9)
        case .narrow:
            return max(360, w * 0.95)
        case .normal:
            return min(520, w * 0.6)
        case .large:
            return min(640, w * 0.5)
        case .ultraWide:
            return min(720, w * 0.45)
        }
    }

    /// Predložena maksimalna visina lebdećih prozora (da nisu previsoki)
    var preferredFloatingHeight: CGFloat {
        let h = windowSize.height
        guard h > 0 else { return 600 }

        switch sizeClass {
        case .tiny:      return h * 0.95
        case .narrow:    return h * 0.9
        case .normal:    return h * 0.85
        case .large:     return h * 0.8
        case .ultraWide: return h * 0.75
        }
    }

    /// Je li layout u “focus” modu – npr. tamniji background, manje distrakcija
    var isFocusLayout: Bool {
        moveMode == .focused
    }

    // MARK: - Private: layout pravila

    private func layoutForTiny(count: Int) -> MultiWindowLayout {
        guard count > 0 else {
            return MultiWindowLayout(slots: [], showsDockStrip: false, dockOnRightSide: true, hint: .normal)
        }

        // Sve stane u jedan prozor preko gotovo cijelog app-a
        let slot = WindowSlot(
            windowIndex: 0,
            frame: CGRect(x: 0.05, y: 0.05, width: 0.90, height: 0.90)
        )

        return MultiWindowLayout(
            slots: [slot],
            showsDockStrip: false,
            dockOnRightSide: true,
            hint: .normal
        )
    }

    /// Layout kad je app u “pola ekrana” (narrow) – tvoja pravila:
    /// - 1 prozor: normalno
    /// - 2 prozora: lijepo raspoređenja (gore/dolje)
    /// - 3 prozora: 2 gore, 1 dolje
    /// - 4 prozora: 2 gore, 1 dolje + hint da 4. ide u GlassWindow (najstariji)
    private func layoutForNarrow(count: Int, dockOnRight: Bool) -> MultiWindowLayout {
        var slots: [WindowSlot] = []

        switch count {
        case 0:
            return MultiWindowLayout(slots: [], showsDockStrip: false, dockOnRightSide: dockOnRight, hint: .normal)

        case 1:
            // jedan prozor, praktički cijeli prostor
            slots.append(
                WindowSlot(
                    windowIndex: 0,
                    frame: CGRect(x: 0.05, y: 0.05, width: 0.90, height: 0.90)
                )
            )
            return MultiWindowLayout(
                slots: slots,
                showsDockStrip: false,
                dockOnRightSide: dockOnRight,
                hint: .normal
            )

        case 2:
            // 2 prozora – jedan gore, drugi dolje
            slots.append(
                WindowSlot(
                    windowIndex: 0,
                    frame: CGRect(x: 0.05, y: 0.04, width: 0.90, height: 0.44)
                )
            )
            slots.append(
                WindowSlot(
                    windowIndex: 1,
                    frame: CGRect(x: 0.05, y: 0.52, width: 0.90, height: 0.44)
                )
            )
            return MultiWindowLayout(
                slots: slots,
                showsDockStrip: false,
                dockOnRightSide: dockOnRight,
                hint: .normal
            )

        case 3:
            // 3 prozora – 2 GORE, 1 DOLJE
            slots.append(
                WindowSlot(
                    windowIndex: 0,
                    frame: CGRect(x: 0.05, y: 0.04, width: 0.44, height: 0.42)
                )
            )
            slots.append(
                WindowSlot(
                    windowIndex: 1,
                    frame: CGRect(x: 0.51, y: 0.04, width: 0.44, height: 0.42)
                )
            )
            slots.append(
                WindowSlot(
                    windowIndex: 2,
                    frame: CGRect(x: 0.05, y: 0.50, width: 0.90, height: 0.44)
                )
            )
            return MultiWindowLayout(
                slots: slots,
                showsDockStrip: false,
                dockOnRightSide: dockOnRight,
                hint: .normal
            )

        default:
            // 4 ili više – zadržavamo 3 kao gore, a za 4. šaljemo hint: GlassWindow
            slots.append(
                WindowSlot(
                    windowIndex: 0,
                    frame: CGRect(x: 0.05, y: 0.04, width: 0.44, height: 0.42)
                )
            )
            slots.append(
                WindowSlot(
                    windowIndex: 1,
                    frame: CGRect(x: 0.51, y: 0.04, width: 0.44, height: 0.42)
                )
            )
            slots.append(
                WindowSlot(
                    windowIndex: 2,
                    frame: CGRect(x: 0.05, y: 0.50, width: 0.90, height: 0.44)
                )
            )

            // 4. prozor ne dobiva slot – ide u GlassWindow (najstariji)
            return MultiWindowLayout(
                slots: slots,
                showsDockStrip: false,
                dockOnRightSide: dockOnRight,
                hint: .useGlassForOldest
            )
        }
    }

    /// Layout kad je app "široka" (normal/large/ultraWide, uključujući fullscreen):
    /// - može postojati dock-strip + do 3 prozora
    private func layoutForWide(count: Int, dockOnRight: Bool) -> MultiWindowLayout {
        var slots: [WindowSlot] = []

        // u fullscreenu dopuštamo dock-strip i do 3 normalna prozora
        let showsDock = isFullScreen || sizeClass == .large || sizeClass == .ultraWide
        let dockWidth: CGFloat = showsDock ? 0.12 : 0.0

        let contentX: CGFloat = dockOnRight ? 0.04 : (0.04 + dockWidth)
        let maxWidth: CGFloat = dockOnRight
            ? (0.96 - dockWidth - 0.04)
            : (0.96 - 0.04)

        switch count {
        case 0:
            return MultiWindowLayout(
                slots: [],
                showsDockStrip: showsDock,
                dockOnRightSide: dockOnRight,
                hint: .normal
            )

        case 1:
            // jedan prozor u sredini
            slots.append(
                WindowSlot(
                    windowIndex: 0,
                    frame: CGRect(x: contentX, y: 0.10, width: maxWidth, height: 0.80)
                )
            )

        case 2:
            // 2 prozora – lijevo/desno unutar content područja
            let halfWidth = (maxWidth - 0.02) / 2
            slots.append(
                WindowSlot(
                    windowIndex: 0,
                    frame: CGRect(x: contentX, y: 0.10, width: halfWidth, height: 0.80)
                )
            )
            slots.append(
                WindowSlot(
                    windowIndex: 1,
                    frame: CGRect(x: contentX + halfWidth + 0.02, y: 0.10, width: halfWidth, height: 0.80)
                )
            )

        default:
            // 3 ili više – 2 gore, 1 dolje (unutar content područja)
            let halfWidth = (maxWidth - 0.02) / 2

            slots.append(
                WindowSlot(
                    windowIndex: 0,
                    frame: CGRect(x: contentX, y: 0.08, width: halfWidth, height: 0.40)
                )
            )
            slots.append(
                WindowSlot(
                    windowIndex: 1,
                    frame: CGRect(x: contentX + halfWidth + 0.02, y: 0.08, width: halfWidth, height: 0.40)
                )
            )
            slots.append(
                WindowSlot(
                    windowIndex: 2,
                    frame: CGRect(x: contentX, y: 0.52, width: maxWidth, height: 0.38)
                )
            )
        }

        return MultiWindowLayout(
            slots: slots,
            showsDockStrip: showsDock,
            dockOnRightSide: dockOnRight,
            hint: .normal
        )
    }

    // MARK: - Private – računanje klase veličine

    private func recalcSizeClass() {
        let w = windowSize.width
        let h = windowSize.height
        guard w > 0, h > 0 else {
            sizeClass = .normal
            return
        }

        let aspect = w / h

        if w < 700 || h < 500 {
            sizeClass = .tiny
        } else if w < 1100 {
            sizeClass = .narrow   // ovo je tvoj "pola ekrana" slučaj
        } else if aspect > 2.3 {
            sizeClass = .ultraWide
        } else if w > 1800 || h > 1100 {
            sizeClass = .large
        } else {
            sizeClass = .normal
        }
    }
}
