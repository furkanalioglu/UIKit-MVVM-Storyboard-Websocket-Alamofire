//
//  EditProfileViewModel.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 2.08.2023.
//

import Foundation


class EditProfileViewModel {
    let cellNib = "EditProfileCell"
    
        
    func setUpdates(updates: UpdateUserModel) {
        UserService.instance.updateCurrentUser(updates: updates) { error in
            print("DEBUG2: \(updates)")
            if let error = error {
                print(error.localizedDescription)
//                self.delegate?.userDidEditProfile(error: error.localizedDescription)
                return
            }
            AppConfig.instance.currentUser?.status = updates.status
            AppConfig.instance.currentUser?.age = updates.age
            AppConfig.instance.currentUser?.firstName = updates.firstName
            AppConfig.instance.currentUser?.lastName = updates.lastName
//            self.delegate?.userDidEditProfile(error: nil)
        }
    }
    
    
}
