//
//  SplashViewModel.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 3.08.2023.
//

import Foundation
import UIKit

class SplashViewModel {
    
    weak var delegate : SplashControllerDelegate?
    
    let giftManager = GiftManager()
    
    var messages : [MessagesCellItem]?
        
    let video : UIView  = {
        let view = UIView()
        return view
    }()
    
    init() {
        attemptAutoLogin()
        fetchCarAssets()
        fetchEnvironmentAssets()
    }


    
    func attemptAutoLogin() {
        UserService.instance.getCurrentUser { error, currentUser in
            if let error = error {
                self.handleLoginError(error: error)
                return
            }
            AppConfig.instance.currentUser = currentUser
            self.handleSuccessfulLogin(with: currentUser)
        }
    }
    
    func handleSuccessfulLogin(with user: CurrentUserModel?) {
//        delegate?.couldCheckUser(error: nil)
        fetchAllMessages()
    }
    
    func handleLoginError(error: Error) {
        print("LIFEDEBUG: Splash faced with error: \(error.localizedDescription)")
        delegate?.couldCheckUser(error: .couldNotFindUser)
        AppConfig.instance.currentUser = nil
        RootManager.switchRoot(.auth)
    }
    
    func fetchAllMessages() {
        UserService.instance.getAllMessages { error, messages in
            
            if let error = error {
                print("MESSAGECONTROLLERDEBUG: \(error.localizedDescription)")
                self.delegate?.couldCheckUser(error: .couldNotReceivedDatas)
                return
            }
            
            self.messages = messages
            self.fetchCarAssets()
            print("MESSAGECONTROLLERDEBUG: \(String(describing: messages))")
        }
    }
    
    func fetchCarAssets() {
        for i in  0..<AppConfig.instance.carURLS.count{
            DownloadManager.shared.didDownloadVideo(from: AppConfig.instance.carURLS[i],assetString: AssetTypes.urlCAR ,forAsset: i) { didCompleted, err in
                if err == nil && didCompleted == true {
                    print("Downloaded car asset for \(i)")
                }else{
                    self.delegate?.couldCheckUser(error: .couldNotReceivedDatas)
                    return
                }
            }
        }
        self.delegate?.couldCheckUser(error: nil)
        guard let localURL = AssetManager.shared.getUDAssetPath(for: .urlCAR, assetId: 4) else { return }
        //better solution?
        giftManager.playSuperAnimation(view: UIView(), videoURLString: localURL) {}
        giftManager.removePlayerView()
    }
    
    func fetchEnvironmentAssets() {
        for i in 0..<AppConfig.instance.otherAssets.count {
            DownloadManager.shared.didDownloadVideo(from: AppConfig.instance.otherAssets[i],assetString: AssetTypes.urlEnvironment, forAsset: i) { didCompleted, err in
                if err == nil && didCompleted == true {
                    print("Downloaded environment asset for \(i)")
                }else{
                    return
                }
            }
        }
    }
    
}

enum AssetTypes: String {
    case urlCAR,urlEnvironment
    
    
    func getPathKey(for assetId: Int) -> String {
        switch self {
        case .urlCAR:
            return "\(assetId)-\(self.rawValue)"
        case .urlEnvironment:
            return "\(assetId)-\(self.rawValue)"
        }
    }
}
