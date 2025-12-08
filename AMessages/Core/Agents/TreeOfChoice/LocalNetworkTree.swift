// Trees+LocalNetwork
// Placeholder za stablo odluka koje će se baviti LAN / ARP / gateway dijagnostikom.

import Foundation

extension DecisionTree {
    static func localNetworkTree() -> DecisionTree {
        let nodes: [String: TreeNode] = [
            "root": TreeNode(
                id: "root",
                functionId: .checkCanReachGateway,
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
