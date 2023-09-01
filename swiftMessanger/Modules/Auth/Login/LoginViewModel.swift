//
//  LoginViewModel.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 31.07.2023.
//

import Foundation
import OneSignal

class LoginViewModel {
    let segueRegisterId = "toShowRegister"
    let segueMessagesTabId = "toShowMainTab"
    
    weak var delegate : LoginControllerDelegate?
    
    init() {
    }
    
    func loginUser(withEmail email: String, password: String, pushToken: String) {
        let user = LoginModel(username: email, password: password, pushToken: pushToken)
        AuthService.instance.login(withLoginModel: user) { error in
            if let error = error {
                print("DEBUGERROR: \(error.localizedDescription)")
                print("LIFEDEBUG:could not get current user")
                self.delegate?.userLoggedIn(error: error)
                return
            }
            print("DEBUG2: USER LOGGED IN)")
            UserService.instance.getCurrentUser { error, currentUser in
                if let error = error {
                    print(error.localizedDescription)
                    print("LIFEDEBUG:COULD NOT GET CURRENT USER")
                    self.delegate?.userLoggedIn(error: error)
                    return
                }
                print("SOCKETDEBUG:: \(UserDefaults.standard.string(forKey: userToken))")
                OneSignal.setExternalUserId(pushToken)
                print("SOCKETDEBUG:: \(currentUser)")
                AppConfig.instance.currentUserId = UserDefaults.standard.string(forKey: currentUserIdK)
                AppConfig.instance.currentUser = currentUser



//                SocketIOManager.shared().establishConnection()
                print("LIFEDEBUG:Suc")
                self.delegate?.userLoggedIn(error: error)
            }
        }
    }
}
