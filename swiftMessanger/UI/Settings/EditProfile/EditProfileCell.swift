//
//  EditProfileCellTableViewCell.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 2.08.2023.
//

import UIKit

class EditProfileCell: UITableViewCell {
    
    weak var delegate : EditProfileDelegate?
    
    @IBOutlet weak var userProfileImageView: UIImageView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var statusTextField: UITextField!
    @IBOutlet weak var saveButtonOutlet: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureUserModel()
    }
    
    @IBAction func saveButtonAction(_ sender: Any) {
        guard  let name = firstNameTextField.text else { return }
        guard let lastName = lastNameTextField.text else { return }
        guard  let status = statusTextField.text else { return }
        let updates = UpdateUserModel(firstName: name, lastName: lastName, status:status, age:"15")
        print("DEBUG2: \(updates)")
        self.delegate?.didTapSaveUser(updates:updates)
    }
    

    private func configureUserModel() {
        guard let user = AppConfig.instance.currentUser else { return }
        print("DEBUG7: USER \(user)")
        firstNameTextField.text = user.firstName
        lastNameTextField.text = user.lastName
        statusTextField.text = user.status
    }
}
