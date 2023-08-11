//
//  MessagesCellItem.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 4.08.2023.
//

import Foundation

struct MessagesCellItem: Codable {
    let id : Int
    let username :String
    let status: String
    let url: String
    var lastMsg: String
    var sendTime : String?
    var isSeen : Bool?
    var selectedForCell: Bool? = false
    
    
}
