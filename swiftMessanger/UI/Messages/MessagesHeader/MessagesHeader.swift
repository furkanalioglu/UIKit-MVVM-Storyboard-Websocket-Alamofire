//
//  MessagesHeader.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 11.08.2023.
//

import UIKit

protocol MessagesHeaderProtocol : AnyObject {
    func userDidTapNewGroupButton()
}

class MessagesHeader: UITableViewHeaderFooterView {
    
    let viewModel = MessagesHeaderViewModel()
    
    @IBOutlet weak var broadcastsLabel: UIButton!
    @IBOutlet weak var newGroupLabel: UIButton!
    
    //MARK: - Lifecylce
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func newGroupHandler(_ sender: UIButton) {
        viewModel.delegate?.userDidTapNewGroupButton()
    }
    


}
