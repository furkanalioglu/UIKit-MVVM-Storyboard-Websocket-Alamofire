//
//  RaceHandler.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 15.08.2023.
//

import Foundation
import UIKit

protocol RaceHandlerProtocol : AnyObject {
    func timerDidChange(value: Int)
    func timerDidCompleted()
}

class RaceHandler {
    
    weak var delegate: RaceHandlerProtocol?
    
    var userModels : [GroupEventModel] = []
    var previousTopUsers : [GroupEventModel] = []
    
    var isAnyRaceAvailable = false
    
    var displayLink: CADisplayLink?
    var elapsedSeconds: Int = 0
    var startTime: CFTimeInterval = 0.0
    var countdownValue: Int = 100
    
    init(userModels: [GroupEventModel], isAnyRaceAvailable: Bool,countdownValue : Int) {
        self.userModels = userModels
        self.isAnyRaceAvailable = isAnyRaceAvailable
        self.countdownValue = countdownValue
        print("RACE17,: CREATING RACEHANDLER")
    }
    
    var topUsers : [GroupEventModel] {
        let topUsersSliced = userModels.sorted(by: { $0.itemCount > $1.itemCount }).prefix(4)
        return Array(topUsersSliced)
    }
    
    var totalTopUsersPoints: Int {
        var total = topUsers.reduce(0, { $0 + $1.itemCount })
        // Check if the current user is NOT in the top users list but exists in the userModels.
//        if let currentUserId = Int(AppConfig.instance.currentUserId ?? ""),
//           !topUsers.contains(where: { $0.userId == currentUserId }),
//           let currentUser = userModels.first(where: { $0.userId == currentUserId }) {
//        } else if let currentUserId = Int(AppConfig.instance.currentUserId ?? ""),
//                  topUsers.contains(where: { $0.userId == currentUserId }) {
//            if let currentUser = userModels.first(where: { $0.userId == currentUserId }) {
//                total += currentUser.itemCount
//            }
//        }
        return total
    }
    
    var topUsersNotEqualToPrevious : Bool {
        return Set(previousTopUsers.map { $0.userId }) != Set(topUsers.map { $0.userId })
    }
    
    func removeAndUpdateUser() -> (userToRemove: GroupEventModel?, userToAdd: GroupEventModel?) {
        let userToRemove = previousTopUsers.first(where: { !topUsers.contains($0)})
        let userToAdd = topUsers.first(where: { !previousTopUsers.contains($0) })
        if topUsers.count == 4  && userToRemove?.userId == Int(AppConfig.instance.currentUserId ?? "")!{
            return(topUsers[2],userToAdd)
        }else{
            return (userToRemove,userToAdd)
        }
    }
    
    
    func startTimer() {
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
        displayLink?.add(to: .current, forMode: .default)
        startTime = CACurrentMediaTime()
        
    }
    
    func stopTimer() {
        displayLink?.invalidate()
        displayLink = nil
        delegate?.timerDidCompleted()
    }
    
    func getCurrentUserModel(groupId: Int) -> GroupEventModel? {
        if let currentUserId = Int(AppConfig.instance.currentUserId ?? "") {
            if let existingUserModel = userModels.first(where: { $0.userId == currentUserId }) {
                return existingUserModel
            } else {
                return GroupEventModel(userId: currentUserId, itemCount: 0, groupId: groupId)
            }
        }
        return nil
    }
    
    @objc private func handleDisplayLink() {
        let elapsed = CACurrentMediaTime() - startTime
        
        if elapsed >= 1.0 {
            DispatchQueue.main.async {
                self.countdownValue -= 1
                self.delegate?.timerDidChange(value: self.countdownValue)
            }
            
            startTime = CACurrentMediaTime()
            
            if countdownValue <= 0 {
                stopTimer()
                delegate?.timerDidCompleted()
            }
        }
    }
}
