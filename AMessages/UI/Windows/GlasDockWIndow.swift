import SwiftUI

enum DockSide {
    case left
    case right
}

struct GlassDockWindow: View {
    @EnvironmentObject var windowManager: WindowManager

    @Binding var isVisible: Bool
    @Binding var dockSide: DockSide
    @Binding var dragOffset: CGFloat

    let dockedWindows: [WindowState]
    let onUndock: (UUID) -> Void
    let onDropFromDock: (UUID) -> Void

    private let baseWidth: CGFloat = 190

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // LISTA PROZORA U DOCKU
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(dockedWindows) { win in
                        DockItemView(
                            window: win,
                            onRestore: {
                                withAnimation(.spring(response: 0.3,
                                                      dampingFraction: 0.85)) {
                                    onUndock(win.id)
                                }
                            },
                            onClose: {
                                if let idx = windowManager.windows.firstIndex(where: { $0.id == win.id }) {
                                    windowManager.windows.remove(at: idx)
                                }
                            },
                            onDropOut: {
                                withAnimation(.spring(response: 0.35,
                                                      dampingFraction: 0.85)) {
                                    onDropFromDock(win.id)
                                    isVisible = false
                                }
                            }
                        )
                    }
                }
            }

            // DONJI BIJELI GUMB = RUČKA ZA CIJELI PANEL
            Button {
                withAnimation(.spring(response: 0.35,
                                      dampingFraction: 0.85)) {
                    isVisible = false
                }
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "chevron.left.arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Prozori")
                        .font(.system(size: 11, weight: .semibold))
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white)
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
                        let dy = value.translation.height
                        let distance = sqrt(dx * dx + dy * dy)

                        if distance < 5 {
                            // tap već odrađen gore
                        } else {
                            if dx < -80 {
                                dockSide = .left
                            } else if dx > 80 {
                                dockSide = .right
                            }
                        }

                        withAnimation(.spring(response: 0.3,
                                              dampingFraction: 0.85)) {
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
        .frame(maxWidth: .infinity,
               alignment: dockSide == .right ? .trailing : .leading)
        .padding(dockSide == .right ? .trailing : .leading, 16)
    }
}

// MARK: - Jedan item u docku

private struct DockItemView: View {
    let window: WindowState
    let onRestore: () -> Void
    let onClose: () -> Void
    let onDropOut: () -> Void

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

                        if distance < 15 {
                            // tap → restore
                            onRestore()
                        } else {
                            // veći drag → izvlačenje
                            onDropOut()
                        }
                    }
            )
    }

    @ViewBuilder
    private var itemContent: some View {
        switch window.kind {
        case .messages:
            DockConversationItem(onRestore: onRestore, onClose: onClose)
        case .history:
            DockHistoryItem(onRestore: onRestore, onClose: onClose)
        case .notes:
            DockNotesItem(onRestore: onRestore, onClose: onClose)
        case .settings:
            DockHistoryItem(onRestore: onRestore, onClose: onClose) // fallback
        }
    }
}
