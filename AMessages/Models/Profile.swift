//
//  Profile.swift
//  AMessages
//
//  Created by Toma Babić on 25.11.2025..
//

import Foundation

struct Profile: Codable {
    let userId: String
    let publicKey: Data
    let encryptedPrivateKey: Data

    static func demo() -> Profile {
        Profile(
            userId: "demo-user",
            publicKey: Data(),
            encryptedPrivateKey: Data()
        )
    }
}
