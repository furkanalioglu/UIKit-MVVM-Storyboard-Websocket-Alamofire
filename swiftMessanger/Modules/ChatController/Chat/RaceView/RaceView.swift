//
//  RaceView.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 15.08.2023.
//
import UIKit

class RaceView: UIView {
    var userModels: [GroupEventModel] = []
    var previousTopUsers : [GroupEventModel] = []
    
    var userCircles: [UserCircle] = []
    var flagView: UIImageView!
    
    var totalPoints = 1
    
    var raceTimer : Timer?
    var countdownValue: Int = 100

    var timerLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupFlag()
        road()
        setupTimer()
        
        backgroundColor = .systemGray
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
        let topUsersSlice = userModels.sorted(by: { $0.itemCount > $1.itemCount }).prefix(3)
        let topUsers: [GroupEventModel] = Array(topUsersSlice)
        totalPoints = topUsers.reduce(0, { $0 + $1.itemCount })
        
        if userModels.count <= 3 {
            if let newUser = newUser {
                generateNewUserCircle(withUserModel: newUser)
            }
            moveUserCircles(topUsers: topUsers, totalPoints: totalPoints)
            return
        }
        
        if Set(previousTopUsers.map { $0.userId }) != Set(topUsers.map { $0.userId }) {
            if let userToRemove = previousTopUsers.first(where: { !topUsers.contains($0) }),
               let circleToRemove = userCircles.first(where: { $0.userId == userToRemove.userId }) {
                
                circleToRemove.removeFromSuperview()
                userCircles.removeAll(where: { $0.userId == userToRemove.userId })
                
                if let newUser = topUsers.first(where: { !previousTopUsers.contains($0) }) {
                    generateNewUserCircle(withUserModel: newUser)
                }
            }
        }
        
    moveUserCircles(topUsers: topUsers, totalPoints: totalPoints)
    previousTopUsers = topUsers
    }
    
    func moveUserCircles(topUsers: [GroupEventModel], totalPoints: Int) {
        guard totalPoints > 0 else { return }

        let roadWidth = self.bounds.width - 50 // This represents 100%

        for user in topUsers {
            guard let circle = userCircles.first(where: { $0.userId == user.userId }) else { continue }
            
            let userPercentageOfTotal = CGFloat(user.itemCount) / CGFloat(totalPoints)
            
            let estimatedXPosition = (userPercentageOfTotal * roadWidth) - (circle.frame.width / 2)
            
            let clampedXPosition = max(circle.frame.width / 2, min(estimatedXPosition, roadWidth - circle.frame.width / 2))
            
            UIView.animate(withDuration: 0.5) {
                circle.frame.origin.x = clampedXPosition
                self.layoutIfNeeded()
            }
        }
    }
    
    
    func generateNewUserCircle(withUserModel userModel: GroupEventModel) {
        let newCircle = UserCircle()
        newCircle.configure(withUser: userModel)
        addSubview(newCircle)
        newCircle.anchor(bottom: bottomAnchor, right: rightAnchor,paddingRight: 50)
        newCircle.setWidth(30)
        newCircle.setHeight(30)
        userCircles.append(newCircle)
        newCircle.layoutIfNeeded()
        newCircle.makeCircle()
    }
    
    func startTimer() {
        timerLabel.text = "\(countdownValue)"
        raceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let strongSelf = self else { return }
            
            strongSelf.countdownValue -= 1
            strongSelf.timerLabel.text = "\(strongSelf.countdownValue)"
            
            if strongSelf.countdownValue <= 0 {
                strongSelf.removeFromSuperview()
            }
        }
    }
}

class UserCircle: UIView {
    
    var userId: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let userIdLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    func makeCircle() {
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.masksToBounds = true
    }
    
    func configure(withUser user: GroupEventModel) {
        userIdLabel.text = String(user.userId)
        backgroundColor = .random
        userId = user.userId
        makeCircle()
    }
    
    private func setupView() {
        self.backgroundColor = .random
        addSubview(userIdLabel)
        userIdLabel.centerX(inView: self)
        userIdLabel.centerY(inView: self)
    }
    
}
