//
//  GroupEventModel.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 15.08.2023.
//

import Foundation

struct GroupEventModel : Codable, Hashable {
    let userId : Int
    var itemCount : Int
    let groupId: Int
    var carId : Int
}

struct GroupEventModelArray : Codable {
    let Array: [GroupEventModel]
//    let client: GroupEventModel
}

//MARK: - DELETE - DELETEDELETEDEELTE
extension GroupEventModel{
    static func == (lhs: GroupEventModel, rhs: GroupEventModel) -> Bool {
        return lhs.userId == rhs.userId
    }
}
