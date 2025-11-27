import SwiftUI

struct MessengerWindow: View {
    @EnvironmentObject var windowManager: WindowManager
    @State private var messageText: String = ""

    private let conversationTitle = "Razgovor"
    private let isSessionActive = false

    private let barWidth: CGFloat = 420
    private let barHeight: CGFloat = 45
    private let controlSize: CGFloat = 30

    var body: some View {
        VStack(spacing: 0) {
            // HEADER – centriran
            HStack {
                Spacer()
                MessengerHeaderBar(
                    title: conversationTitle,
                    isActive: isSessionActive,
                    onClose: {
                        if let idx = windowManager.windows.firstIndex(
                            where: { $0.kind == .messages && !$0.isDocked }
                        ) {
                            windowManager.windows.remove(at: idx)
                        }
                    },
                    onMinimize: { },
                    onSearch: { },
                    onQuickSettings: { }
                )
                Spacer()
            }

            // sredina prazna
            Spacer()

            // DONJI ELEMENT – BEZ IKAKVOG MARGIN / PADDING DOLJE
            HStack {
                Spacer()
                bottomBar
                Spacer()
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 8) {
            // + datoteke
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.55, blue: 0.2),
                            Color(red: 0.9, green: 0.15, blue: 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: controlSize, height: controlSize)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                )

            // glasovne
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.55, blue: 0.2),
                            Color(red: 0.9, green: 0.15, blue: 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: controlSize, height: controlSize)
                .overlay(
                    Image(systemName: "waveform")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                )

            // input
            TextField("Napiši poruku…", text: $messageText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 10)
                .frame(height: controlSize)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                )
                .foregroundColor(.black)

            // send
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.2, green: 0.85, blue: 0.45))
                .frame(width: 55, height: controlSize)
                .overlay(
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                )
        }
        .padding(.horizontal, 10)                  // SAMO UNUTARNJI padding
        .frame(width: barWidth, height: barHeight) // fiksna veličina
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.85))
        )
    }
}
