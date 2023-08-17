//
//  RaceHandler.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 15.08.2023.
//

import Foundation
import UIKit

class RaceHandler {
    
    var userModels : [GroupEventModel] = []
    var previousTopUsers : [GroupEventModel] = []
    
    var isAnyRaceAvailable = false
    var timerValue = 100 // Change it to user's selected value later
    
    init(userModels: [GroupEventModel], isAnyRaceAvailable: Bool, timerValue: Int) {
        self.userModels = userModels
        self.isAnyRaceAvailable = isAnyRaceAvailable
        self.timerValue = timerValue
    }
    
    init() {
        
    }
    
    var topUsers : [GroupEventModel] {
        let topUsersSliced = userModels.sorted(by: { $0.itemCount > $1.itemCount }).prefix(3)
        return Array(topUsersSliced)
    }
    
    var totalTopUsersPoints : Int {
        return topUsers.reduce(0, { $0 + $1.itemCount })
    }
    
    var topUsersNotEqualToPrevious : Bool {
        return Set(previousTopUsers.map { $0.userId }) != Set(topUsers.map { $0.userId })
    }
    
    func removeAndUpdateUser() -> (userToRemove: GroupEventModel?, userToAdd: GroupEventModel?) {
        let userToRemove = previousTopUsers.first(where: { !topUsers.contains($0) })
        let userToAdd = topUsers.first(where: { !previousTopUsers.contains($0) })
        return (userToRemove,userToAdd)
    }
    
    func shouldGenerateNewUserCircle(for newUser: GroupEventModel?) -> Bool {
        if let newUser = newUser {
            return newUser.userId != Int(AppConfig.instance.currentUserId ?? "")
        }
        return false
    }
    
    

}
