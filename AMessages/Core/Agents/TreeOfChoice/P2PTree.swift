// Trees+P2P
// Placeholder za stablo koje će se baviti P2P handshakeom i fallbackom na relay.

import Foundation

extension DecisionTree {
    static func p2pTree() -> DecisionTree {
        let nodes: [String: TreeNode] = [
            "root": TreeNode(
                id: "root",
                functionId: .checkP2PHandshake,
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
