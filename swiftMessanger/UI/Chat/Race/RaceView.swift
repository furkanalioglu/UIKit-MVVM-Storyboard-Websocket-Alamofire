//
//  RaceView.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 15.08.2023.
//
import UIKit
import AVFoundation
import Lottie

class RaceView: UIView {
    var userCircles: [UserConatiner] = []
    var timerLabel = UILabel()
    var handler : RaceHandler?
    var groupId: Int?

    
    private var playerLooper:  AVPlayerLooper?
    private var playerLayer : AVPlayerLayer?
    private var queuePlayer : AVQueuePlayer?
    
    
    init(frame: CGRect, handler: RaceHandler,groupId: Int) {
        super.init (frame: frame)
        self.handler = handler
        self.groupId = groupId
        configureRoadUI()
        configureGhostCarUI()
        configureFlagUI()
        generateUserCircleInTopList(groupId: groupId)
        playLottieAnimation()
        setupTimer()
        handler.delegate = self
        print("refreshing view")
        backgroundColor = .clear
        print("RACE VIEW 11 CREATED")
    } 
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("RACE VIEW 11 DELETED")
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
    
    var lottieAnimationView: LottieAnimationView = {
        let animationView = LottieAnimationView(name: "data2")
        animationView.loopMode = .loop
        animationView.contentMode = .scaleAspectFill
        return animationView
    }()
    
    var ghostCarView : UserConatiner =  {
        let view = UserConatiner()
        view.setWidth(100)
        view.setHeight(100)
        return view
    }()
    
    var flagView : UIImageView =  {
        let flagView = UIImageView()
        flagView.image = UIImage(named: "flag")
        flagView.contentMode = .scaleAspectFill
        return flagView
    }()
    
