//
//  RootExtension.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 3.08.2023.
//

import Foundation
import UIKit
extension UIStoryboard {
    
    enum Storyboard: String {
        case Main
        case MainTab
        var name: String {
            return rawValue
        }
    }
    
    static func loadViewController<T>(_ board: Storyboard) -> T where T: StoryboardSwitch, T: UIViewController {
        return UIStoryboard(name: board.name, bundle: nil).instantiateViewController(withIdentifier: T.storyboardIdentifier()) as! T
    }

    func instantiateViewController<T: UIViewController>(ofType _: T.Type, withIdentifier identifier: String? = nil) -> T {
        let identifier = identifier ?? String(describing: T.self)
        return instantiateViewController(withIdentifier: identifier) as! T
    }
}



protocol StoryboardSwitch {
    static func storyboardIdentifier() -> String
}

extension StoryboardSwitch where Self: UIViewController {
    static func storyboardIdentifier() -> String {
        return String(describing: Self.self)
    }
}

extension StoryboardSwitch where Self: UINavigationController {
    static func storyboardIdentifier() -> String {
        return String(describing: Self.self)
    }
}

extension UIWindow {
    func switchRoot(to viewController: UIViewController, animated: Bool ,duration: TimeInterval,options: UIView.AnimationOptions, _ completion: (() -> Void)? = nil) {
        guard animated else {
            rootViewController = viewController
            completion?()
            return
        }
        UIView.transition(with: self, duration: duration, options: options, animations: {
            let animationState = UIView.areAnimationsEnabled
            UIView.setAnimationsEnabled(false)
            self.rootViewController = viewController
            UIView.setAnimationsEnabled(animationState)
        }, completion: { _ in
            completion?()
        })
    }
}

extension UIView {
    func setAnchorPoint(_ point: CGPoint) {
        var newPoint = CGPoint(x: bounds.size.width * point.x, y: bounds.size.height * point.y)
        var oldPoint = CGPoint(x: bounds.size.width * layer.anchorPoint.x, y: bounds.size.height * layer.anchorPoint.y);

        newPoint = newPoint.applying(transform)
        oldPoint = oldPoint.applying(transform)

        var position = layer.position

        position.x -= oldPoint.x
        position.x += newPoint.x

        position.y -= oldPoint.y
        position.y += newPoint.y

        layer.position = position
        layer.anchorPoint = point
    }
}

