//
//  SplashViewModel.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 3.08.2023.
//

import Foundation

class SplashViewModel {
    
    weak var delegate : SplashControllerDelegate?
    
    var messages : [MessagesCellItem]?
    
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
//        for i in 0..<assetsArray.count {
//            GiftManager.shared.didDownloadVideo(from: assetsArray[i], assetString: assetType.rawValue, forAsset: i) { didCompleted, err in
//
//            }
//        }
        for i in  0..<AppConfig.instance.carURLS.count{
            GiftManager.shared.didDownloadVideo(from: AppConfig.instance.carURLS[i],assetString: "urlCAR" ,forAsset: i) { didCompleted, err in
                if err == nil && didCompleted == true {
                    print("Downloaded car asset for \(i)")
                }else{
                    self.delegate?.couldCheckUser(error: .couldNotReceivedDatas)
                    return
                }
            }
        }
        self.delegate?.couldCheckUser(error: nil)
    }
    
    func fetchEnvironmentAssets() {
        for i in 0..<AppConfig.instance.otherAssets.count {
            GiftManager.shared.didDownloadVideo(from: AppConfig.instance.otherAssets[i],assetString: "urlEnvironment", forAsset: i) { didCompleted, err in
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
    case urlCAR, urlEnvironment
}
