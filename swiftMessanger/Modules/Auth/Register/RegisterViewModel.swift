//
//  RegisterViewModel.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 3.08.2023.
//

import Foundation
import OneSignal

class RegisterViewModel {
    
    var email : String?
    var password : String?
    var rePassword : String?
    
    weak var delegate : RegisterControllerDelegate?
    
    var isRegisterButtonEnabled: Bool {
        return isDataGranted()
    }
    
    private func isDataGranted() -> Bool {
        guard let email = email,
              let password = password,
              let rePassword = rePassword,
              !email.isEmpty,
              !password.isEmpty,
              !rePassword.isEmpty,
              password == rePassword else {
            return false
        }
        return true
    }
    
    private func createUser(firstName: String?, lastName: String?,age: String? , gender: String?)  -> RegisterModel?{
        guard let email = email,
                let password = password,
                password == rePassword,
                let firstName = firstName,
                let lastName = lastName,
                let age = age,
                let gender = gender else {
              return nil
          }
        return RegisterModel(username: email,
                             email: email,
                             password: password,
                             firstName: firstName,
                             lastName: lastName,
                             age: age,
                             gender: gender)
    }
    
    func registerUser(firstName: String?, lastName: String?, age: String?, gender: String?) {
        guard let user = createUser(firstName: firstName, lastName: lastName, age: age, gender: gender) else { return }
        AuthService.instance.register(withUser: user) { error in
            if let error = error {
                self.delegate?.didRegisterUser(nil, error: error.localizedDescription)
                return
            }
            self.delegate?.didRegisterUser(user, error: nil)
        }
    }
    
    func loginUser(withEmail email: String, password: String, pushToken: String) {
        let user = LoginModel(username: email, password: password, pushToken: pushToken)
        AuthService.instance.login(withLoginModel: user) { error in
            if let error = error {
                print("DEBUGERROR: \(error.localizedDescription)")
                print("LIFEDEBUG:could not get current user")
                self.delegate?.didLoginRegisteredUser(error: error.localizedDescription)
                return
            }
            print("DEBUG2: USER LOGGED IN)")
            UserService.instance.getCurrentUser { error, currentUser in
                if let error = error {
                    print(error.localizedDescription)
                    print("LIFEDEBUG:COULD NOT GET CURRENT USER")
                    self.delegate?.didLoginRegisteredUser(error: error.localizedDescription)
                    return
                }
                UserDefaults.standard.string(forKey: userToken)
                OneSignal.setExternalUserId(pushToken)
                AppConfig.instance.currentUser = currentUser
                AppConfig.instance.currentUserId = UserDefaults.standard.string(forKey: currentUserIdK)


                SocketIOManager.shared().establishConnection()
                print("LIFEDEBUG:Suc")
                self.delegate?.didLoginRegisteredUser(error: nil)
            }
        }
    }
}
