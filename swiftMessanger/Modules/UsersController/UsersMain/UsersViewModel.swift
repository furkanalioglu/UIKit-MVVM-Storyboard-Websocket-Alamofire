//
//  UsersViewModel.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 1.08.2023.
//

import Foundation

class UsersViewModel {
    let cellNib = "UsersCell"
    let headerNib = "UsersHeader"
    
    weak var delegate : UsersControllerProtocol?
    weak var selectUserDelegate : DidSelectUserProtocol?
    
    init() {
        getDatas()
    }
    
    var users : [MessagesCellItem]?
    var filteredUsers: [MessagesCellItem]?
    var currentUser : CurrentUserModel?

    
    func getDatas() {
        UserService.instance.getAllUsers { error, users in
            if let error = error {
                print("DEBUG COULD NOT FETCH USERS \(error.localizedDescription)")
                self.delegate?.didReceivedDatas(error: error.localizedDescription)
                return
            }
            self.users = users
            self.filteredUsers = users
            self.delegate?.didReceivedDatas(error: nil)
        }
    }
    
    func filterUsers(searchText: String) {
        if searchText.count > 1 && !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filteredUsers = users?.filter({$0.username.contains(searchText)})
        }else{
            filteredUsers = users
        }
        
    }
}
