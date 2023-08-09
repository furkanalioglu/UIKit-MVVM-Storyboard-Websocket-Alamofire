//
//  LoginModel.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 1.08.2023.
//

import Foundation

struct LoginData : Codable {
    let accessToken: String
    let refreshToken: String
    let userId: Int
}

struct LoginModel : Codable {
    let username: String
    let password: String
    var pushToken : String
}
