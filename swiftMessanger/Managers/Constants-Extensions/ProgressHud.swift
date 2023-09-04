//
//  ProgressHud.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 4.09.2023.
//

import Foundation
import JGProgressHUD

extension UIViewController {
    
    static let hud = JGProgressHUD(style: .dark)
    
    func showLoader(_ show: Bool) {
        view.endEditing(true)
        
        if show {
            UIViewController.hud.show(in: view)
        }else {
            UIViewController.hud.dismiss()
        }
        
    }
}
