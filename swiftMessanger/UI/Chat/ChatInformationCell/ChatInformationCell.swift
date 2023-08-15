//
//  ChatInformationCell.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 15.08.2023.
//

import UIKit

class ChatInformationCell: UITableViewCell {
    
    var user : UserModel? {
        didSet {
            configureUI()
        }
    }

    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    private func configureUI() {
        userNameLabel.text = user?.username
        userImageView.image = UIImage(named:"prsn")
        userNameLabel.textColor = user?.groupRole == "User" ? .black : .systemYellow
    }
    
}
