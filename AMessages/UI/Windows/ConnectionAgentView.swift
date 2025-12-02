import SwiftUI

/// Traka za odabir agenta za neovisne poruke.
/// Ideja: isti feeling kao gore kod Messages, ali za "profila/agent" izbor.
struct ConnectionAgentView: View {
    @ObservedObject var store: ConnectionAgentStore

    /// Poziva se kad korisnik odabere agenta
    var onSelectAgent: ((ConnectionAgent) -> Void)?

    /// Poziva se kad korisnik zatraži kreiranje novog agenta
    var onCreateAgent: (() -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.agents) { agent in
                    agentChip(for: agent)
                }

                addAgentButton
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.25))
        )
    }

    // MARK: - UI za jednog agenta

    @ViewBuilder
    private func agentChip(for agent: ConnectionAgent) -> some View {
        let isSelected = store.selectedAgent?.id == agent.id

        Button {
            store.select(agent)
            onSelectAgent?(agent)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: agent.iconSystemName)
                    .font(.system(size: 13, weight: .semibold))

                VStack(alignment: .leading, spacing: 2) {
                    Text(agent.name)
                        .font(.system(size: 11, weight: .semibold))

                    if !agent.details.isEmpty {
                        Text(agent.details)
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(backgroundColor(for: agent, selected: isSelected))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSelected ? Color.white.opacity(0.9) : Color.white.opacity(0.15),
                        lineWidth: isSelected ? 1.4 : 1
                    )
            )
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
    }

    // MARK: - "Dodaj agenta" gumb

    private var addAgentButton: some View {
        Button {
            if let onCreateAgent {
                onCreateAgent()
            } else {
                // default ponašanje: dodaj praznog agenta
                let newAgent = ConnectionAgent.empty()
                store.add(newAgent)
                onSelectAgent?(newAgent)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                Text("Novi agent")
                    .font(.system(size: 10, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
            )
        }
        .buttonStyle(.plain)
        .foregroundColor(.white.opacity(0.9))
    }

    // MARK: - Boja po agentu

    private func backgroundColor(for agent: ConnectionAgent, selected: Bool) -> Color {
        let base: Color
        switch agent.colorTag.lowercased() {
        case "green":
            base = .green
        case "orange":
            base = .orange
        case "purple":
            base = .purple
        case "red":
            base = .red
        case "yellow":
            base = .yellow
        default:
            base = .blue
        }

        return selected ? base.opacity(0.85) : base.opacity(0.55)
    }
}
