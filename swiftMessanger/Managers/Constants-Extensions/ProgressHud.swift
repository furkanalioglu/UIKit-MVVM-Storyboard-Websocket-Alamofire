//
//  ProgressHud.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 4.09.2023.
//

import Foundation
import JGProgressHUD

extension UIViewController {
    
    private static var huds: [UIViewController: JGProgressHUD] = [:]
    
    private var hud: JGProgressHUD {
        if let hud = UIViewController.huds[self] {
            return hud
        } else {
            let newHUD = JGProgressHUD(style: .dark)
            UIViewController.huds[self] = newHUD
            return newHUD
        }
    }
    
    func showLoader(_ show: Bool) {
        view.endEditing(true)
        
        if show {
            hud.show(in: view)
        } else {
            hud.dismiss()
            UIViewController.huds[self] = nil
        }
    }
}
