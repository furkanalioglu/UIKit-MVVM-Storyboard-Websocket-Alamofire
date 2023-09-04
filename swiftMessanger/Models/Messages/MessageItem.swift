//
//  MessageItem.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 3.08.2023.
//

import Foundation

struct MessageItem: Codable{
    let message : String
    let senderId : Int
    let receiverId: Int
    let sendTime : String
    let type: String
    
    var imageData: Data?
}


struct ChatACKModel : Codable {
    let receiverId: Int
    let payloadDate: String
}


