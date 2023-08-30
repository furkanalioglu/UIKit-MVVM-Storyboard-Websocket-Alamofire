//
//  UserConatiner.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 22.08.2023.
//

import UIKit

class UserConatiner: UIView{
    
    var leadingConstraing : NSLayoutConstraint?
    var bottomConstraing : NSLayoutConstraint?
    
    var userId = 0
    var itemCount = 0
        
    var carId = 1 {
        didSet{
            print("CAR ID CHANGED TO \(carId)")
        }
    }
    
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    private let itemCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    let userCircle: UserCircle = {
        let circle = UserCircle()
        return circle
    }()
    
    init() {
        super.init(frame: .zero)
        setupView()
        print("CONTAINER 11 CREATED")
    }
    
    deinit {
        print("CONTAINER 11 DELETED")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            addSubview(usernameLabel)
            addSubview(itemCountLabel)
            addSubview(userCircle)
            
            userCircle.setWidth(30)
            userCircle.setHeight(20)
            userCircle.backgroundColor = .clear
            
            itemCountLabel.setHeight(30)
            itemCountLabel.setWidth(30)
            
            usernameLabel.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor)
            itemCountLabel.anchor(top: usernameLabel.bottomAnchor, left: leftAnchor, right: rightAnchor,paddingBottom: 8)
            userCircle.anchor(top: itemCountLabel.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor,paddingBottom: 10)
            layoutIfNeeded()
        }
    }
    
    func configure(user: GroupEventModel) {
        userId = user.userId
        carId = user.carId
        itemCount = user.itemCount

  
            DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            usernameLabel.text = String(user.userId)
            itemCountLabel.text = String(user.itemCount)

        }
        userCircle.configure(withUser: user,withCarId: carId)

    }
    
    func updateItemCount(user: GroupEventModel) {
        DispatchQueue.main.async { [weak self] in
            self?.itemCount = user.itemCount
            self?.itemCountLabel.text = String(user.itemCount)
        }
    }
    
    func updateItemCountForGhostCar(itemCount : Int) {
        DispatchQueue.main.async { [weak self] in
            self?.itemCount = itemCount
            self?.itemCountLabel.text = String(itemCount)
        }
    }
    
}

