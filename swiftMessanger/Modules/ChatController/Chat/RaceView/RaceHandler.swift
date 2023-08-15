//
//  RaceHandler.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 15.08.2023.
//

import Foundation
import UIKit

class RaceLogicHandler {
    
    var users: [UserModel]?
    var raceDuration : TimeInterval?
    private var elapsedTime : TimeInterval = 0
    private var userProgress : [Int: Float] = [:]
    private var timer: Timer?
    
    init(users: [UserModel],raceDuration : TimeInterval) {
        self.users = users
        self.raceDuration = raceDuration
        for user in users {
            userProgress[user.id] = 0
        }
    }
    
    func userSentMessage(userId: Int) {
        userProgress[userId] = min(1.0, (userProgress[userId] ?? 0) + 0.1)
    }
    
    func startRace(completion: @escaping(Int,Float) -> Void) {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            self.elapsedTime += 1
            
            let progressPerSecond = 1.0 / Float(self.raceDuration!)
            for (userId, progress) in self.userProgress {
                self.userProgress[userId] = min(1.0, progress + progressPerSecond)
                completion(userId, self.userProgress[userId] ?? 0)
            }
            
            if self.elapsedTime >= self.raceDuration! {
                self.stopRace()
            }
        })
    }
    
    func stopRace() {
        timer?.invalidate()
    }
    
    func getProgressForUser(userId: Int) -> Float {
        return userProgress[userId] ?? 0
    }
}
