//
//  CurrentUserModel.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 1.08.2023.
//

import Foundation


struct CurrentUserModel: Codable {
    
    var username: String
    var firstName: String
    var lastName: String
    var age: String
    var gender: String
    var status: String
    var photoUrl: String
    
}

