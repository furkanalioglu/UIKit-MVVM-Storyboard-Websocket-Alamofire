//
//  MessagesCell.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 4.08.2023.
//

import UIKit

class MessagesCell: UITableViewCell {
    
    var message : MessagesCellItem? {
        didSet{
            configureUI()
        }
    }
    
    var group : GroupCell? {
        didSet{
            configureGroupUI()
        }
    }

    @IBOutlet weak var messageImageView: UIImageView!
    @IBOutlet weak var messageSenderLabel: UILabel!
    @IBOutlet weak var messageContentLabel: UILabel!
    @IBOutlet weak var messageSentTimeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    private func configureUI() {
        guard let message = message else { return }
        messageImageView.image = UIImage(named: "prsn")
        messageSenderLabel.text = message.username
        messageContentLabel.text = message.lastMsg
        messageSenderLabel.textColor = message.isSeen ?? false ? .black : .green
        messageSentTimeLabel.text = message.sendTime?.timeElapsedSinceDate()
        
    }
    
    private func configureGroupUI() {
        guard let group = group else { return }
        messageImageView.image = UIImage(named: "prsn")
        messageSenderLabel.text = group.groupName
        messageContentLabel.text = group.lastMsg
        messageSentTimeLabel.text = group.sendTime.timeElapsedSinceDate()
        messageSenderLabel.textColor = group.isSeen ? .black : .green

    }
    
}
