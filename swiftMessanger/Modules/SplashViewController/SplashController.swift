//
//  SplashController.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 3.08.2023.
//

import UIKit

enum SplashErrors: Int {
    case couldNotFindUser, couldNotReceivedDatas
}

//MARK: - VMDELEGATE
protocol SplashControllerDelegate : AnyObject {
    func couldCheckUser(error: SplashErrors?)
}


class SplashController: UIViewController {
    
    //MARK: - Properties
    let viewModel = SplashViewModel()
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
    }
}

//MARK: - DELEGATE
extension SplashController : SplashControllerDelegate {
    func couldCheckUser(error: SplashErrors?) {
        if error == .couldNotFindUser {
            RootManager.switchRoot(.auth)
            return
        }
        
        if error == .couldNotReceivedDatas {
            print("COULD NOT FIND USER")
            return
        }
        
        
        if error == nil {
            RootManager.switchRoot(.tabBar,sender: viewModel.messages)
        }
    }
}

