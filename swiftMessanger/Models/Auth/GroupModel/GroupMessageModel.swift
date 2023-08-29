//
//  GroupMessageModel.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 15.08.2023.
//

import Foundation

struct GroupMessageModel : Codable{
    let messages : [MessageItem]
    let users : [UserModel]
    let race : [GroupEventModel]
    let userItemCount : Int
    let timeLeft : Int
}
