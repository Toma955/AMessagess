import SwiftUI

enum DockSide {
    case left
    case right
}

struct GlassDockWindow: View {
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var session: SessionManager       // 🆕 za zastavice

    @Binding var isVisible: Bool
    @Binding var dockSide: DockSide
    @Binding var dragOffset: CGFloat

    let dockedWindows: [WindowState]
    let onUndock: (UUID) -> Void
    let onDropFromDock: (UUID) -> Void

    private let baseWidth: CGFloat = 190

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    // filtriramo prozore prema zastavicama u SessionManageru
                    ForEach(dockedWindows.filter { isKindVisible($0.kind) }) { win in
                        DockItemView(
                            window: win,
                            onSwapToActive: {
                                withAnimation(.spring(
                                    response: 0.30,
                                    dampingFraction: 0.85
                                )) {
                                    windowManager.swapDockWithOldestActive(dockedId: win.id)
                                }
                            },
                            onClose: {
                                if let idx = windowManager.windows.firstIndex(where: { $0.id == win.id }) {
                                    withAnimation(.spring(
                                        response: 0.25,
                                        dampingFraction: 0.9
                                    )) {
                                        windowManager.windows.remove(at: idx)
                                    }
                                }
                            },
                            onDragOut: {
                                withAnimation(.spring(
                                    response: 0.35,
                                    dampingFraction: 0.85
                                )) {
                                    onDropFromDock(win.id)
                                }
                            },
                            onMoveUp: {
                                windowManager.moveDocked(id: win.id, direction: -1)
                            },
                            onMoveDown: {
                                windowManager.moveDocked(id: win.id, direction: 1)
                            }
                        )
                    }
                }
            }

            Button {
                withAnimation(.spring(
                    response: 0.35,
                    dampingFraction: 0.85
                )) {
                    isVisible = false
                }
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "rectangle.on.rectangle")
                        .font(.system(size: 11, weight: .medium))
                    Text("Prozori")
                        .font(.system(size: 11, weight: .semibold))
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.95))
                )
                .foregroundColor(.black)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let dx = value.translation.width
                        let distance = abs(dx)

                        if distance > 60 {
                            if dx < 0 {
                                dockSide = .left
                            } else {
                                dockSide = .right
                            }
                        }

                        withAnimation(.spring(
                            response: 0.3,
                            dampingFraction: 0.85
                        )) {
                            dragOffset = 0
                        }
                    }
            )
        }
        .frame(width: baseWidth)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(radius: 10)
        )
        .frame(maxHeight: .infinity, alignment: .center)
        .frame(
            maxWidth: .infinity,
            alignment: dockSide == .right ? .trailing : .leading
        )
        .padding(dockSide == .right ? .trailing : .leading, 16)
    }

    // MARK: - Filtriranje po zastavicama iz SessionManager-a

    private func isKindVisible(_ kind: WindowKind) -> Bool {
        switch kind {
        case .messages:
            return session.showMessagesEntry
        case .independentMessages:
            return session.showIndependentMessagesEntry
        case .history:
            return session.showHistoryEntry
        case .notes:
            return true          // za sada bilješke uvijek dopuštene
        case .settings:
            return true          // settings se ne gasi zastavicama
        }
    }
}

// MARK: - Jedan item u docku

private struct DockItemView: View {
    let window: WindowState
    let onSwapToActive: () -> Void
    let onClose: () -> Void
    let onDragOut: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    @GestureState private var dragTranslation: CGSize = .zero

    var body: some View {
        let isDragging = dragTranslation != .zero

        itemContent
            .offset(dragTranslation)
            .scaleEffect(isDragging ? 1.03 : 1.0)
            .opacity(isDragging ? 0.9 : 1.0)
            .zIndex(isDragging ? 10 : 0)
            .gesture(
                DragGesture(minimumDistance: 4)
                    .updating($dragTranslation) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        let distance = sqrt(dx * dx + dy * dy)

                        // klik (mali pomak) → swap najstarijeg aktivnog
                        if distance < 12 {
                            onSwapToActive()
                            return
                        }

                        // vertikalno povlačenje → reorder unutar docka
                        if abs(dy) > abs(dx) && abs(dy) > 25 {
                            if dy < 0 {
                                onMoveUp()
                            } else {
                                onMoveDown()
                            }
                            return
                        }

                        // horizontalno povlačenje → izvuci na ekran
                        if abs(dx) > 40 {
                            onDragOut()
                        }
                    }
            )
    }

    @ViewBuilder
    private var itemContent: some View {
        switch window.kind {
        case .messages:
            DockConversationItem(onRestore: onSwapToActive, onClose: onClose)

        case .independentMessages:
            DockIndependentMessagesItem(onRestore: onSwapToActive, onClose: onClose)

        case .history:
            DockHistoryItem(onRestore: onSwapToActive, onClose: onClose)
        case .notes:
            DockNotesItem(onRestore: onSwapToActive, onClose: onClose)
        case .settings:
            DockHistoryItem(onRestore: onSwapToActive, onClose: onClose) // fallback
        }
    }
}
