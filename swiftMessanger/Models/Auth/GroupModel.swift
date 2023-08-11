//
//  GroupModel.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 11.08.2023.
//

import Foundation

struct GroupCell : Codable {
    let id : Int
    let groupName : String
    let url : String
    let sendTime: String
    let lastMsg: String
}

