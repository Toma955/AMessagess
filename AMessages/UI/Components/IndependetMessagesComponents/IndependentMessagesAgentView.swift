//
//  IndependentMessagesAgentView.swift
//  AMessages
//
//  Created by Toma Babić on 02.12.2025..
//

// ConnectionAgentViewModel
// ObservableObject koji drži stanje za UI agenta (mrežna topologija, opis, boje).

import Foundation
import Combine

final class ConnectionAgentViewModel: ObservableObject {

    @Published var diagnosis: IndependentMessagesDiagnosisResult = IndependentMessagesDiagnosisResult()
    @Published var isExpanded: Bool = false

    /// Pomoćna funkcija za ručni update (kasnije će dolaziti iz agenta).
    func debugSetSampleData() {
        diagnosis.faultLocation = .none
        diagnosis.topologyMode = .p2pInternet
        diagnosis.transportMode = .p2p
        diagnosis.isServerActive = false
        diagnosis.humanSummary = "Primjer: sve izgleda u redu."
    }
}
