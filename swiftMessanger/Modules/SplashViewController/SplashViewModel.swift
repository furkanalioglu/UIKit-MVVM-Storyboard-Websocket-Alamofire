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
        delegate?.couldCheckUser(error: error)
        AppConfig.instance.currentUser = nil
        RootManager.switchRoot(.auth)
    }
    
    func fetchAllMessages() {
        UserService.instance.getAllMessages { error, messages in
            
            if let error = error {
                print("MESSAGECONTROLLERDEBUG: \(error.localizedDescription)")
                self.delegate?.couldReceivedDatas(error: error)
                return
            }
            
            self.messages = messages
            self.delegate?.couldReceivedDatas(error: nil)
            print("MESSAGECONTROLLERDEBUG: \(String(describing: messages))")
        }
    }
    

}
