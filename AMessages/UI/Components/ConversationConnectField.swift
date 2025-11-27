import SwiftUI

struct ConversationConnectField: View {
    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var onConnect: (String) -> Void
    private let maxLength = 16

    var body: some View {
        HStack(spacing: 8) {
            ZStack(alignment: .leading) {
                // nevidljivi TextField – služi samo za unos
                TextField("", text: $text)
                    .focused($isFocused)
                    .onChange(of: text) { newValue in
                        let cleaned = clean(input: newValue)
                        if cleaned.count > maxLength {
                            text = String(cleaned.prefix(maxLength))
                        } else {
                            text = cleaned
                        }
                    }
                    .textFieldStyle(.plain)
                    .opacity(0.01)

                // ono što korisnik vidi
                HStack(spacing: 4) {
                    if text.isEmpty {
                        Text("Session ID")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 2)
                    } else {
                        let chars = Array(text)
                        ForEach(0..<maxLength, id: \.self) { i in
                            if i < chars.count {
                                Text(String(chars[i]))
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .frame(width: 14, height: 18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(Color.white.opacity(0.18))
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    .frame(width: 14, height: 18)
                            }
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }

            // zeleno “Connect” dugme/ikona
            Button {
                let id = text
                guard !id.isEmpty else { return }
                onConnect(id)
                text = ""
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.14))
        )
    }

    private func clean(input: String) -> String {
        let allowed = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        let set = CharacterSet(charactersIn: allowed)
        return String(input.unicodeScalars.filter { set.contains($0) })
    }
}
