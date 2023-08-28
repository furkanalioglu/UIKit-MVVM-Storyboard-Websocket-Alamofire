//
//  ItemCountAck.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 28.08.2023.
//

import Foundation

struct ItemCountAck : Codable {
    let itemCount : Int?
    let payloadDate: String?
    let receiverId : Int?
}
