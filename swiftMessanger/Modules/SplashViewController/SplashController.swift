//
//  SplashController.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 3.08.2023.
//

import UIKit

//MARK: - VMDELEGATE
protocol SplashControllerDelegate : AnyObject {
    func couldCheckUser(error: Error?)
    func couldReceivedDatas(error: Error?)
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
    func couldCheckUser(error: Error?) {
        if error != nil {
            RootManager.switchRoot(.auth)
        } else {
            print("Configured user without error")
        }
    }
    
    func couldReceivedDatas(error: Error?) {
        if error != nil {
            print(error?.localizedDescription)
        } else {
            print("DEBUGSEND: \(viewModel.messages)")
            RootManager.switchRoot(.tabBar,sender: viewModel.messages)
        }
    }
}
