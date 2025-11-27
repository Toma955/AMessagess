import SwiftUI

/// Bazični header za prozor
struct WindowHeaderBar: View {
    var title: String? = nil
    var statusColor: Color? = nil   // npr. .green ili .red

    var onClose: () -> Void = {}
    var onMinimize: () -> Void = {}
    var onSearch: () -> Void = {}
    var onQuickSettings: () -> Void = {}

    private let fixedWidth: CGFloat = 420

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black)

            HStack(spacing: 16) {
                // lijevo: X + minus (+ opcionalni status + title)
                HStack(spacing: 10) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.25, blue: 0.25))
                    }

                    Button(action: onMinimize) {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 0.25, green: 0.9, blue: 0.4))
                    }

                    if let title = title {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(statusColor ?? .red)
                                .frame(width: 8, height: 8)
                            Text(title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }

                Spacer()

                // desno: search + quick settings
                HStack(spacing: 14) {
                    Button(action: onSearch) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }

                    Button(action: onQuickSettings) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
        }
        .frame(width: fixedWidth, height: 40)
        .buttonStyle(.plain)
    }
}
