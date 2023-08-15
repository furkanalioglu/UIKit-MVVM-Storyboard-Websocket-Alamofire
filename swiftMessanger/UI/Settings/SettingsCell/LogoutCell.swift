//
//  LogoutCell.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 2.08.2023.
//

import UIKit

protocol LogoutCellProtocol : AnyObject{
    func didTapLogoutButton()
}

class LogoutCell: UITableViewCell {
    weak var delegate : LogoutCellProtocol?
    @IBOutlet weak var logoutButtonOutlet: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func logoutButtonAction(_ sender: Any) {
        self.delegate?.didTapLogoutButton()
        
    }
    
}
