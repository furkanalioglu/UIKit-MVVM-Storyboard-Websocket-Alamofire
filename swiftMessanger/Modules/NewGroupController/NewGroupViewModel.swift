//
//  NewGroupViewModel.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 11.08.2023.
//

import Foundation

class NewGroupViewModel {
    let cellId = "NewGroupCell"
    let headerId = "NewGroupHeader"
    
    lazy var segueId = "toShowGroupEditController"
    
    var users : [MessagesCellItem]?
    var selectedUsers = [Int]()
    
    weak var delegate : NewGroupControllerProtocol?
    
    init() {
        getDatas()
    }
    
    func getDatas() {
        UserService.instance.getAllUsersForGroups { error, users in
            if error != nil {
                print(error)
                self.delegate?.datasReceived(error: error?.localizedDescription)
                return
            }
            self.users = users
            self.delegate?.datasReceived(error: nil)
        }
    }
}
