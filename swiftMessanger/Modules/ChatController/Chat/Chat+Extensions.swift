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
        setupNavigationController()

        if let count = viewModel.messages?.count, count > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }
}

extension ChatController : SocketIOManagerChatDelegate {
    func didReceiveNewEventUser(userModel: GroupEventModel) {
        switch viewModel.chatType {
        case .group(let group):
            let newUser = GroupEventModel(userId: userModel.userId, itemCount: userModel.itemCount, groupId: userModel.groupId)
            viewModel.topUserInformations.append(newUser)
            print("eventdebug:",viewModel.topUserInformations.count)
            if viewModel.rView?.userCircles.count ?? 0 < 3{
                viewModel.rView?.generateNewUserCircle(withGroupModel: userModel)
            }else{
                viewModel.rView?.updateUserCircles()
            }
            print("EVENTDEBUG: \(userModel)")
        default:
            break
            
        }
    }
    
    func didReceiveGroupChatMessage(groupMessage: MessageItem) {
        switch viewModel.chatType {
        case .user(let user):
            print("User received email")
        case .group(let group):
            if groupMessage.senderId != Int(AppConfig.instance.currentUserId ?? "") {
                viewModel.messages?.append(groupMessage)
                viewModel.socketMessages.append(groupMessage)
                print("receiveddebugSOCKET arrived appending....")
                viewModel.socketMessages.removeAll()
                tableView.reloadData()
                scrollToBottom(animated: true)
                if viewModel.rView != nil  {
                    print("EVENTDEBUG: MOVE CIRCLES")
                }
            }
        default:
            print("err")
        }
    }
    
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
            print("Received group message")
        case .none:
            debugPrint("Received a message for an unidentified chat type.")
        }
    }
}


extension ChatController{
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == viewModel.segueId, let chatVC = segue.destination as? ChatInformationController {
            if let selectedUsers = sender as? [UserModel] {
                chatVC.viewModel.users = viewModel.userInformations
            }else{
                print("SEGUEDEBUG: could not send segue")
            }
        }
    }
}


