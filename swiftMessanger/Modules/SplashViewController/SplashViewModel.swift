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
        delegate?.couldCheckUser(error: nil)
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
            self.fetchAllAssets()
            print("MESSAGECONTROLLERDEBUG: \(String(describing: messages))")
        }
    }
    
    func fetchAllAssets() {
        for i in  0..<AppConfig.instance.carURLS.count{
            GiftManager.shared.didDownloadVideo(from: AppConfig.instance.carURLS[i] ,forCar: i) { didCompleted, err in
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
}
