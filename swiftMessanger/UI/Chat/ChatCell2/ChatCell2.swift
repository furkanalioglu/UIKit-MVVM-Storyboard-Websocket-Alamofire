//
//  ChatCell2.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 7.08.2023.
//

import UIKit

class ChatCell2: UITableViewCell {
    
    var message: MessageItem? {
        didSet {
            configureUI()
        }
    }
    

    @IBOutlet weak var leftStack: UIStackView!
    @IBOutlet weak var rightStack: UIStackView!
    
    @IBOutlet weak var messageLabrl: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        leftStack.isHidden = false
        rightStack.isHidden = false
    }
    
    private func configureUI() {
        messageLabrl.text = message?.message
        messageLabrl.layer.borderWidth = 2
        guard let message = message else { return }
        guard let currentUserId = AppConfig.instance.currentUserId else { return }
        let isCurrentUserSender = message.senderId == Int(currentUserId)

        rightStack.isHidden = isCurrentUserSender
        leftStack.isHidden = !isCurrentUserSender
    }
    
}
