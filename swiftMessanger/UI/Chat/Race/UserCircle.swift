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
    var carId = 0
    var fileName = "framelights1"
    
    let carAnimationManager = GiftManager()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        print("CIRCLE 11 CREATED")
        setupView()
    }

    
    deinit {
        print("CIRCLE 11 DELETED")
    }

        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(withUser user: GroupEventModel, withCarId carId:Int ) {
        self.carId = user.carId
        self.playAnimation()
        self.userId = user.userId
     }
    
    private func setupView() {
        self.backgroundColor = .random
    }
    
    func playAnimation() {
        guard let localURL = AssetManager.shared.getUDAssetPath(for: .urlCAR, assetId: carId) else { return }
        print("AssetDEBUG: trying to play \(localURL)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            carAnimationManager.playSuperAnimation(view: self, videoURLString:localURL) {
                self.layoutIfNeeded()
                self.layoutSubviews()
                print("fired")
            }
        }
    }
}

