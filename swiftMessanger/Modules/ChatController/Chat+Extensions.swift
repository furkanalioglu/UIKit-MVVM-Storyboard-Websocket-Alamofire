//
//  Chat+Extensions.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 14.08.2023.
//

import Foundation
import UIKit
import SocketIO

protocol ChatControllerDelegate : AnyObject {
    func datasReceived(error : String?)
}

protocol ChatMessageSeenDelegate : AnyObject {
    func chatMessageSeen(error: String?, forId senderId: Int?)
    func chatMessageReceivedFromUser(error: String?, message: MessageItem)
}




extension ChatController : ChatControllerDelegate {
    func datasReceived(error: String?) {
        tableView.refreshControl?.endRefreshing()
        tableView.reloadData()
        if let count = viewModel.messages?.count, count > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
        
    }
}

extension ChatController : SocketIOManagerChatDelegate {
    func scrollToBottom(animated: Bool = true) {
        guard let msgCount = viewModel.messages?.count, msgCount > 0 else {
            return
        }
        
        let indexPath = IndexPath(row: msgCount - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
    
    func didReceiveChatMessage(message: MessageItem) {
        switch viewModel.chatType {
        case .user(let user):
            if message.senderId == user.id || message.senderId == Int(AppConfig.instance.currentUserId ?? "") {
                viewModel.messages?.append(message)
                viewModel.socketMessages.append(message)
                let count = Double(viewModel.socketMessages.count) * viewModel.playbackDurationToAdd
                if message.senderId != Int(AppConfig.instance.currentUserId ?? "") {
                    viewModel.playVideoForDuration(count)
                }
                viewModel.socketMessages.removeAll()
                tableView.reloadData()
                scrollToBottom(animated: true)
            }
        case .group:
            if message.senderId != Int(AppConfig.instance.currentUserId ?? "") {
                viewModel.messages?.append(message)
                viewModel.socketMessages.append(message)
                print("receiveddebugSOCKET arrived appending....")
                viewModel.socketMessages.removeAll()
                tableView.reloadData()
                scrollToBottom(animated: true)
            }
        case .none:
            debugPrint("Received a message for an unidentified chat type.")
        }
    }
}

