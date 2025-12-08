// Trees+DeviceBasics
// Stablo za osnovne provjere + demo stablo za odluku
// localhost / ARP LAN / internet na temelju A/B endpoint informacija.

import Foundation

// =======================================================
// POSTOJEĆI DIO – ostavljam kako je bio da ne razbijemo projekt
// =======================================================

extension DecisionTree {
    static func deviceBasicsTree() -> DecisionTree {
        let nodes: [String: TreeNode] = [
            "root": TreeNode(
                id: "root",
                functionId: .checkAppAlive,
                nextOnSuccess: nil,
                nextOnFail: nil
            )
        ]

        return DecisionTree(
            nodes: nodes,
            rootId: "root"
        )
    }
}

// =======================================================
// NOVI DIO – binarno stablo za localhost / ARP / internet
// =======================================================

/// Gdje se realno nalazi veza između A i B.
enum LinkLocation {
    case localhost      // isti uređaj / ista instanca
    case arpLAN         // ista javna IP (isti router), različite privatne
    case internet       // različite javne IP adrese / nepoznato
}

/// Jedan endpoint (A ili B).
struct EndpointInfo {
    /// Privatna (LAN) IP adresa, npr. 192.168.1.23
    let privateIP: String?

    /// Javna (WAN) IP adresa, npr. 93.137.x.x
    let publicIP: String?

    /// Port na kojem endpoint sluša / komunicira
    let port: UInt16?
}

/// Kontekst za odluku – imamo A i B stranu.
struct LinkDecisionContext {
    let a: EndpointInfo
    let b: EndpointInfo
}

/// Binarno stablo odluke: svaki čvor je pitanje (YES/NO) ili rezultat.
indirect enum LinkDecisionNode {
    case question((LinkDecisionContext) -> Bool, yes: LinkDecisionNode, no: LinkDecisionNode)
    case result(LinkLocation)

    func decide(_ ctx: LinkDecisionContext) -> LinkLocation {
        switch self {
        case .result(let loc):
            print("[LinkTree] ⏹ leaf = \(loc)")
            return loc

        case .question(let test, let yesNode, let noNode):
            let answer = test(ctx)
            print("[LinkTree] ➤ question → \(answer ? "YES" : "NO")")
            return answer ? yesNode.decide(ctx) : noNode.decide(ctx)
        }
    }
}

/// Glavno drvo odluke za lokaciju veze.
struct LinkLocationDecisionTree {

    let root: LinkDecisionNode

    /// Glavno “default” stablo:
    ///
    /// 1) Q1: jesu li isti privatni IP, javni IP i port?  → localhost
    /// 2) Q2: ako NE, jesu li isti javni IP, a privatne različite? → arpLAN
    /// 3) inače → internet
    static func makeDefault() -> LinkLocationDecisionTree {

        // Q1: localhost?
        let isLocalhost: (LinkDecisionContext) -> Bool = { ctx in
            let a = ctx.a
            let b = ctx.b

            let privA = a.privateIP ?? ""
            let privB = b.privateIP ?? ""
            let pubA  = a.publicIP ?? ""
            let pubB  = b.publicIP ?? ""

            // privatne moraju postojati i biti iste
            guard
                !privA.isEmpty,
                !privB.isEmpty,
                privA == privB
            else {
                print("[LinkTree] Q1: privatne IP se ne poklapaju → nije localhost")
                return false
            }

            // javne moraju biti iste ili obje nil/prazne (čisto lokalno bez WAN-a)
            let samePublic: Bool
            if pubA.isEmpty && pubB.isEmpty {
                samePublic = true
            } else {
                samePublic = (!pubA.isEmpty && pubA == pubB)
            }

            guard samePublic else {
                print("[LinkTree] Q1: javne IP se ne poklapaju → nije localhost")
                return false
            }

            // portovi moraju postojati i biti jednaki
            guard let pA = a.port, let pB = b.port, pA == pB else {
                print("[LinkTree] Q1: portovi se ne poklapaju ili nedostaju → nije localhost")
                return false
            }

            print("[LinkTree] Q1: isti priv, isti pub, isti port → localhost")
            return true
        }

        // Q2: ista javna IP, različite privatne → LAN / ARP
        let isLanArp: (LinkDecisionContext) -> Bool = { ctx in
            let a = ctx.a
            let b = ctx.b

            let privA = a.privateIP ?? ""
            let privB = b.privateIP ?? ""
            let pubA  = a.publicIP ?? ""
            let pubB  = b.publicIP ?? ""

            guard
                !pubA.isEmpty,
                !pubB.isEmpty,
                pubA == pubB
            else {
                print("[LinkTree] Q2: javne IP nisu iste ili nedostaju → nije LAN")
                return false
            }

            guard
                !privA.isEmpty,
                !privB.isEmpty,
                privA != privB
            else {
                print("[LinkTree] Q2: privatne IP su iste ili prazne → nije LAN")
                return false
            }

            print("[LinkTree] Q2: ista javna, različite privatne → LAN/ARP")
            return true
        }

        // Stablo:
        //
        //          [Q1: localhost?]
        //             /        \
        //          YES          NO
        //         leaf L      [Q2: LAN?]
        //                         /   \
        //                      YES     NO
        //                     leaf A  leaf I

        let tree =
            LinkDecisionNode.question(
                isLocalhost,
                yes: .result(.localhost),
                no: .question(
                    isLanArp,
                    yes: .result(.arpLAN),
                    no: .result(.internet)
                )
            )

        return LinkLocationDecisionTree(root: tree)
    }

    /// Pokreni odluku s ispisom.
    func decide(with ctx: LinkDecisionContext) -> LinkLocation {
        print("🌳 [LinkTree] START")
        let res = root.decide(ctx)
        print("✅ [LinkTree] RESULT = \(res)")
        return res
    }
}

// MARK: - Mali helper za testiranje iz koda Agenta

extension DecisionTree {
    /// Demo helper: možeš pozvati iz Agenta da ispitaš gdje bi svrstao A/B.
    static func debugClassifyLink(
        aPrivate: String?, aPublic: String?, aPort: UInt16?,
        bPrivate: String?, bPublic: String?, bPort: UInt16?
    ) -> LinkLocation {
        let aInfo = EndpointInfo(privateIP: aPrivate, publicIP: aPublic, port: aPort)
        let bInfo = EndpointInfo(privateIP: bPrivate, publicIP: bPublic, port: bPort)
        let ctx = LinkDecisionContext(a: aInfo, b: bInfo)
        let tree = LinkLocationDecisionTree.makeDefault()
        return tree.decide(with: ctx)
    }
}
