import SwiftUI

struct DockWindowItem: View {
    let window: WindowState
    var onClose: () -> Void
    var onRestore: () -> Void

    private var title: String {
        switch window.kind {
        case .messages: return "Razgovor"
        case .history:  return "Povijest"
        case .notes:    return "Bilješke"
        case .settings: return "Postavke"
        }
    }

    private var typeIconName: String {
        switch window.kind {
        case .messages: return "bubble.left.and.bubble.right.fill"
        case .history:  return "text.justify"
        case .notes:    return "note.text"
        case .settings: return "gearshape.fill"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            // ikona tipa (poruke / notes / reader)
            Image(systemName: typeIconName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))

                // future: zadnja poruka / vrijeme
                Text("—")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.45))
            }

            Spacer()

            // zeleno: “window” / maximize
            Button(action: onRestore) {
                Image(systemName: "rectangle.and.arrow.up.right.and.arrow.down.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 0.25, green: 0.9, blue: 0.45))
            }
            .buttonStyle(.plain)

            // crveno X – zatvori
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.3))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading) // “duže” stavke
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04)) // lagano stakleno, praktički prozirno
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }
}
