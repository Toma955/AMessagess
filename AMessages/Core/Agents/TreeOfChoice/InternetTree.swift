// Trees+Internet
// Placeholder za stablo koje će se baviti provjerom puta do servera, TLS, itd.

import Foundation

extension DecisionTree {
    static func internetTree() -> DecisionTree {
        let nodes: [String: TreeNode] = [
            "root": TreeNode(
                id: "root",
                functionId: .checkCanReachRelayServer,
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
