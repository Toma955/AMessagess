import SwiftUI

/// Stavka u docku za "Neovisne poruke" / serverless chat.
struct DockIndependentMessagesItem: View {
    var onRestore: () -> Void
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // ikona tipa – serverless / direktna konekcija
            Image(systemName: "personalhotspot")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))

            VStack(alignment: .leading, spacing: 2) {
                Text("Neovisne poruke")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))

                Text("Poruke bez posrednika")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.45))
            }

            Spacer()

            // zeleni “restore” gumb
            Button(action: onRestore) {
                Image(systemName: "rectangle.and.arrow.up.right.and.arrow.down.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 0.25, green: 0.9, blue: 0.45))
            }
            .buttonStyle(.plain)

            // crveni X
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.3))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
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
