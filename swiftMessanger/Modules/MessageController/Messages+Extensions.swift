//
//  Messages+Extensions.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 14.08.2023.
//

import Foundation
import UIKit
import SocketIO

protocol MessagesControllerDelegate : AnyObject {
    func messageDatasReceived(error: Error?)
    func newMessageCellDataReceived(error : Error?)
    func groupDatasReceived(error: Error?)
}


extension MessagesController : DidSelectUserProtocol {
    func didSelectUser(user: MessagesCellItem) {
        print("SELECTED USER ::\(user)")
        self.performSegue(withIdentifier: viewModel.chatSegueId, sender: user)
    }
}

extension MessagesController : MessagesControllerDelegate {
    func messageDatasReceived(error: Error?) {
        if let error = error {
            print("LIFEDEBUG: COULD NOT LOAD USERS",error.localizedDescription)
            return
        }else{
            tableView.reloadData()
            if AppConfig.instance.dynamicLinkId != nil {
                guard let index = (viewModel.messages?.firstIndex(where: {$0.id == AppConfig.instance.dynamicLinkId})) else { fatalError("NO USER")}
                let user = viewModel.messages?[index]
                performSegue(withIdentifier: viewModel.chatSegueId, sender: user)
            }
        }
        self.refreshControl.endRefreshing()

    }
    
    func newMessageCellDataReceived(error: Error?) {
        if let error = error{
            print(error.localizedDescription)
            return
        }else{
            viewModel.messages = viewModel.messages?.sorted(by: { $0.sendTime?.toDate() ?? Date() > $1.sendTime?.toDate() ?? Date()})
            tableView.reloadData()
        }
    }
    
    func groupDatasReceived(error: Error?) {
        if let error = error {
            print("COULD NOT LOAD",error.localizedDescription)
            return
        }else{
            viewModel.groups = viewModel.groups?.sorted(by: {$0.sendTime.toDate() ?? Date() > $1.sendTime.toDate() ?? Date()})
            tableView.reloadData()
        }
        self.refreshControl.endRefreshing()
    }
}


//MARK: - Delegates
extension MessagesController : SocketIOManagerDelegate {
    func didReceiveGroupMessage(groupMessage: MessageItem) {
        viewModel.handleIncomingGroupMessage(message: groupMessage)
        viewModel.groups = viewModel.groups?.sorted(by: { $0.sendTime.toDate() ?? Date() > $1.sendTime.toDate() ?? Date()})
        tableView.reloadData()

    }
    
    func didReceiveMessage(message: MessageItem) {
        viewModel.handleIncomingMessage(message: message)
        viewModel.messages = viewModel.messages?.sorted(by: { $0.sendTime?.toDate() ?? Date() > $1.sendTime?.toDate() ?? Date()})
        tableView.reloadData()
    }
}

extension MessagesController: ChatMessageSeenDelegate {
    func chatMessageReceivedFromUser(error: String?, message: MessageItem) {
        viewModel.handleIncomingMessage(message: message)
        viewModel.messages = viewModel.messages?.sorted(by: { $0.sendTime?.toDate() ?? Date() > $1.sendTime?.toDate() ?? Date()})
        viewModel.groups = viewModel.groups?.sorted(by: { $0.sendTime.toDate() ?? Date() > $1.sendTime.toDate() ?? Date()})
        print("MESSAGELOFGGG: apeending message to list!")
        tableView.reloadData()
    }
    
    
    func chatMessageSeen(error: String?, forId senderId: Int?) {
        switch viewModel.currentSegment{
        case .groups:
            if let groupIndex = viewModel.groups?.firstIndex(where: {$0.id == senderId}) {
                viewModel.groups?[groupIndex].isSeen = true
                tableView.reloadData()
                print("SEENDEBUG: group \(groupIndex) is setting to seen")
            }
        case .messages:
            if let messageIndex = viewModel.messages?.firstIndex(where: {$0.id == senderId}) {
                viewModel.messages?[messageIndex].isSeen = true
                tableView.reloadData()
                print("SEENDEBUG: message \(messageIndex) is setting to seen")

            }else{
                print("Seendebug: Could not find message with index \(String(describing: senderId))")
            }
        }
    }
}

extension MessagesController: MessagesHeaderProtocol {
    func userDidTapNewGroupButton() {
        performSegue(withIdentifier: viewModel.newGroupSegueId, sender: nil)
    }
}
