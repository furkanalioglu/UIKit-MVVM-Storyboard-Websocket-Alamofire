//
//  UserCircle.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 17.08.2023.
//

import Foundation
import UIKit
import AVFoundation

class UserCircle: UIView {
    
    var userId: Int = 0
    var leadingConstraing : NSLayoutConstraint?
    
    private var playerLooper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?
    private var queuePlayer : AVQueuePlayer?

    
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
//        backgroundColor = .random
        userId = user.userId
//        playAnimation()
        makeCircle()
    }
    
    private func setupView() {
        self.backgroundColor = .random
        addSubview(userIdLabel)
        userIdLabel.centerX(inView: self)
        userIdLabel.centerY(inView: self)
    }
    
    func playAnimation() {
        guard let url = Bundle.main.url(forResource: "framelights2",withExtension: "mp4") else {
            print("Unable to find URL Video")
            return }
        
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
                
        queuePlayer?.pause()
        playerLayer?.removeFromSuperlayer()

        queuePlayer = AVQueuePlayer(playerItem: playerItem)
        playerLooper = AVPlayerLooper(player: queuePlayer!, templateItem: playerItem)

        playerLayer = AVPlayerLayer(player: queuePlayer!)
        guard let playerLayer = self.playerLayer else { return }
        playerLayer.frame = bounds
        layer.addSublayer(playerLayer)

        queuePlayer?.play()
    }
}
