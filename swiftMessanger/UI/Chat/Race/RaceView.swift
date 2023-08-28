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
        super.init(frame: frame)
        self.handler = handler
        self.groupId = groupId
        configureRoadUI()
        configureGhostCarUI()
        configureFlagUI()
        playLottieAnimation()
        setupTimer()
        handler.delegate = self
        print("refreshing view")
        backgroundColor = .clear
        generateUserCircleInTopList(groupId: groupId)
        
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    private lazy var flagView : UIImageView =  {
        let flagView = UIImageView()
        flagView.image = UIImage(named: "flag")
        flagView.contentMode = .scaleAspectFill
        return flagView
    }()
    
    func updateUserCircles(newUsers: GroupEventModelArray?) {
        guard let handler = handler else { return }
        guard let newUsers = newUsers else { return }

        handler.userModels = newUsers.Array
            for user in newUsers.Array {
                
                if handler.shouldCreateNewCircle(userCircles, userId: user.userId) {
                    generateNewUserCircle(withUserModel: user)
                }
                
                if handler.topUsersNotEqualToPrevious(userContainers: userCircles) && handler.userModels.count == 3{
                    let updatedTopUsersInfo = handler.removeAndUpdateUser(userContainers: userCircles)
                    if let circleToRemove = updatedTopUsersInfo.userToRemove{
                        if circleToRemove.userId == ghostCarView.userId {
                            ghostCarView.isHidden = false
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
            moveUserCircles(topUsers: handler.userModels)

    }
    
    
    func generateNewUserCircle(withUserModel userModel: GroupEventModel) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let handler = handler else { return }
            let newCircle = UserConatiner()
            newCircle.setWidth(35)
            newCircle.setHeight(75)
            addSubview(newCircle)

            if userModel.userId == ghostCarView.userId{
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self = self else {return}
                    ghostCarView.isHidden = true
                }
            }
            let bottomConstraint = newCircle.bottomAnchor.constraint(equalTo: bottomAnchor)
            let leadingConstraint = newCircle.leadingAnchor.constraint(equalTo: leadingAnchor)
            leadingConstraint.isActive = true
            bottomConstraint.isActive = true
            newCircle.leadingConstraing = leadingConstraint
            newCircle.bottomConstraing = bottomConstraint
            newCircle.configure(user: userModel)
            
            
            userCircles.append(newCircle)
            print("*-*-*-Created circle with \(newCircle)")
            moveUserCircles(topUsers: handler.userModels)
        }
    }
    
    func generateUserCircleInTopList(groupId: Int) {
            guard let handler = handler else { return }
            for user in handler.userModels{
                print("*-*-*-TOPUSERS:",handler.userModels)
                if userCircles.first(where: {$0.userId == user.userId}) == nil,
                   user.userId != 0,
                   user.userId != -1{
                    print("*-*-*- GENERATINBG USER CIRCLE FOR \(user.userId) with \(user.itemCount)")
                    generateNewUserCircle(withUserModel: user)
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
        DispatchQueue.main.async {
            [weak self] in
            guard let self = self else { return }
            addSubview(ghostCarView)
            ghostCarView.leadingConstraing = leadingConstraint
            leadingConstraint.isActive = true
            ghostCarView.configure(user: myUser)
            ghostCarView.anchor(bottom: lottieAnimationView.centerYAnchor)
            ghostCarView.setWidth(35)
            ghostCarView.setHeight(75)
            ghostCarView.isHidden = !handler.shouldCreateGhostCar

//            if handler.isGroupOwner {
//                ghostCarView.isHidden = true
//            }else{
//                ghostCarView.isHidden = !handler.shouldCreateGhostCar
//
//            }
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

