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
    
    
    init(frame: CGRect, handler: RaceHandler) {
        super.init(frame: frame)
        self.handler = handler
        setupFlag()
        road()
        setupTimer()
        handler.delegate = self
        print("refreshing view")
        backgroundColor = .systemRed
        generateUserCircleInTopList()
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
        if totalPoints == 0 {
            totalPoints += 1
        }
        
        if handler.userModels.count <= 3  && newUser != nil{
            //            if handler.shouldGenerateNewUserCircle(for: newUser)  {
            generateNewUserCircle(withUserModel: newUser!)
            moveUserCircles(topUsers: handler.topUsers, totalPoints: totalPoints)
            backgroundColor = .green // CREATED
            return
            //            }
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
                backgroundColor = .yellow // CHANGED
                
            }
        }else{
            self.moveUserCircles(topUsers: handler.topUsers, totalPoints: totalPoints)
        }
        handler.previousTopUsers = handler.topUsers
    }
    
    func generateNewUserCircle(withUserModel userModel: GroupEventModel) {
        guard let handler = handler else { return }
        let newCircle = UserCircle()
        newCircle.configure(withUser: userModel)
        addSubview(newCircle)
        newCircle.anchor(left: leftAnchor,bottom: bottomAnchor)
        userCircles.append(newCircle)
        newCircle.setWidth(30)
        newCircle.setHeight(30)
        //        newCircle.layoutIfNeeded()
        newCircle.makeCircle()
        moveUserCircles(topUsers: handler.topUsers, totalPoints: handler.totalTopUsersPoints)
        
    }
    
    func generateUserCircleInTopList() {
        guard let handler = handler else { return }
        let totalPoints = handler.totalTopUsersPoints
        for user in handler.topUsers {
            if userCircles.first(where: {$0.userId == user.userId}) == nil {
                generateNewUserCircle(withUserModel: user)
            }
        }
    }
    
    func moveUserCircles(topUsers: [GroupEventModel], totalPoints: Int) {
        
        debugPrint("current_frame", self.frame.width, UIScreen.main.bounds.size.width )
        let roadWidth = self.frame.width - 50 // This represents 100%
        DispatchQueue.main.async {
            
            for user in topUsers {
                guard let circle = self.userCircles.first(where: { $0.userId == user.userId }) else { continue }
                
                debugPrint(user.itemCount, "to position")
                let userPercentageOfTotal = CGFloat(user.itemCount) / CGFloat(totalPoints)
                debugPrint(userPercentageOfTotal, "to position")
                let estimatedXPosition = (userPercentageOfTotal * roadWidth) - (circle.frame.width / 2)
                debugPrint(estimatedXPosition, "to position", roadWidth, circle.frame.width)
                let clampedXPosition = max(circle.frame.width / 2, min(estimatedXPosition, roadWidth - circle.frame.width / 2))
                print(" \(user.userId) to position \(clampedXPosition)")
                
                UIView.animate(withDuration: 0.5) {
                    circle.frame.origin.x = clampedXPosition
//                    circle.updateLeftAnchor(toConstant: clampedXPosition)
                }
            }
        }
        
    }
}

//Timer Delegate
extension RaceView : RaceHandlerProtocol{
    func timerDidChange(value: Int) {
        //        timerLabel.text = String(value)
        
    }
    
    func timerDidCompleted() {
        timerLabel.text = "0"
        
    }
}

