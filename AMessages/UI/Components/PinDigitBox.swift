import SwiftUI

struct PinDigitBox: View {
    @Binding var text: String
    let index: Int
    let focusedIndex: FocusState<Int?>.Binding

    var onChanged: () -> Void

    private var isFocused: Bool {
        focusedIndex.wrappedValue == index
    }

    var body: some View {
        ZStack {
            // Nevidljivi TextField – služi samo za unos i fokus
            TextField("", text: $text)
                .multilineTextAlignment(.center)
                .focused(focusedIndex, equals: index)
                .onChange(of: text) { newValue in
                    // max 1 znak
                    if newValue.count > 1 {
                        text = String(newValue.suffix(1))
                    }

                    // auto skok na sljedeće polje
                    if !text.isEmpty {
                        let next = index + 1
                        focusedIndex.wrappedValue = next < 12 ? next : nil
                    }

                    onChanged()
                }
                .textFieldStyle(.plain)   // bez macOS okvira
                .frame(width: 0, height: 0) // praktički nevidljiv layout
                .opacity(0.01)             // ali i dalje prima fokus

            // Vidljivi “kvadratić” PIN polja
            RoundedRectangle(cornerRadius: 6)
                .stroke(isFocused ? Color.green : Color.clear, lineWidth: 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Text(displayChar)
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                )
        }
        .frame(width: 26, height: 34)
        .onTapGesture {
            focusedIndex.wrappedValue = index
        }
    }

    private var displayChar: String {
        guard !text.isEmpty else { return "" }
        return isFocused ? text : "*"
    }
}
