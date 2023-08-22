//
//  RaceView.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 15.08.2023.
//
import UIKit

class RaceView: UIView {
    var userCircles: [UserConatiner] = []
    var flagView: UIImageView!
    var timerLabel = UILabel()
    var handler : RaceHandler?
    var groupId: Int?
    var avaibleCars = [0,1,2,3]
    
    
    init(frame: CGRect, handler: RaceHandler,groupId: Int) {
        super.init(frame: frame)
        self.handler = handler
        self.groupId = groupId
        setupFlag()
        road()
        setupTimer()
        handler.delegate = self
        print("refreshing view")
        backgroundColor = .clear
        generateUserCircleInTopList(groupId: groupId)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupFlag() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let flagImage = UIImage(systemName: "flag")
           flagView = UIImageView(image: flagImage)
           addSubview(flagView)
           flagView.setDimensions(height: 20, width: 20)
           flagView.tintColor = .black
           flagView.anchor(bottom:bottomAnchor,right: rightAnchor, paddingBottom: 5,paddingRight: 0)
        }
    }

    private func setupTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            timerLabel.font = UIFont.systemFont(ofSize: 12)
            timerLabel.textColor = .black
            addSubview(timerLabel)
            timerLabel.anchor(top: topAnchor, right: rightAnchor,paddingRight: 8)
        }
    }

    private func road() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let road = UIView()
            addSubview(road)
            road.backgroundColor = .black
            road.setDimensions(height: 5,width:  UIScreen.main.bounds.width)
            road.anchor(left: leftAnchor,bottom: bottomAnchor,right: rightAnchor,paddingBottom: 1)
        }
    }
    
    func updateUserCircles(newUser: GroupEventModel?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let handler = handler else { return }
            let totalPoints = handler.totalTopUsersPoints
            
            if handler.userModels.count <= 4,
               let user = newUser {
                generateNewUserCircle(withUserModel: user,passedBy: nil)
                moveUserCircles(topUsers: handler.topUsers, totalPoints: totalPoints)
                
                return
            }
            
            if handler.topUsersNotEqualToPrevious {
                let updatedTopUsersInfo = handler.removeAndUpdateUser()
                if let userToRemove = updatedTopUsersInfo.userToRemove,
                   let circleToRemove = userCircles.first(where: { $0.userId == userToRemove.userId }),
                   let userToAdd = updatedTopUsersInfo.userToAdd{
                    let removedIndex = userCircles.firstIndex(where: {$0.userId == userToRemove.userId})!
                    let removedCarId = userCircles[removedIndex].carId
                        circleToRemove.removeFromSuperview()
                        userCircles.removeAll(where: { $0.userId == userToRemove.userId })
                        generateNewUserCircle(withUserModel: userToAdd, passedBy: removedCarId)


                        moveUserCircles(topUsers: handler.topUsers, totalPoints: totalPoints)
                }
            }else{
                self.moveUserCircles(topUsers: handler.topUsers, totalPoints: totalPoints)
            }
            handler.previousTopUsers = handler.topUsers
        }
    }
    
    
    func generateNewUserCircle(withUserModel userModel: GroupEventModel, passedBy fourthUserCarId :Int?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let handler = handler else { return }
            let newCircle = UserConatiner(frame: CGRect(x: 0, y: 0, width: 300, height: 100), videoResourceName: "framelights1")
            addSubview(newCircle)

            if fourthUserCarId == nil {
                newCircle.carId = userCircles.count ?? 0
            }else{
                newCircle.carId = fourthUserCarId!
            }
            userCircles.append(newCircle)
            layoutIfNeeded()
            let leadingConstraint = newCircle.leadingAnchor.constraint(equalTo: leadingAnchor)
            leadingConstraint.isActive = true
            newCircle.leadingConstraing = leadingConstraint
            newCircle.anchor(bottom: bottomAnchor)
            newCircle.configure(user: userModel)
            moveUserCircles(topUsers: handler.topUsers, totalPoints: handler.totalTopUsersPoints)
        }

    }
    
    func generateUserCircleInTopList(groupId: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let handler = handler else { return }
            for user in handler.topUsers {
                print("*-*-*-TOPUSERS:",handler.topUsers)
                if userCircles.first(where: {$0.userId == user.userId}) == nil{
                    print("*-*-*- GENERATINBG USER CIRCLE FOR \(user.userId) with \(user.itemCount)")
                    generateNewUserCircle(withUserModel: user,passedBy: nil)
                }
            }
        }


    }
    
    func moveUserCircles(topUsers: [GroupEventModel], totalPoints: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            debugPrint("current_frame", self.frame.width, UIScreen.main.bounds.size.width )
            print("*-*-*-\(totalPoints)")
            let roadWidth = self.frame.width - 50 // This represents 100%
            
            
            for user in topUsers {
                guard let circle = self.userCircles.first(where: { $0.userId == user.userId }) else { continue }
                debugPrint(user.itemCount, "to position")
                let userPercentageOfTotal = CGFloat(user.itemCount) / CGFloat(totalPoints)
                debugPrint(userPercentageOfTotal, "to position")
                let estimatedXPosition = (userPercentageOfTotal * roadWidth) - (circle.frame.width / 2)
                debugPrint(estimatedXPosition, "to position", roadWidth, circle.frame.width)
                let clampedXPosition = max(circle.frame.width / 2, min(estimatedXPosition, roadWidth - circle.frame.width / 2))
                
                circle.leadingConstraing?.constant = clampedXPosition
                
                print(" \(user.userId) to position \(clampedXPosition)")
                UIView.animate(withDuration: 0.5) {
                    self.layoutIfNeeded()
                }
            
            }
        }
    }
    
    
    
}

//Timer Delegate
extension RaceView : RaceHandlerProtocol{
    func timerDidChange(value: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.timerLabel.text = String(value)
        }
    }

    func timerDidCompleted() {
        DispatchQueue.main.async { [weak self] in
            self?.timerLabel.text = "0"
        }
    }
    
    func selectAndReturnRandomNumber(array: [Int]) -> Int {
        let randomIndex = Int.random(in: 0..<array.count)
        let selectedNumber = array[randomIndex]
        print("Cardebug: selected number\(selectedNumber), from array \(array)")
        return selectedNumber
    }
    
}

