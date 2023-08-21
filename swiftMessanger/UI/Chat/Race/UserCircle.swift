//
//  UserCircle.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 17.08.2023.
//

import Foundation
import UIKit

class UserCircle: UIView {
    
    var userId: Int = 0
    var leadingConstraing : NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let userIdLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    func makeCircle() {
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.masksToBounds = true
    }
    
    func configure(withUser user: GroupEventModel) {
        userIdLabel.text = String(user.userId)
        backgroundColor = .random
        userId = user.userId
        makeCircle()
    }
    
    private func setupView() {
        self.backgroundColor = .random
        addSubview(userIdLabel)
        userIdLabel.centerX(inView: self)
        userIdLabel.centerY(inView: self)
    }
}
