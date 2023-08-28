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
    
    var isAnyRaceAvailable = false
    
    var displayLink: CADisplayLink?
    var elapsedSeconds: Int = 0
    var startTime: CFTimeInterval = 0.0
    var countdownValue: Int = 100
    
    var raceOwnerId: Int?
    
    init(userModels: [GroupEventModel], isAnyRaceAvailable: Bool,countdownValue : Int,raceOwnerId : Int?) {
        self.userModels = userModels
        self.isAnyRaceAvailable = isAnyRaceAvailable
        self.countdownValue = countdownValue
        self.raceOwnerId = raceOwnerId
        print("RACE17,: CREATING RACEHANDLER")
    }
    
    var totalTopUsersPoints : Int {
        return userModels.reduce(0, { $0 + $1.itemCount })
    }

    func topUsersNotEqualToPrevious(userContainers: [UserConatiner]) -> Bool {
        return Set(userContainers.map { $0.userId }) != Set(userModels.map { $0.userId })
    }
    
    func shouldCreateNewCircle(_ userCircles: [UserConatiner], userId: Int) -> Bool {
        return userCircles.count <= 2 &&
                userId != 0 &&
                userId != -1 &&
                !userCircles.contains(where: {$0.userId == userId})
    }
    
    
    func shouldUpdateUserCircleWith(userCircles: [UserConatiner] ,user: GroupEventModel) -> Bool{
        guard let existedUserIndex = userCircles.firstIndex(where: {$0.userId == user.userId}) else {return false}
        userCircles[existedUserIndex].itemCount = user.itemCount
        userCircles[existedUserIndex].updateItemCount(user: user)
        return true
    }
    
    
    var isGroupOwner : Bool {
        return Int(AppConfig.instance.currentUserId ?? "") == raceOwnerId
    }
    
    var maximumCirclesCount: Int {
        return 3
    }
    
    var isCurrentUserInTopUsersList : Bool {
        guard let currentUserId = Int(AppConfig.instance.currentUserId ?? "") else { return false }
        return userModels.contains(where: { $0.userId == currentUserId })
    }
    
    func removeAndUpdateUser(userContainers: [UserConatiner]) -> (userToRemove: UserConatiner?, userToAdd: GroupEventModel?) {
        let userToRemove = userContainers.first(where: { container in
            !userModels.contains(where: { $0.userId == container.userId })
        })

        let userToAdd = userModels.first(where: { userModel in
            !userContainers.contains(where: { $0.userId == userModel.userId })
        })

        if userModels.count == maximumCirclesCount, let userToRemoveId = userToRemove?.userId, userToRemoveId == Int(AppConfig.instance.currentUserId ?? "")! {
            return (userToRemove, userToAdd)
        } else {
            return (userToRemove, userToAdd)
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
    
//    func getCurrentUserModel(groupId: Int) -> GroupEventModel? {
//        if let currentUserId = Int(AppConfig.instance.currentUserId ?? "") {
//            if let existingUserModel = userModels.first(where: { $0.userId == currentUserId }) {
//                return existingUserModel
//            } else {
//                return GroupEventModel(userId: currentUserId, itemCount: 0, groupId: groupId,carId: 4)
//            }
//        }
//        return nil
//    }
    
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
