//
//  RaceView.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 15.08.2023.
//
import UIKit

class RaceView: UIView {
    var userCircles: [UserCircle] = []
    var flagView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupFlag()
        road()
        backgroundColor = .systemGray
    }
    
    init(frame: CGRect, users: [GroupEventModel]) {
        super.init(frame: frame)
        
        setupFlag()
        road()
        backgroundColor = .systemGray
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupFlag() {
        let flagImage = UIImage(systemName: "flag")
        flagView = UIImageView(image: flagImage)
        addSubview(flagView)
        flagView.setDimensions(height: 20, width: 20)
        flagView.tintColor = .black
        flagView.anchor(bottom:bottomAnchor,right: rightAnchor, paddingBottom: 5,paddingRight: 0)
    }
    
    private func road() {
        let road = UIView()
        addSubview(road)
        road.backgroundColor = .black
        road.setDimensions(height: 5,width:  400)
        road.anchor(left: leftAnchor,bottom: bottomAnchor,right: rightAnchor,paddingBottom: 1)
    }
    
    func updateUserCircles() {
        
    }
    
    func generateNewUserCircle(withGroupModel user: GroupEventModel) {
            let circle = UserCircle()
            circle.setHeight(30)
            circle.setWidth(30)
            userCircles.append(circle)
            addSubview(circle)
            circle.anchor(left: leftAnchor , bottom:bottomAnchor, paddingLeft: CGFloat((userCircles.count * 10)), paddingBottom: 8)
            circle.layoutIfNeeded()
            circle.makeCircle()
            circle.setUserId(user.userId)
    }
    
    
}

class UserCircle: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .random
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
    
    func setUserId(_ id: Int) {
        userIdLabel.text = String(id)
        addSubview(userIdLabel)
        userIdLabel.centerX(inView: self)
        userIdLabel.center(inView: self)
    }
    
}
