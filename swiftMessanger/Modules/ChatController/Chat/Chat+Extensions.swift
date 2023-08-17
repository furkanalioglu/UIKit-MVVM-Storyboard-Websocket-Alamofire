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
        
        if viewModel.raceDetails == [] {
            videoCell.isHidden = true
        }else{
            videoCell.isHidden = false
            guard let raceDetails = viewModel.raceDetails else { fatalError("COULD NOT FETCH") } // CHANGE IT LATER
            let handler = RaceHandler(userModels: raceDetails, isAnyRaceAvailable: true, timerValue: 100)
            viewModel.rView = RaceView(frame:.zero,handler: handler)
            videoCell.addSubview(self.viewModel.rView!)
            viewModel.rView?.fillSuperview()

        }
    }
}

extension ChatController : SocketIOManagerChatDelegate {
    func didSendNewEventRequest(groupId: Int, seconds: Int, statusCode: Int) {
        if statusCode == 0 {
            setupRaceView()
        }else{
            videoCell.isHidden = true
            viewModel.rView?.raceTimer?.invalidate()
            print("Wait for cooldown")
        }
    }
    
    func didReceiveNewEventUser(userModel: GroupEventModel) {
        switch viewModel.chatType {
        case .group(let group):
            if let existedUserIndex = viewModel.rView?.handler?.userModels.firstIndex(where: {$0.userId == userModel.userId}) {
                viewModel.rView?.handler?.userModels[existedUserIndex].itemCount += 1
                viewModel.rView?.updateUserCircles(newUser: nil)
                print("Test")
            }else{
                if viewModel.isGroupOwner {
                    if userModel.userId != Int(AppConfig.instance.currentUserId ?? "") {
                        viewModel.rView?.handler?.userModels.append(userModel)
                        viewModel.rView?.updateUserCircles(newUser: userModel)
                        print("Test")
                    }
                }else{
                    viewModel.rView?.handler?.userModels.append(userModel)
                    viewModel.rView?.updateUserCircles(newUser: userModel)
                }
            }
        default:
            break
        }
    }
    
    func didReceiveGroupChatMessage(groupMessage: MessageItem) {
        switch viewModel.chatType {
        case .group(let group):
            if groupMessage.senderId != Int(AppConfig.instance.currentUserId ?? "") {
                if group.id == groupMessage.receiverId {
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
        default:
            break
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


