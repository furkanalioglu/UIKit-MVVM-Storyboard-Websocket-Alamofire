//
//  RaceView.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 15.08.2023.
//
import UIKit

class RaceView: UIView {
    var userCircles: [UserCircle] = []
    var flagView: UIImageView!
    var timerLabel = UILabel()
    var handler : RaceHandler?
    var groupId: Int?
    
    
    init(frame: CGRect, handler: RaceHandler,groupId: Int) {
        super.init(frame: frame)
        self.handler = handler
        self.groupId = groupId
        setupFlag()
        road()
        setupTimer()
        handler.delegate = self
        print("refreshing view")
        backgroundColor = .systemRed
        generateUserCircleInTopList(groupId: groupId)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupFlag() {
        let flagImage = UIImage(systemName: "flag")
        flagView = UIImageView(image: flagImage)
        addSubview(flagView)
        flagView.setDimensions(height: 20, width: 20)
        flagView.tintColor = .black
        flagView.anchor(bottom:bottomAnchor,right: rightAnchor, paddingBottom: 5,paddingRight: 0)
    }
    
    private func setupTimer() {
        timerLabel.font = UIFont.systemFont(ofSize: 12)
        timerLabel.textColor = .black
        addSubview(timerLabel)
        timerLabel.anchor(top: topAnchor, right: rightAnchor,paddingRight: 8)
    }
    
    private func road() {
        let road = UIView()
        addSubview(road)
        road.backgroundColor = .black
        road.setDimensions(height: 5,width:  400)
        road.anchor(left: leftAnchor,bottom: bottomAnchor,right: rightAnchor,paddingBottom: 1)
    }
    
    func updateUserCircles(newUser: GroupEventModel?) {
        guard let handler = handler else { return }
        var totalPoints = handler.totalTopUsersPoints
        
        if handler.userModels.count <= 4 && newUser != nil{
            generateNewUserCircle(withUserModel: newUser!)
            moveUserCircles(topUsers: handler.topUsers, totalPoints: totalPoints)
            backgroundColor = .green // CREATED
            return
        }
        
        if handler.topUsersNotEqualToPrevious {
            let updatedTopUsersInfo = handler.removeAndUpdateUser()
            if let userToRemove = updatedTopUsersInfo.userToRemove,
               let circleToRemove = userCircles.first(where: { $0.userId == userToRemove.userId }),
               let userToAdd = updatedTopUsersInfo.userToAdd{
                    circleToRemove.removeFromSuperview()
                    userCircles.removeAll(where: { $0.userId == userToRemove.userId })
                    generateNewUserCircle(withUserModel: userToAdd)
                    moveUserCircles(topUsers: handler.topUsers, totalPoints: totalPoints)
                    backgroundColor = .yellow
            }
        }else{
            self.moveUserCircles(topUsers: handler.topUsers, totalPoints: totalPoints)
        }
        print("*0*0*0*0*0")
        dump(userCircles)
        print("*0*0*0*0*0")
        handler.previousTopUsers = handler.topUsers
    }
    
    
    func generateNewUserCircle(withUserModel userModel: GroupEventModel) {
        guard let handler = handler else { return }
        let newCircle = UserCircle()
        addSubview(newCircle)
        userCircles.append(newCircle)
        newCircle.setWidth(30)
        newCircle.setHeight(30)
        newCircle.layoutIfNeeded()
        newCircle.makeCircle()
        
        let leadingConstraint = newCircle.leadingAnchor.constraint(equalTo: self.leadingAnchor)
        leadingConstraint.isActive = true
        newCircle.leadingConstraing = leadingConstraint
        newCircle.anchor(bottom: self.bottomAnchor)
        
        newCircle.configure(withUser: userModel)
        moveUserCircles(topUsers: handler.topUsers, totalPoints: handler.totalTopUsersPoints)
    }
    
    func generateUserCircleInTopList(groupId: Int) {
        guard let handler = handler else { return }
        for user in handler.topUsers {
            if userCircles.first(where: {$0.userId == user.userId}) == nil {
                generateNewUserCircle(withUserModel: user)
            }
        }

    }
    
    func moveUserCircles(topUsers: [GroupEventModel], totalPoints: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            debugPrint("current_frame", self.frame.width, UIScreen.main.bounds.size.width )
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
                //                circle.anchor(bottom: self.bottomAnchor)
                
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
        timerLabel.text = String(value)
        
    }
    
    func timerDidCompleted() {
        timerLabel.text = "0"
        
    }
}

