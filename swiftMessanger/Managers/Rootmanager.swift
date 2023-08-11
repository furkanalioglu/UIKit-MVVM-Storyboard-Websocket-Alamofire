//
//  Rootmanager.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 3.08.2023.
//
import UIKit

class RootManager {
    
    static let shared: RootManager = {
        let instance = RootManager()
        return instance
    }()
    
    init(){}
    
    static func switchRoot(_ type: PageType,sender: Any? = nil) {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let delegate = windowScene.delegate as? SceneDelegate
            else { return }
            debugPrint("selected root:", type.getSelectedVC())
            let vc = type.getSelectedVC(sender: sender)
            delegate.window?.rootViewController = vc
            UIView.transition(with: delegate.window!,
                              duration: 0.5,
                              options: .transitionCrossDissolve,
                              animations: nil,
                              completion: nil)
        }
    }
}

enum PageType {
    case auth
    case tabBar
    case splash
    
    func getSelectedVC(sender: Any? = nil) -> UIViewController {
        switch self {
        case .auth: return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginController")
        case .tabBar:
            let tabBarVC = UIStoryboard(name: "MainTab", bundle: nil).instantiateViewController(withIdentifier: "MainTab") as! UITabBarController
            if let navController = tabBarVC.viewControllers?.first as? UINavigationController,
               let messagesController = navController.viewControllers.first as? MessagesController,
               let messages = sender as? [MessagesCellItem] {
                messagesController.viewModel.messages = messages
            }
            return tabBarVC
        case .splash: return UIStoryboard(name: "Splash", bundle: nil).instantiateViewController(withIdentifier: "SplashController")
        }
    }
}


