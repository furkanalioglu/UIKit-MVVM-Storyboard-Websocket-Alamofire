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
    var avaibleCars = [0,1,2,3]
    
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
        animationView.contentMode = .scaleAspectFill
        animationView.loopMode = .autoReverse
        return animationView
    }()
    
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
            
            self.moveUserCircles(topUsers: handler.topUsers, totalPoints: totalPoints)
            handler.previousTopUsers = handler.topUsers
        }
    }
    
    
    func generateNewUserCircle(withUserModel userModel: GroupEventModel, passedBy fourthUserCarId :Int?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let handler = handler else { return }
            let newCircle = UserConatiner(frame: CGRect(x: 0, y:100, width: 100, height: 50))
            addSubview(newCircle)
            if fourthUserCarId == nil {
                newCircle.carId = userCircles.count
            }else{
                newCircle.carId = fourthUserCarId!
            }
            userCircles.append(newCircle)
            let leadingConstraint = newCircle.leadingAnchor.constraint(equalTo: leadingAnchor)
            leadingConstraint.isActive = true
            newCircle.leadingConstraing = leadingConstraint
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
    
    func configureRoadUI() {
        addSubview(lottieAnimationView)
        lottieAnimationView.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingBottom: 1)
        lottieAnimationView.setHeight(60)
        playLottieAnimation()
    }
    
    func moveUserCircles(topUsers: [GroupEventModel], totalPoints: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("*-*-*-\(totalPoints)")
            let roadWidth = self.frame.width - 50 // This represents 100%
            for user in topUsers {
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
    
    
//    private func playAnimation(environmentId: Int) {
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            guard let pathUD = fetchVideoPath(forEnvironmentId: environmentId) else { return }
//            let videoURLString = "\(pathUD)"
//
//            guard let url = URL(string: videoURLString) else {
//                print("Invalid URL string.")
//                return
//            }
//            print("Trying to use \(videoURLString)")
//
//
//            let asset = AVAsset(url: url)
//            let playerItem = AVPlayerItem(asset: asset)
//
//            queuePlayer?.pause()
//            playerLayer?.removeFromSuperlayer()
//
//            queuePlayer = AVQueuePlayer(playerItem: playerItem)
//            playerLooper = AVPlayerLooper(player: queuePlayer!, templateItem: playerItem)
//            playerLayer = AVPlayerLayer(player: queuePlayer!)
//            guard let playerLayer = self.playerLayer else { return }
//
//            playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
//
//
//            playerLayer.frame = self.road.frame
//            self.layer.addSublayer(playerLayer)
//            self.layoutIfNeeded()
//            self.queuePlayer?.play()
//            debugPrint("It should work..")
//        }
//
//    }
    
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