    func updateUserCircles(newUsers: GroupEventModelArray?) {
        guard let handler = handler else { return }
        guard let newUsers = newUsers else { return }
        
        handler.userModels = newUsers.Array
        print("**********")
        for user in newUsers.Array {
            if handler.shouldCreateNewCircle(userCircles, userId: user.userId) {
                let newCircle = UserConatiner()
                userCircles.append(newCircle)
                generateNewUserCircle(withUserModel: user,newCircle: newCircle)
            }
            
            if handler.topUsersNotEqualToPrevious(userContainers: userCircles) && handler.userModels.count == 3{
                let updatedTopUsersInfo = handler.removeAndUpdateUser(userContainers: userCircles)
                if let circleToRemove = updatedTopUsersInfo.userToRemove{
                    if circleToRemove.userId == ghostCarView.userId {
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            ghostCarView.isHidden = false
                        }
                    }
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        circleToRemove.removeFromSuperview()
                        self.layoutIfNeeded()
                    }
                    userCircles.removeAll(where: { $0.userId == circleToRemove.userId })
                    moveUserCircles(topUsers: handler.userModels)
                }
            }
            if handler.shouldUpdateUserCircleWith(userCircles: userCircles, user: user) {
                moveUserCircles(topUsers: handler.userModels)
            }
        }
        print("USERCIRCLECOUNT \(userCircles.count)")
        for user in userCircles {
            print("USERCIRCLEINFO \(user.userId)")
            print("USERCIRCLEINFO \(user.itemCount)")
        }
        moveUserCircles(topUsers: handler.userModels)
    }
    
    
    func generateNewUserCircle(withUserModel userModel: GroupEventModel, newCircle: UserConatiner) {
        guard let handler = handler else { return }

        newCircle.configure(user: userModel)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            newCircle.setWidth(35)
            newCircle.setHeight(75)
            addSubview(newCircle)

            if userModel.userId == ghostCarView.userId{
                ghostCarView.isHidden = true
            }

            let bottomConstraint = newCircle.bottomAnchor.constraint(equalTo: bottomAnchor)
            let leadingConstraint = newCircle.leadingAnchor.constraint(equalTo: leadingAnchor)
            leadingConstraint.isActive = true
            bottomConstraint.isActive = true
            newCircle.leadingConstraing = leadingConstraint
            newCircle.bottomConstraing = bottomConstraint
            layoutIfNeeded()
        }
        moveUserCircles(topUsers: handler.userModels)
    }
    
    func generateUserCircleInTopList(groupId: Int) {
        guard let handler = handler else { return }
        for user in handler.userModels{
            print("*-*-*-TOPUSERS:",handler.userModels)
            if userCircles.first(where: {$0.userId == user.userId}) == nil,
               user.userId != 0,
               user.userId != -1{
                let newCircle = UserConatiner()
                userCircles.append(newCircle)
                generateNewUserCircle(withUserModel: user,newCircle: newCircle)
                print("*-*-*- GENERATINBG USER CIRCLE FOR \(user.userId) with \(user.itemCount)")
            }
        }
    }
    
    func configureRoadUI() {
        DispatchQueue.main.async {
            [weak self ] in
            guard let self = self else { return }
            addSubview(lottieAnimationView)
            lottieAnimationView.setHeight(40)
            lottieAnimationView.anchor(bottom: bottomAnchor)
            playLottieAnimation()
        }
    }
    
    func configureFlagUI() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            addSubview(flagView)
            flagView.anchor(bottom:bottomAnchor,right: rightAnchor)
            flagView.setWidth(20)
            flagView.setHeight(40)
            lottieAnimationView.anchor(bottom: bottomAnchor,right: flagView.leftAnchor)
            layoutIfNeeded()
        }
    }
    
    func configureGhostCarUI() {
        guard let currenUid = Int(AppConfig.instance.currentUserId ?? "") else { return }
        guard let groupId = groupId else { return }
        guard let handler = handler else { return }
        let myUser = GroupEventModel(userId: currenUid, itemCount: 0, groupId: groupId, carId: 4)
        let leadingConstraint = ghostCarView.leadingAnchor.constraint(equalTo: leadingAnchor,constant: 12)
        ghostCarView.configure(user: myUser)
        layoutIfNeeded()

        DispatchQueue.main.async {
            [weak self] in
            guard let self = self else { return }
            addSubview(ghostCarView)
            ghostCarView.anchor(bottom: bottomAnchor)
            ghostCarView.isHidden = !handler.shouldCreateGhostCar
            ghostCarView.leadingConstraing = leadingConstraint
            leadingConstraint.isActive = true
            ghostCarView.setWidth(35)
            ghostCarView.setHeight(75)
            layoutIfNeeded()
        }
    }
    
    
    func moveUserCircles(topUsers: [GroupEventModel]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let roadWidth: CGFloat = self.frame.width - 70
            let invisibleWall = roadWidth * 0.20
            let usableRoadWidth = roadWidth * 0.80
            let verticalOffsetForIndex0And2 = roadWidth * 0.05
            let verticalOffsetForIndex1 = roadWidth * 0.025
            
            guard let totalPoints = handler?.totalTopUsersPoints, totalPoints != 0 else { return }
            
            for (index, user) in topUsers.enumerated() {
                guard let circle = self.userCircles.first(where: { $0.userId == user.userId }) else { continue }
                if index == 0 || index == 2 {
                    circle.bottomConstraing?.constant = -verticalOffsetForIndex0And2
                    print("Fireddd")
                }else{
                    circle.bottomConstraing?.constant = verticalOffsetForIndex1
                    circle.layer.zPosition = 1

                    print("Fireddd2")
                }
                let userPercentageOfTotal = CGFloat(user.itemCount) / CGFloat(totalPoints)
                let estimatedXPosition = invisibleWall + (usableRoadWidth * userPercentageOfTotal)
                circle.leadingConstraing?.constant = estimatedXPosition - (circle.frame.width / 2)
            }
            
            UIView.animate(withDuration: 0.5) {
                self.layoutIfNeeded()
            }
        }
    }
    
    
    private func playLottieAnimation() {
        lottieAnimationView.play()
    }
    
    func removeAllCircles() {
        for user in userCircles{
            user.userCircle.carAnimationManager.removePlayerView()
            user.removeFromSuperview()
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


extension UIView {
    func subviews<T: UIView>(ofType WhatType: T.Type) -> [T] {
        var result = self.subviews.compactMap { $0 as? T }
        for sub in self.subviews {
            result.append(contentsOf: sub.subviews(ofType: WhatType))
        }
        return result
    }
}

