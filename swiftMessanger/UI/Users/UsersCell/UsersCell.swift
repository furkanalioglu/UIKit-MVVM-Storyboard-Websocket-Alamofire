//
//  UsersCell.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 1.08.2023.
//

import UIKit
import SDWebImage

class UsersCell: UITableViewCell {
    
    var user: MessagesCellItem? {
        didSet  {
            print("userdebug: \(user) SETT!!")
            configureUI()
        }
    }
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var fullname: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    private func configureUI() {
        guard let user = user else { return }
        username.text = user.username
        fullname.text = user.status
        userImageView.sd_setImage(with: URL(string: user.url))
        
        userImageView.layer.borderWidth = 1.0
        userImageView.layer.masksToBounds = false
        userImageView.layer.borderColor = UIColor.white.cgColor
        userImageView.layer.cornerRadius = userImageView.frame.size.width / 2
        userImageView.clipsToBounds = true
    }
}
