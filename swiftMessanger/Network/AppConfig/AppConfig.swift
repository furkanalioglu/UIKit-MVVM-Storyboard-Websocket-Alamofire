//
//  AppConfig.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 2.08.2023.
//

import Foundation


class AppConfig {
    
    static let instance = AppConfig()
    
    private init() {}

    
    var currentUser: CurrentUserModel? {
        didSet {
            if currentUser != nil {
                SocketIOManager.shared().establishConnection()
            } else {
                SocketIOManager.shared().closeConnection()
            }
        }
    }
    
    var currentUserId = UserDefaults.standard.string(forKey: currentUserIdK) {
        didSet{
            print("DEBUGGGGGGG:",currentUserId)
        }
    }
    
    

}
