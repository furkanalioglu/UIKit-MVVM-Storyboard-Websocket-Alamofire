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
                            circleToRemove.removeFromSuperview()
                            userCircles.removeAll(where: { $0.userId == circleToRemove.userId })
                            generateNewUserCircle(withUserModel: userToAdd)
                            moveUserCircles(topUsers: handler.userModels, totalPoints: handler.totalTopUsersPoints)
                        return
                    }
                }else{
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
                moveUserCircles(topUsers: handler.userModels, totalPoints: handler.totalTopUsersPoints)
            }
            moveUserCircles(topUsers: handler.userModels, totalPoints: handler.totalTopUsersPoints)

    }
    
    
    func generateNewUserCircle(withUserModel userModel: GroupEventModel) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let handler = handler else { return }
            let newCircle = UserConatiner(frame: CGRect(x: 0, y:125, width: 100, height: 50))
            addSubview(newCircle)
            let leadingConstraint = newCircle.leadingAnchor.constraint(equalTo: leadingAnchor)
            leadingConstraint.isActive = true
            newCircle.leadingConstraing = leadingConstraint
            newCircle.configure(user: userModel)
            userCircles.append(newCircle)
            print("*-*-*-Created circle with \(newCircle)")
            moveUserCircles(topUsers: handler.userModels, totalPoints: handler.totalTopUsersPoints)
        }
    }
    
    func generateGhostUser(withUserModel userModel: GroupEventModel){
        guard let currentUid = Int(AppConfig.instance.currentUserId ?? "") else { return }
        let ghostUser = GroupEventModel(userId: currentUid, itemCount: userModel.itemCount, groupId: userModel.groupId,carId: 0)
        handler?.userModels.append(ghostUser)
    }
    
    func removeGhostUser() {
        guard let currentUid = Int(AppConfig.instance.currentUserId ?? "") else { return }
        guard let removeIndex = handler?.userModels.firstIndex(where: {$0.userId == currentUid}) else { return }
        handler?.userModels.remove(at: removeIndex)
        userCircles.removeAll(where: {$0.userId == currentUid})
    }
    
    func generateUserCircleInTopList(groupId: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let handler = handler else { return }
            for user in handler.userModels{
                print("*-*-*-TOPUSERS:",handler.userModels)
                if userCircles.first(where: {$0.userId == user.userId}) == nil{
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
            lottieAnimationView.setHeight(60)
            playLottieAnimation()
        }
    }
    
    func moveUserCircles(topUsers: [GroupEventModel], totalPoints: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("*-*-*-\(totalPoints)")
            let roadWidth = self.frame.width - 50
            for user in topUsers {
                print("*-*-*- \(user)")
                guard let circle = self.userCircles.first(where: { $0.userId == user.userId }) else { continue }
                circle.anchor(bottom: lottieAnimationView.centerYAnchor)
                let userPercentageOfTotal = CGFloat(user.itemCount) / CGFloat(totalPoints)
                let estimatedXPosition = (userPercentageOfTotal * roadWidth) - (circle.frame.width / 2)
                let clampedXPosition = max(circle.frame.width / 2, min(estimatedXPosition, roadWidth - circle.frame.width / 2))
                circle.leadingConstraing?.constant = clampedXPosition
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

