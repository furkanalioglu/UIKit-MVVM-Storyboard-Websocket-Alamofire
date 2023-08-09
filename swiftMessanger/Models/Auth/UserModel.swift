//
//  UserModel.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 1.08.2023.
//

import Foundation

class UserModel : Codable{
    let id: Int
    let username: String
    let status: String
    let url: String
    let lastMsg: String
}
