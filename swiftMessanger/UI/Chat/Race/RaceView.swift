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
    var flagView: UIImageView!
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
    
    private var lottieAnimationView: LottieAnimationView = {
        let animationView = LottieAnimationView(name: "data")
        animationView.loopMode = .loop
        animationView.contentMode = .scaleAspectFill
        return animationView
    }()
    
    private lazy var  ghostCarView : UserConatiner =  {
        let view = UserConatiner(frame: CGRect(x: 0, y:lottieAnimationView.center.y - 50, width: 100, height: 50))
        return view
    }()
    
    func updateUserCircles(newUsers: GroupEventModelArray?) {
        guard let handler = handler else { return }
        guard let newUsers = newUsers else { return }

        handler.userModels = newUsers.Array
            for user in newUsers.Array {
                if handler.topUsersNotEqualToPrevious(userContainers: userCircles) && handler.userModels.count == 3{
                    let updatedTopUsersInfo = handler.removeAndUpdateUser(userContainers: userCircles)
                    if let circleToRemove = updatedTopUsersInfo.userToRemove,
                       let userToAdd = updatedTopUsersInfo.userToAdd
                       {
                        if circleToRemove.userId == ghostCarView.userId {
                            ghostCarView.isHidden = false
                        }
//                        if userToAdd.userId == ghostCarView.userId {
//                            ghostCarView.isHidden = true
//                        }
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            circleToRemove.removeFromSuperview()
                            self.layoutIfNeeded()
                        }
                            userCircles.removeAll(where: { $0.userId == circleToRemove.userId })
                            generateNewUserCircle(withUserModel: userToAdd)
                            moveUserCircles(topUsers: handler.userModels)
                        return
                    }
                }
                if userCircles.count <= 2,
                   user.userId != 0,
                    user.userId != -1
                    {
                    if userCircles.contains(where: {$0.userId == user.userId}) {
                        
                    }else{
                        generateNewUserCircle(withUserModel: user)
                    }
                }
                guard let index = userCircles.firstIndex(where: {$0.userId == user.userId}) else { return }
                userCircles[index].itemCount = user.itemCount
                userCircles[index].updateItemCount(user: user)
                moveUserCircles(topUsers: handler.userModels)
            }
            moveUserCircles(topUsers: handler.userModels)

    }
    
    
    func generateNewUserCircle(withUserModel userModel: GroupEventModel) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let handler = handler else { return }
            let newCircle = UserConatiner(frame: CGRect(x: 0, y:lottieAnimationView.center.y - 50, width: 100, height: 50))
            addSubview(newCircle)
            if userModel.userId == ghostCarView.userId{
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self = self else {return}
                    ghostCarView.isHidden = true
                }
            }
            let leadingConstraint = newCircle.leadingAnchor.constraint(equalTo: leadingAnchor)
            leadingConstraint.isActive = true
            newCircle.leadingConstraing = leadingConstraint
            newCircle.configure(user: userModel)
            userCircles.append(newCircle)
            print("*-*-*-Created circle with \(newCircle)")
            moveUserCircles(topUsers: handler.userModels)
        }
    }
    
    func generateUserCircleInTopList(groupId: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
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
    }
    
    func configureRoadUI() {
        DispatchQueue.main.async {
            [weak self ] in
            guard let self = self else { return }
            addSubview(lottieAnimationView)
            lottieAnimationView.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor)
            lottieAnimationView.setHeight(40)
            playLottieAnimation()
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
            ghostCarView.isHidden = handler.isGroupOwner
            layoutIfNeeded()
        }
    }
    
    
    func moveUserCircles(topUsers: [GroupEventModel]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let roadWidth: CGFloat = self.frame.width - 40
            let invisibleWall = roadWidth * 0.20
            let usableRoadWidth = roadWidth * 0.80
            
            guard let totalPoints = handler?.totalTopUsersPoints else { return }
            
            guard totalPoints != 0 else { return }
            
            for user in topUsers {
                guard let circle = self.userCircles.first(where: { $0.userId == user.userId }) else { continue }
                circle.anchor(bottom: self.lottieAnimationView.centerYAnchor)
                let userPercentageOfTotal = CGFloat(user.itemCount) / CGFloat(totalPoints)
                let estimatedXPosition = invisibleWall + (usableRoadWidth * userPercentageOfTotal)
        
                circle.leadingConstraing?.constant = estimatedXPosition - (circle.frame.width / 2)  // This accounts for the width of the car to center it
                
//                if user.userId == ghostCarView.userId && estimatedXPosition >= ghostCarView.frame.minX {
//                    ghostCarView.isHidden = true
//                }
                
                UIView.animate(withDuration: 0.5) {
                    self.layoutIfNeeded()
                }
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

