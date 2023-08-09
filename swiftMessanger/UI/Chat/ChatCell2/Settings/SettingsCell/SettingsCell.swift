import UIKit

class SettingsCell: UITableViewCell {
    
    var user: CurrentUserModel? {
        didSet{
            configureUI()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userStatusLabel: UILabel!
    
    
    
    private func configureUI() {
        guard let user = AppConfig.instance.currentUser else { return }
        usernameLabel.text = user.firstName + user.lastName
        userStatusLabel.text = user.status
    }

}
