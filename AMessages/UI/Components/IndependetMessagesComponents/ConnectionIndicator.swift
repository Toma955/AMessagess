import SwiftUI

struct ConnectionIndicator: View {

    enum Mode {
        case notConnected   // "Not con" – crveno
        case server         // "Ser"     – narančasto
        case p2p            // "P2P"     – zeleno (serverless)
        case arp            // "ARP"     – žuto (lokalna mreža)
        case local          // "Loc"     – bijelo (isto računalo)
        case bluetooth      // "Blo"     – plavo
    }

    let mode: Mode
    @Binding var isExpanded: Bool
    var onTap: () -> Void = {}

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
            onTap()
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(color.opacity(0.7))
                    .frame(width: 8, height: 8)

                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(width: isExpanded ? 110 : 60, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(Color.white.opacity(0.08))   // “prozirna tekstura”
            )
            .overlay(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .stroke(color.opacity(0.9), lineWidth: 1)
            )
            .foregroundColor(color)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Label & boje

    private var label: String {
        switch mode {
        case .server:       return "Ser"
        case .bluetooth:    return "Blo"
        case .p2p:          return "P2P"
        case .arp:          return "ARP"
        case .local:        return "Loc"
        case .notConnected: return "Not con"
        }
    }

    private var color: Color {
        switch mode {
        case .server:       return .orange
        case .bluetooth:    return .blue
        case .p2p:          return .green
        case .arp:          return .yellow
        case .local:        return .white
        case .notConnected: return .red
        }
    }
}
