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
    var userId : Int
    var selectedForCell: Bool? = false
}

struct FetchUsersModel : Codable {
    let userId: Int
    let username: String
    let status: String
    let lastMsg : String
    let url: String
    var selectedForCell: Bool? = false
}
