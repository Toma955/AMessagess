import SwiftUI
#if os(macOS)
import AppKit
#endif

struct Island: View {
    private enum Mode {
        case collapsed
        case idView
        case edit
    }

    @EnvironmentObject var session: SessionManager

    @State private var mode: Mode = .collapsed
    @State private var mainId: String = Island.generateId()
    @State private var justCopied: Bool = false

    @State private var editableChars: [String] = Array(repeating: "", count: 16)
    @FocusState private var focusedIndex: Int?

    private var horizontalPadding: CGFloat {
        guard session.pendingCallId == nil else { return 14 }
        switch mode {
        case .collapsed: return 14
        case .idView:    return 18
        case .edit:      return 24
        }
    }

    var body: some View {
        Group {
            if let callId = session.pendingCallId {
                callSetupContent(callId: callId)
            } else {
                defaultContent
            }
        }
        .padding(.vertical, (session.pendingCallId == nil && mode == .collapsed) ? 6 : 8)
        .padding(.horizontal, horizontalPadding)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    session.pendingCallId == nil
                    ? Color.black.opacity(0.85)
                    : Color.green.opacity(0.85)
                )
                .shadow(radius: 10)
        )
        .fixedSize(horizontal: true, vertical: true)
        .animation(.spring(response: 0.28, dampingFraction: 0.85), value: mode)
        .animation(.spring(response: 0.28, dampingFraction: 0.85), value: session.pendingCallId)
        .onTapGesture {
            // klik direktno na Island
            guard session.pendingCallId == nil else { return }
            withAnimation {
                switch mode {
                case .collapsed:
                    mode = .idView
                default:
                    mode = .collapsed
                }
            }
        }
        .onChange(of: session.islandCollapseTick) { _ in
            // klik negdje drugdje u appu
            guard session.pendingCallId == nil else { return }
            withAnimation {
                mode = .collapsed
            }
        }
        .onAppear {
            session.islandCurrentId = mainId
        }
    }

    // MARK: - DEFAULT (crni) ISLAND

    @ViewBuilder
    private var defaultContent: some View {
        switch mode {
        case .collapsed:
            Text("AMessages")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)

        case .idView:
            VStack(alignment: .center, spacing: 6) {
                Text("AMessages")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 10) {
                    // strelica DOLJE → otvara edit
                    Button {
                        enterEditMode()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.plain)

                    // ID kao bijeli gumb (copy)
                    Button {
                        copyToClipboard(mainId)
                    } label: {
                        HStack(spacing: 4) {
                            ForEach(Array(mainId.enumerated()), id: \.0) { _, ch in
                                Text(String(ch))
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(width: 16, height: 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(Color.white.opacity(0.9))
                                    )
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white)
                        )
                    }
                    .buttonStyle(.plain)

                    // REGENERATE – mijenja ID samo kad klikneš
                    Button {
                        regenerate()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.plain)

                    if justCopied {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
            }

        case .edit:
            VStack(alignment: .center, spacing: 8) {
                // GORE: strelica GORE + REGENERATE
                HStack(spacing: 10) {
                    Button {
                        // izlaz iz edit moda, spremi uneseni ID
                        withAnimation {
                            mode = .idView
                            focusedIndex = nil
                            mainId = normalizedEditableId()
                            session.islandCurrentId = mainId
                        }
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        // generate novi ID i popuni polja
                        let newId = Island.generateId()
                        mainId = newId
                        session.islandCurrentId = newId
                        let chars = Array(newId)
                        editableChars = (0..<16).map { idx in
                            idx < chars.count ? String(chars[idx]) : ""
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.plain)
                }

                // SREDINA: editable kućice (inicijalno prazne)
                HStack(spacing: 4) {
                    ForEach(0..<16, id: \.self) { index in
                        EditableCharBox(
                            text: $editableChars[index],
                            index: index,
                            focusedIndex: $focusedIndex,
                            onChanged: {
                                let id = normalizedEditableId()
                                mainId = id
                                session.islandCurrentId = id
                            }
                        )
                    }
                }
                .padding(.top, 2)

                // DOLJE: COPY gumb
                HStack {
                    Spacer()
                    Button {
                        let id = normalizedEditableId()
                        mainId = id
                        session.islandCurrentId = id
                        copyToClipboard(id)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - ZELENI CALL MODE

    @ViewBuilder
    private func callSetupContent(callId: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ID poziva:")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)

            HStack(spacing: 4) {
                ForEach(Array(callId.enumerated()), id: \.0) { _, ch in
                    Text(String(ch))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.green)
                        .frame(width: 16, height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.white.opacity(0.9))
                        )
                }
            }

            TextField("Naziv korisnika", text: Binding(
                get: { session.pendingCallerName },
                set: { session.pendingCallerName = String($0.prefix(32)) }
            ))
            .textFieldStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.15))
            )
            .foregroundColor(.white)
            .font(.system(size: 12))

            let canStartCall = !session.requireCallerName ||
                !session.pendingCallerName.trimmingCharacters(in: .whitespaces).isEmpty

            HStack(spacing: 10) {
                Spacer()

                Button {
                    // TODO: prava logika spajanja
                    print("Start call to \(callId) as \(session.pendingCallerName)")
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(canStartCall ? .white : Color.white.opacity(0.4))
                }
                .buttonStyle(.plain)
                .disabled(!canStartCall)

                Button {
                    withAnimation {
                        session.pendingCallId = nil
                        session.pendingCallerName = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Logika

    private func regenerate() {
        mainId = Island.generateId()
        session.islandCurrentId = mainId
        justCopied = false
    }

    private func enterEditMode() {
        // polja prazna – korisnik unosi novi ID ručno
        editableChars = Array(repeating: "", count: 16)
        withAnimation {
            mode = .edit
        }
        DispatchQueue.main.async {
            focusedIndex = 0
        }
    }

    private func normalizedEditableId() -> String {
        let allowed = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        let set = CharacterSet(charactersIn: allowed)

        let joined = editableChars.joined()
        let filtered = joined.unicodeScalars.filter { set.contains($0) }
        let trimmed = String(String.UnicodeScalarView(filtered)).prefix(16)
        return String(trimmed)
    }

    private func copyToClipboard(_ id: String) {
        #if os(macOS)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(id, forType: .string)
        #endif
        withAnimation(.easeOut(duration: 0.15)) {
            justCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.2)) {
                justCopied = false
            }
        }
    }

    static func generateId() -> String {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
        return String((0..<16).compactMap { _ in chars.randomElement() })
    }
}

// MARK: - EditableCharBox

private struct EditableCharBox: View {
    @Binding var text: String
    let index: Int
    let focusedIndex: FocusState<Int?>.Binding
    var onChanged: () -> Void

    var body: some View {
        ZStack {
            TextField("", text: $text)
                .multilineTextAlignment(.center)
                .focused(focusedIndex, equals: index)
                .onChange(of: text) { newValue in
                    if newValue.count > 1 {
                        text = String(newValue.suffix(1))
                    }

                    if !text.isEmpty {
                        let next = index + 1
                        focusedIndex.wrappedValue = next < 16 ? next : nil
                    }

                    onChanged()
                }
                .textFieldStyle(.plain)
                .frame(width: 0, height: 0)
                .opacity(0.01)

            Text(displayChar)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 16, height: 20)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.white.opacity(0.15))
                        )
                )
        }
        .onTapGesture {
            focusedIndex.wrappedValue = index
        }
    }

    private var displayChar: String {
        text.isEmpty ? " " : text
    }
}
