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
        switch viewModel.chatType{
        case .group(let group):
            if error == nil {
                
                tableView.refreshControl?.endRefreshing()
                tableView.reloadData()
                setupNavigationController()
                
                if let count = viewModel.messages?.count, count > 0 {
                    tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                }
                
                if viewModel.raceDetails == [] && viewModel.timeLeft == 0{
                    videoCell.isHidden = true
                }else{
                    guard var raceDetails = viewModel.raceDetails else { fatalError("COULD NOT FETCH") } // CHANGE IT LATER
                    guard let timeLeft = viewModel.timeLeft else { return }
                    viewModel.rView?.handler?.countdownValue = timeLeft
                    guard let myId = Int(AppConfig.instance.currentUserId ?? "") else { fatalError( "NO CUID ")}

                    if !raceDetails.contains(where: {$0.userId == myId}) && !viewModel.isGroupOwner{
                        raceDetails.append(GroupEventModel(userId: myId, itemCount: 0, groupId: group.id))
                    }
                    let handler = RaceHandler(userModels: raceDetails, isAnyRaceAvailable: true,countdownValue:timeLeft )
                    viewModel.rView = RaceView(frame: view.frame, handler: handler,groupId: group.id)
                    videoCell.addSubview(self.viewModel.rView!)
                    viewModel.rView?.fillSuperview()
                    viewModel.rView?.handler?.startTimer()
                    videoCell.isHidden = false
                    viewModel.rView?.updateUserCircles(newUser: nil)
                }
            }
        default:
            break
        }
    }
}

extension ChatController : SocketIOManagerChatDelegate {
    func didSendNewEventRequest(groupId: Int, seconds: Int, statusCode: Int) {
        if statusCode == 0 {
            setupRaceView(seconds: seconds)
        }else{
            videoCell.isHidden = true
            print("Wait for cooldown")
        }
    }
    
    func didReceiveNewEventUser(userModel: GroupEventModel) {
        switch viewModel.chatType {
        case .group(let group):
            print("EVENTDEBUG: CRASH, \(userModel.userId)")
            if userModel.groupId == group.id && userModel.userId != EventResponse.evenFinished.rawValue {
                if let existedUserIndex = viewModel.rView?.handler?.userModels.firstIndex(where: {$0.userId == userModel.userId}) {
                    viewModel.rView?.handler?.userModels[existedUserIndex].itemCount += 1
                    viewModel.rView?.updateUserCircles(newUser: nil)
                    print("Test")
                }else{
                    viewModel.rView?.handler?.userModels.append(userModel)
                    if let existedUserIndex = viewModel.rView?.handler?.userModels.firstIndex(where: {$0.userId == userModel.userId}){
                        viewModel.rView?.handler?.userModels[existedUserIndex].itemCount += 1
                        viewModel.rView?.updateUserCircles(newUser: userModel)
                    }
                }
            }
            
            if userModel.groupId == group.id && userModel.userId == EventResponse.evenFinished.rawValue {
                videoCell.isHidden = true
                viewModel.raceDetails = []
                viewModel.rView?.handler?.stopTimer()
                viewModel.rView?.removeFromSuperview()
                return
            }
            
            if userModel.groupId == group.id && userModel.userId == EventResponse.eventAvaible.rawValue{
                guard var raceDetails = viewModel.raceDetails else { fatalError("COULD NOT FETCH") } // CHANGE IT LATER
                print("RACE17DEBUG: fetceh race details from viewModel : \(raceDetails)")
                videoCell.isHidden = false
                guard let myId = Int(AppConfig.instance.currentUserId ?? "") else { fatalError( "NO CUID ")}
                if !raceDetails.contains(where: {$0.userId == myId}) && !viewModel.isGroupOwner{
                    raceDetails.append(GroupEventModel(userId: myId, itemCount: 0, groupId: group.id))
                }
                let handler = RaceHandler(userModels: raceDetails, isAnyRaceAvailable: true,countdownValue: userModel.itemCount)
                viewModel.rView = RaceView(frame: view.frame, handler: handler,groupId: group.id)
                videoCell.addSubview(self.viewModel.rView!)
                viewModel.rView?.fillSuperview()
                viewModel.rView?.handler?.startTimer()
                viewModel.rView?.updateUserCircles(newUser: nil)
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
        }else if segue.identifier == viewModel.startSegueId, let chatVC = segue.destination as? StartRaceController{
            chatVC.delegate = self
        }
    }
}

extension ChatController: StartControllerProtocol{
    func userDidTapStartButton(value: Int) {
        switch viewModel.chatType{
        case .group(let group):
            SocketIOManager.shared().sendRaceEventRequest(groupId: String(group.id), seconds: String(value),status: 0)
            dismiss(animated: true)
        default:
            break
        }
    }
}


