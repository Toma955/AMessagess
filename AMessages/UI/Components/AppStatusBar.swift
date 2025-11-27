import SwiftUI

struct AppStatusBar: View {
    var onLock: () -> Void
    var onQuit: () -> Void          // ⬅️ NOVO
    var onConnect: (String) -> Void

    var onOpenMessages: () -> Void
    var onOpenContacts: () -> Void
    var onOpenSettings: () -> Void
    var onOpenHistory: () -> Void   // preview / reader

    var body: some View {
        HStack(spacing: 16) {
            // 🔌 CONNECT FIELD – ID sesije
            ConversationConnectField { id in
                onConnect(id)
            }
            .frame(minWidth: 220, idealWidth: 260, maxWidth: 300)

            // 💬 Poruke (Messenger prozor)
            Button {
                onOpenMessages()
            } label: {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .symbolRenderingMode(.hierarchical)
            }

            // 👥 Kontakti
            Button {
                onOpenContacts()
            } label: {
                Image(systemName: "person.2.fill")
                    .symbolRenderingMode(.hierarchical)
            }

            // ⚙️ Postavke
            Button {
                onOpenSettings()
            } label: {
                Image(systemName: "gearshape.fill")
                    .symbolRenderingMode(.hierarchical)
            }

            // 🔍 Reader / povijest / pretraga
            Button {
                onOpenHistory()
            } label: {
                Image(systemName: "magnifyingglass")
                    .symbolRenderingMode(.hierarchical)
            }

            Divider()
                .frame(height: 18)

            // 🔒 Lock
            Button {
                onLock()
            } label: {
                Image(systemName: "lock.fill")
                    .symbolRenderingMode(.hierarchical)
            }

            // ⏻ Quit / ugasi app
            Button {
                onQuit()
            } label: {
                Image(systemName: "power")
                    .symbolRenderingMode(.hierarchical)
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
