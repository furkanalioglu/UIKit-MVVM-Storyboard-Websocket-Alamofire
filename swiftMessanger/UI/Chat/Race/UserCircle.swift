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
    var fileName = "framelights1"
    
    private var playerLooper: AVPlayerLooper?
    var playerLayer: AVPlayerLayer?
    private var queuePlayer : AVQueuePlayer?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(withUser user: GroupEventModel) {
        userId = user.userId
        playAnimation()
    }
    
    private func setupView() {
        self.backgroundColor = .random
    }
    
    func playAnimation() {
        GiftManager.shared.didDownloadVideo(from: "https://chat-appbucket.s3.eu-central-1.amazonaws.com/Asset+36%402x+2-luma.mp4") { url, err in
            if err == nil {
                print("METALDEBUG: BEFORE LAUNCH: \(UserDefaults.standard.string(forKey: "urlCAR")!)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    GiftManager.shared.playSuperAnimation(view: self, videoURLString: UserDefaults.standard.string(forKey: "urlCAR")!) {
                        self.playAnimation()
                    }
                }
            }
        }
    }
}
