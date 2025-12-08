// AgentNetworkMapView
// Minimalni placeholder za mrežnu topologiju (A – router – server – B).

import SwiftUI

struct AgentNetworkMapView: View {

    let diagnosis: IndependentMessagesDiagnosisResult

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Placeholder – kasnije se ovdje dodaje prava topologija + animacija.
                HStack {
                    VStack {
                        Image(systemName: "laptopcomputer")
                        Text("Ti")
                            .font(.caption2)
                    }

                    Spacer()

                    if diagnosis.transportMode == .p2p {
                        Text("P2P")
                            .font(.caption2)
                    } else {
                        VStack {
                            Image(systemName: "server.rack")
                            Text("Server")
                                .font(.caption2)
                        }
                    }

                    Spacer()

                    VStack {
                        Image(systemName: "person.fill")
                        Text("Druga strana")
                            .font(.caption2)
                    }
                }
                .foregroundColor(.white)
            }
        }
    }
}
