//
//  NewGroupCell.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 11.08.2023.
//

import UIKit

protocol NewGroupEditCellTextFieldProtocol : AnyObject{
    func textDidChange(text: String)
}


class NewGroupEditCell: UICollectionViewCell {

    @IBOutlet weak var groupNameTextField: UITextField!
    
    weak var delegate : NewGroupEditCellTextFieldProtocol?
    var text = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func groupNameTextFieldHandler(_ sender: Any) {
        guard let text = groupNameTextField.text else { return }
        delegate?.textDidChange(text: text)
    }
    

}
