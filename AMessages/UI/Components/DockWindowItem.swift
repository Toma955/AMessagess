import SwiftUI

struct DockWindowItem: View {
    let window: WindowState
    var onClose: () -> Void
    var onRestore: () -> Void

    // Naslov po tipu prozora
    private var title: String {
        switch window.kind {
        case .messages:
            return "Razgovor"
        case .independentMessages:
            return "Neovisne poruke"
        case .history:
            return "Povijest"
        case .notes:
            return "Bilješke"
        case .settings:
            return "Postavke"
        }
    }

    // Podnaslov / opis
    private var subtitle: String {
        switch window.kind {
        case .messages:
            return "Glavni chat prozor"
        case .independentMessages:
            return "Poruke bez posrednika"
        case .history:
            return "Pregled starih razgovora"
        case .notes:
            return "Brze bilješke i zapisi"
        case .settings:
            return "Postavke aplikacije"
        }
    }

    // Ikona po tipu prozora
    private var iconName: String {
        switch window.kind {
        case .messages:
            return "bubble.left.and.bubble.right.fill"
        case .independentMessages:
            return "personalhotspot"
        case .history:
            return "clock.arrow.circlepath"
        case .notes:
            return "note.text"
        case .settings:
            return "gearshape.fill"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.45))
                    .lineLimit(1)
            }

            Spacer()

            // Zeleni “restore” gumb
            Button(action: onRestore) {
                Image(systemName: "rectangle.and.arrow.up.right.and.arrow.down.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 0.25, green: 0.9, blue: 0.45))
            }
            .buttonStyle(.plain)

            // Crveni X
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.3))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }
}
