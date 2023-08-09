//
//  User.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 1.08.2023.
//

import Foundation

struct RegisterModel : Codable{
    let username: String
    let email : String
    let password: String
    let firstName: String
    let lastName: String
    let age: String
    let gender: String
}
