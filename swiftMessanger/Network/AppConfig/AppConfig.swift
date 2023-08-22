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

    lazy var pushToken  : String? = nil
    lazy var dynamicLinkId : Int? = nil
    lazy var currentChat : Int? = nil
    
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
    
    let carURLS = ["https://chat-appbucket.s3.eu-central-1.amazonaws.com/Asset+36%402x+2-luma.mp4",
                   "https://chat-appbucket.s3.eu-central-1.amazonaws.com/Asset+38%402x+2-luma.mp4",
                   "https://chat-appbucket.s3.eu-central-1.amazonaws.com/Asset+41%402x+2-luma.mp4",
                   "https://chat-appbucket.s3.eu-central-1.amazonaws.com/Asset+42%402x+2-luma.mp4"]
    

}
