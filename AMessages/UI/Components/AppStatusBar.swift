import SwiftUI

struct AppStatusBar: View {
    @EnvironmentObject var session: SessionManager

    var onLock: () -> Void
    var onQuit: () -> Void
    var onConnect: (String) -> Void

    var onOpenMessages: () -> Void
    var onOpenIndependentMessages: () -> Void
    var onOpenNotes: () -> Void
    var onOpenContacts: () -> Void
    var onOpenSettings: () -> Void
    var onOpenHistory: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // 🔌 CONNECT FIELD – ID sesije
            if session.showSessionIdField {
                ConversationConnectField { id in
                    onConnect(id)
                }
                .frame(minWidth: 220, idealWidth: 260, maxWidth: 300)
            }

            // 💬 Poruke (glavni Messenger prozor)
            if session.showMessagesEntry {
                Button {
                    onOpenMessages()
                } label: {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .symbolRenderingMode(.hierarchical)
                }
            }

            // 🛰️ Neovisne poruke / serverless
            if session.showIndependentMessagesEntry {
                Button {
                    onOpenIndependentMessages()
                } label: {
                    Image(systemName: "personalhotspot")
                        .symbolRenderingMode(.hierarchical)
                }
            }

            // 📝 Bilješke
            if session.showNotesEntry {
                Button {
                    onOpenNotes()
                } label: {
                    Image(systemName: "note.text")
                        .symbolRenderingMode(.hierarchical)
                }
            }

            // 👥 Kontakti (trenutno još vodi na povijest / arhivu)
            // — BLOK UKLONJEN —
            // if session.showContactsEntry {
            //     Button {
            //         onOpenContacts()
            //     } label: {
            //         Image(systemName: "person.2.fill")
            //             .symbolRenderingMode(.hierarchical)
            //     }
            // }

            // ⚙️ Postavke – uvijek vidljive
            Button {
                onOpenSettings()
            } label: {
                Image(systemName: "gearshape.fill")
                    .symbolRenderingMode(.hierarchical)
            }

            // 🔍 Reader / povijest / pretraga
            if session.showHistoryEntry {
                Button {
                    onOpenHistory()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .symbolRenderingMode(.hierarchical)
                }
            }

            Divider()
                .frame(height: 18)

            // 🔒 Lock
            if session.showLockButton {
                Button {
                    onLock()
                } label: {
                    Image(systemName: "lock.fill")
                        .symbolRenderingMode(.hierarchical)
                }
            }

            // ⏻ Quit / ugasi app
            if session.showQuitButton {
                Button {
                    onQuit()
                } label: {
                    Image(systemName: "power")
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(radius: 8)
        )
    }
}
