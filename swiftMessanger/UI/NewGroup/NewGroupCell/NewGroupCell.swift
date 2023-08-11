//
//  NewGroupCell.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 11.08.2023.
//

import UIKit

class NewGroupCell: UITableViewCell {
    
    var user: MessagesCellItem? {
        didSet  {
            print("userdebug: \(user?.selectedForCell) SETT!!")
            configureUI()
        }
    }
        
    @IBOutlet weak var userProfileImage: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userStatusLabel: UILabel!
    @IBOutlet weak var userIsSelectedView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureUI() {
        guard let user = user else { return }
        usernameLabel.text = user.username
        userStatusLabel.text = user.status
        userIsSelectedView.backgroundColor = user.selectedForCell ?? false ?  .green : .red
    }
}
