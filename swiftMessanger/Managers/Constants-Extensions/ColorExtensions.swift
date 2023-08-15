//
//  ColorExtensions.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 15.08.2023.
//

import Foundation
import UIKit

extension UIColor {
    static var random: UIColor {
        return UIColor(red: .random(), green: .random(), blue: .random(), alpha: 1.0)
    }
}
extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}
