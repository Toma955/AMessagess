// TreeOfChoice
// Minimalna struktura za binarna stabla odluke (DecisionTree + TreeNode).
// Stabla ne znaju implementaciju funkcija – samo ime (SessionFunctionID).

import Foundation

struct TreeNode {
    let id: String
    let functionId: SessionFunctionID?
    let nextOnSuccess: String?
    let nextOnFail: String?
}

struct DecisionTree {
    let nodes: [String: TreeNode]
    let rootId: String

    func node(withId id: String) -> TreeNode? {
        nodes[id]
    }

    /// Pomoćna funkcija za debug ispis cijelog stabla.
    func debugPrintTree() {
        print("[DecisionTree] root = \(rootId), nodes = \(nodes.keys)")
    }
}

// MARK: - Glavno stablo izbora (TreeOfChoice)

extension DecisionTree {

    /// Glavno stablo odluke:
    ///
    /// 1) Prvo pokušaj INTERNET (relay/server).
    ///    - ako uspije -> ostani u "global" modu (InternetTree će dalje raditi svoje).
    /// 2) Ako server NIJE dostupan:
    ///    - pokušaj LOCAL NETWORK (ARP / gateway).
    /// 3) Ako ni LAN ne izgleda OK:
    ///    - zadnji fallback je "on device / localhost" provjera.
    ///
    /// Konkretne akcije (postavljanje topologyMode, faultLocation itd.)
    /// rade se unutar funkcija u SessionFunctionRegistry-u.
    static func choiceTree() -> DecisionTree {
        let nodes: [String: TreeNode] = [

            // ROOT: prvo pitamo možemo li doći do relay/servera (global / internet).
            "root": TreeNode(
                id: "root",
                functionId: .checkCanReachRelayServer,
                nextOnSuccess: "internetPath",
                nextOnFail: "tryLocalNetwork"
            ),

            // INTERNET PATH:
            // Ako je .checkCanReachRelayServer == true, ovdje možemo napraviti
            // još jednu provjeru (npr. TLS handshake) ili jednostavno završiti.
            "internetPath": TreeNode(
                id: "internetPath",
                functionId: .checkTlsHandshake,
                nextOnSuccess: nil,   // leaf – InternetTree će kasnije detaljnije raditi
                nextOnFail: "tryLocalNetwork" // ako TLS ne radi, probaj LAN
            ),

            // LOCAL NETWORK PATH:
            // Pokušaj dohvatiti / pingati gateway, provjeriti ARP / DNS itd.
            "tryLocalNetwork": TreeNode(
                id: "tryLocalNetwork",
                functionId: .checkCanReachGateway,
                nextOnSuccess: "localNetworkPath",
                nextOnFail: "fallbackOnDevice"
            ),

            // LAN path – ovdje bi kasnije mogao pozvati LocalNetworkTree
            // (npr. kroz Agent koji vidi da je prošao ovaj čvor).
            "localNetworkPath": TreeNode(
                id: "localNetworkPath",
                functionId: .checkDnsWorks,
                nextOnSuccess: nil,   // leaf za sada
                nextOnFail: "fallbackOnDevice"
            ),

            // ZADNJI FALLBACK: ON DEVICE / LOCALHOST
            //
            // Ovdje očekujemo da funkcija unutar SessionFunctionRegistry-a:
            // - provjeri npr. myDeviceId == peerDeviceId
            // - eventualno postavi diagnosis.topologyMode = .onDevice
            // - vrati true/false ovisno o tome je li ovo stvarno localhost scenarij.
            "fallbackOnDevice": TreeNode(
                id: "fallbackOnDevice",
                functionId: .securityValidateEndpointChange,
                nextOnSuccess: nil,
                nextOnFail: nil
            )
        ]

        return DecisionTree(
            nodes: nodes,
            rootId: "root"
        )
    }

    // MARK: - Debug run s ispisom "kako drvo razmišlja"

    /// Prolazi kroz stablo od root-a, poziva funkcije iz SessionFunctionRegistry
    /// i ispisuje što se dogodilo u svakoj točki. Koristi za testiranje TreeOfChoice-a.
    func runWithLogging(
        context: IndependentMessagesAgentContext,
        registry: SessionFunctionRegistry
    ) {
        print("🌳 [TreeOfChoice] Start – root = \(rootId)")

        var currentId: String? = rootId

        while let nodeId = currentId, let node = nodes[nodeId] {
            if let functionId = node.functionId {
                print("🌿 [TreeOfChoice] Node='\(node.id)', function=\(functionId)")

                guard let fn = registry.function(for: functionId) else {
                    print("⚠️ [TreeOfChoice] Nema registrirane funkcije za \(functionId), prekidam.")
                    break
                }

                let result = fn(context)
                print("   └─ rezultat = \(result ? "✅ success" : "❌ fail")")

                // Odaberi id sljedećeg noda
                let next = result ? node.nextOnSuccess : node.nextOnFail

                if let next = next {
                    print("      ➜ sljedeći node = '\(next)'")
                    currentId = next
                } else {
                    print("      ⏹ leaf node '\(node.id)' – nema sljedećeg, kraj.")
                    currentId = nil
                }
            } else {
                print("🌿 [TreeOfChoice] Node='\(node.id)' bez funkcije – tretiram kao kraj.")
                currentId = nil
            }
        }

        print("✅ [TreeOfChoice] Gotovo.")
    }
}
