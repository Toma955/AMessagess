import SwiftUI
#if os(macOS)
import AppKit
#endif

struct AppView: View {
    @EnvironmentObject var conversationManager: ConversationManager
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var windowManager: WindowManager

    @State private var isDockVisible: Bool = true
    @State private var dockSide: DockSide = .right
    @State private var dockDragOffset: CGFloat = 0

    @State private var isGlobalDropTargeted: Bool = false

    #if os(macOS)
    @State private var isAppActive: Bool = true

    private let appDidBecomeActive =
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
    private let appDidResignActive =
        NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)
    #endif

    // MARK: - Trenutna tema iz SessionManagera

    private var currentThemeId: AppThemeID {
        if let raw = Int(session.selectedTheme) {
            return AppThemeID.fromStored(raw)
        } else {
            return .onlineGreen    // default
        }
    }

    // MARK: - Promjena pozadina
    @ViewBuilder
    private var themedBackground: some View {
        switch currentThemeId {
        case .onlineGreen:
            BackgroundView()
        case .oceanBlue:
            OceanBackgroundView()
        case .violetNight:
            NordicBackgroundView()
        case .goldenSunset:
            OrientBackgroundView()
        case .warmOrange:
            GreenParadiseBackgroundView()
        case .alertRed:
            NebulaBackgroundView()
        case .pureBlack:
            Color.black.ignoresSafeArea()
        case .pureWhite:
            Color.white.ignoresSafeArea()
        }
    }

    private func collapseIsland() {
        session.islandCollapseTick += 1
    }

    @ViewBuilder
    private func content(for kind: WindowKind) -> some View {
        switch kind {
        case .messages:
            MessengerWindow()
        case .independentMessages:
            IndependentMessagesWindow()
        case .settings:
            SettingsWindow()
        case .notes:
            NotesWindow()
        case .history:
            HistoryWindow()
        }
    }

    var body: some View {
        GeometryReader { geo in
            let active = windowManager.activeWindows
            let docked = windowManager.dockedWindows
            let hasDock = !docked.isEmpty && isDockVisible

            let totalWidth = geo.size.width
            let dockWidth: CGFloat = hasDock ? 190 : 0
            let gap: CGFloat = 24

            let windowCount = max(active.count, 1)

            let availableForWindows =
                totalWidth
                - dockWidth
                - gap * (CGFloat(windowCount) + 1)

            let minWindowWidth: CGFloat = 260
            let windowWidth =
                max(minWindowWidth,
                    availableForWindows / CGFloat(windowCount))

            ZStack {
                // theme-aware pozadina
                themedBackground
                    .contentShape(Rectangle())
                    .onTapGesture { collapseIsland() }

                // zelena “aura” oko cijele app kad vučeš .secret iznad
                if isGlobalDropTargeted {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.green, lineWidth: 4)
                        .shadow(color: .green.opacity(0.9), radius: 20)
                        .padding(10)
                        .transition(.opacity)
                }

                VStack(spacing: 18) {
                    // MARK: ISLAND
                    HStack {
                        Spacer()
                        Island()
                            .padding(.top, 6)
                        Spacer()
                    }

                    Spacer(minLength: 70)

                    // DOCK + PROZORI
                    HStack(alignment: .center, spacing: gap) {
                        Spacer()
                            .frame(width: gap)

                        // dock lijevo
                        if hasDock && dockSide == .left {
                            GlassDockWindow(
                                isVisible: $isDockVisible,
                                dockSide: $dockSide,
                                dragOffset: $dockDragOffset,
                                dockedWindows: docked,
                                onUndock: { id in
                                    windowManager.undock(id: id)
                                },
                                onDropFromDock: { id in
                                    windowManager.bringDockedToActive(id: id)
                                }
                            )
                            .frame(width: dockWidth)
                        }

                        // MARK: GLAVNI PROZORI
                        if active.isEmpty {
                            AppWindow {
                                WelcomeWindow()
                            }
                            .frame(
                                width: totalWidth * 0.6,
                                height: geo.size.height * 0.65
                            )
                        } else {
                            ForEach(active) { win in
                                AppWindow(isSettings: win.kind == .settings) {
                                    content(for: win.kind)
                                }
                                .frame(
                                    width: windowWidth,
                                    height: geo.size.height * 0.75
                                )
                                .offset(win.offset)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            windowManager.updateDrag(
                                                id: win.id,
                                                translation: value.translation
                                            )
                                        }
                                        .onEnded { value in
                                            withAnimation(
                                                .spring(response: 0.32,
                                                        dampingFraction: 0.8)
                                            ) {
                                                windowManager.endDrag(
                                                    id: win.id,
                                                    translation: value.translation,
                                                    windowWidth: windowWidth
                                                )
                                            }
                                        }
                                )
                            }
                        }

                        // dock desno
                        if hasDock && dockSide == .right {
                            GlassDockWindow(
                                isVisible: $isDockVisible,
                                dockSide: $dockSide,
                                dragOffset: $dockDragOffset,
                                dockedWindows: docked,
                                onUndock: { id in
                                    windowManager.undock(id: id)
                                },
                                onDropFromDock: { id in
                                    windowManager.bringDockedToActive(id: id)
                                }
                            )
                            .frame(width: dockWidth)
                        }

                        Spacer()
                            .frame(width: gap)
                    }
                    .frame(maxWidth: .infinity,
                           maxHeight: geo.size.height * 0.8,
                           alignment: .top)
                    .animation(
                        .spring(response: 0.32, dampingFraction: 0.85),
                        value: windowManager.windows
                    )

                    Spacer(minLength: 12)

                    // MARK: "Prozori" DOCK skriven
                    if !docked.isEmpty && !isDockVisible {
                        HStack {
                            if dockSide == .left {
                                Button {
                                    withAnimation(
                                        .spring(response: 0.35,
                                                dampingFraction: 0.85)
                                    ) {
                                        isDockVisible = true
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "rectangle.on.rectangle")
                                            .font(.system(size: 11, weight: .medium))
                                        Text("Prozori")
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.95))
                                    )
                                    .foregroundColor(.black)
                                }
                                .buttonStyle(.plain)
                                .padding(.leading, 40)

                                Spacer()
                            } else {
                                Spacer()

                                Button {
                                    withAnimation(
                                        .spring(response: 0.35,
                                                dampingFraction: 0.85)
                                    ) {
                                        isDockVisible = true
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "rectangle.on.rectangle")
                                            .font(.system(size: 11, weight: .medium))
                                        Text("Prozori")
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.95))
                                    )
                                    .foregroundColor(.black)
                                }
                                .buttonStyle(.plain)
                                .padding(.trailing, 40)
                            }
                        }
                        .padding(.bottom, 4)
                    }

                    // MARK: - STATUS BAR
                    AppStatusBar(
                        onLock: {
                            session.lock()
                            windowManager.closeAll()
                        },
                        onQuit: {
                            windowManager.closeAll()
                            session.lock()
                            #if os(macOS)
                            NSApp.terminate(nil)
                            #endif
                        },
                        onConnect: { id in
                            if id == session.islandCurrentId {
                                session.pendingCallId = nil
                                session.pendingCallerName = ""
                                windowManager.open(kind: .notes)
                            } else {
                                session.pendingCallId = id
                                session.pendingCallerName = ""
                                windowManager.open(kind: .messages)
                            }
                        },
                        onOpenMessages: {
                            windowManager.open(kind: .messages)
                        },
                        onOpenIndependentMessages: {
                            windowManager.open(kind: .independentMessages)
                        },
                        onOpenNotes: {
                            windowManager.open(kind: .notes)
                        },
                        onOpenContacts: {
                            windowManager.open(kind: .history)   // za sada isto kao arhiva
                        },
                        onOpenSettings: {
                            windowManager.toggleSettings()
                        },
                        onOpenHistory: {
                            windowManager.open(kind: .history)
                        }

                    )
                    .simultaneousGesture(
                        TapGesture().onEnded { collapseIsland() }
                    )
                    .padding(.bottom, 16)
                }
                #if os(macOS)
                if session.focusModeEnabled && !isAppActive {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(Color.black.opacity(0.45))
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
                #endif
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onDrop(
                of: ["public.file-url"],
                isTargeted: $isGlobalDropTargeted,
                perform: handleAppDrop(providers:)
            )
            #if os(macOS)
            .onReceive(appDidBecomeActive) { _ in
                isAppActive = true
            }
            .onReceive(appDidResignActive) { _ in
                isAppActive = false
            }
            #endif
        }
    }

    // MARK: - Globalni drop handler za .secret

    private func handleAppDrop(providers: [NSItemProvider]) -> Bool {
        guard let item = providers.first(where: {
            $0.hasItemConformingToTypeIdentifier("public.file-url")
        }) else {
            return false
        }

        item.loadItem(forTypeIdentifier: "public.file-url",
                      options: nil) { data, _ in
            guard
                let data = data as? Data,
                let url = URL(dataRepresentation: data, relativeTo: nil),
                url.pathExtension == "secret"
            else { return }

            DispatchQueue.main.async {
                // HistoryWindow će ovo pokupit
                windowManager.pendingHistoryFileURL = url

                // ako nema otvorenog history prozora → otvori novi
                if !windowManager.activeWindows.contains(where: { $0.kind == .history }) {
                    windowManager.open(kind: .history)
                }
            }
        }

        return true
    }
}
