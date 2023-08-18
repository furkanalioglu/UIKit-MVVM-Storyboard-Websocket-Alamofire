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
