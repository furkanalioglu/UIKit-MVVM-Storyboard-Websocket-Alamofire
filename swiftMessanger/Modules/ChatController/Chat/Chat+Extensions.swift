//
//  Chat+Extensions.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 14.08.2023.
//

import Foundation
import UIKit
import SocketIO
import SDWebImage

protocol ChatControllerDelegate : AnyObject {
    func datasReceived(error : String?)
    func newMessageDatasExist(status: String)
}

protocol ChatMessageSeenDelegate : AnyObject {
    func chatMessageSeen(error: String?, forId senderId: Int?)
    func chatMessageReceivedFromUser(error: String?, message: MessageItem)
}

protocol ChatControllerSentPhotoDelegate: AnyObject {
    func userDidSentPhoto(image:UIImage?, error: String?)
}


extension ChatController : ChatControllerDelegate {
    func newMessageDatasExist(status: String) {
        if status == "fetch" {
            showLoader(true)
        }else{
            tableView.reloadData()
            setupNavigationController()
            scrollToBottom()
            showLoader(false)
        }
    }
    
    
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
                guard let timeleft = viewModel.timeLeft else { return }
                if timeleft <= 0{
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        videoCell.isHidden = true

                    }
                }else{
                    guard let timeLeft = viewModel.timeLeft else { return }
                    guard let raceDetails = viewModel.raceDetails else { return }
                    guard let userItemCount = viewModel.userItemCount else { return }
                    viewModel.rView?.handler?.countdownValue = timeLeft
                    let handler = RaceHandler(userModels: raceDetails, isAnyRaceAvailable: true,countdownValue:timeLeft, raceOwnerId: viewModel.groupOwnerId)
                    viewModel.rView = RaceView(frame: view.frame, handler: handler,groupId: group.id)
                    viewModel.rView?.handler?.startTimer()
                    viewModel.rView?.ghostCarView.itemCount = userItemCount
                    viewModel.rView?.ghostCarView.updateItemCountForGhostCar(itemCount: userItemCount)
                    viewModel.rView?.layoutIfNeeded()
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        videoCell.addSubview(self.viewModel.rView!)
                        viewModel.rView?.fillSuperview()
                        videoCell.isHidden = false
                        viewModel.rView?.layoutIfNeeded()
                        print("2")
                    }
                    viewModel.rView?.updateUserCircles(newUsers: nil)
                    print("3")

                }
            }
        case .user(_):
            if error == nil {
                if tableView.refreshControl?.isRefreshing == true {
                    if tableView.isDragging {
                        shouldEndRefreshingAfterDragging = true
                    } else {
                        DispatchQueue.main.async {
                            self.tableView.refreshControl?.endRefreshing()
                        }
                    }
                }
                tableView.reloadData()
                setupNavigationController()
            }else{

            }
        default:
            break
        }
    }
}

extension ChatController : SocketIOManagerChatDelegate {
    func didSentNewChatMessage(payloadDate: String,text: String,type:String) {
        guard let currentUserId = AppConfig.instance.currentUserId else { return }
        switch viewModel.chatType{
        case .user(_ ):
            if type == MessageTypes.text.rawValue {
                viewModel.addNewChatMessage(payloadDate: payloadDate, messageText: text, type: type) { _ in
                    self.tableView.reloadData()
                    self.scrollToBottom()
                }
            }else{
                viewModel.addNewChatMessage(payloadDate: payloadDate, messageText: text, type: type) { error in
                    if error == nil {
                        self.tableView.reloadData()
                        self.scrollToBottom(animated: true)
                        self.showLoader(false)
                    }
                }
            }
        default:
            break
        }
    }
    
    func didReceiveCurrentuserCountFromAck(itemCount: ItemCountAck) {
        guard let itemCount = itemCount.itemCount else { return }
        self.viewModel.rView?.ghostCarView.updateItemCountForGhostCar(itemCount: itemCount)
    }
    
    func didSendNewEventRequest(groupId: Int, seconds: Int, statusCode: Int) {
        if statusCode == 0 {
            setupRaceView(seconds: seconds)
        }else{
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                videoCell.isHidden = true

            }
        }
    }
    
    
    func didReceiveNewEventUser(userModel: GroupEventModelArray) {
        guard let chatType = viewModel.chatType else { return }
            viewModel.handleEventActions(userModelArray: userModel, group: chatType) { eventType in
                switch eventType{
                case .updateUserCircles:
                    self.viewModel.rView?.updateUserCircles(newUsers: userModel)

                case .showVideoCell(let raceDetails, let groupId, let timer):
                    let handler = RaceHandler(userModels: raceDetails,
                                              isAnyRaceAvailable: true,
                                              countdownValue: timer,raceOwnerId: self.viewModel.groupOwnerId)
                    self.viewModel.rView = RaceView(frame: (self.view.frame),
                                               handler: handler,
                                               groupId: groupId)

                    self.viewModel.rView?.handler?.startTimer()
                    self.viewModel.rView?.updateUserCircles(newUsers: nil)

                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        videoCell.isHidden = false
                        videoCell.addSubview((viewModel.rView)!)
                        viewModel.rView?.fillSuperview()
                        viewModel.rView?.layoutIfNeeded()
                    }
                    
                case .hideVideoCell:
                    self.viewModel.rView?.userCircles = []
                    self.viewModel.raceDetails = []
                    self.viewModel.rView?.handler?.stopTimer()
                    viewModel.rView?.ghostCarView.itemCount = 0
                    viewModel.rView?.ghostCarView.updateItemCountForGhostCar(itemCount: 0)

                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.videoCell.isHidden = true
                        self.viewModel.rView?.removeFromSuperview()
                        
                    }

                }
                
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
        guard let msgCount = viewModel.messages?.count,
                msgCount > 0 else {
            return
        }
        
        let indexPath = IndexPath(row: msgCount - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
    
    func didReceiveChatMessage(message: MessageItem) {
        switch viewModel.chatType {
        case .user(let user):
            if message.senderId == user.userId || message.senderId == Int(AppConfig.instance.currentUserId ?? "") {
                viewModel.messages?.append(message)

                if message.type == MessageTypes.text.rawValue {
                    tableView.reloadData()
                    scrollToBottom(animated: true)
                }else{
                    guard let url = URL(string:message.message) else { return }
                    let index = self.viewModel.messages?.firstIndex(where: {$0.sendTime == message.sendTime})

                    ImageLoader.shared.getData(from: url) { data, _, err in
                        if err == nil {
                            CoreDataManager.shared.updateImageDataInCoreData(forMessageWithSendTime: message.sendTime, with: data!)
                            self.viewModel.messages![index!].imageData = data
                        }
                        
                    }
                }
                tableView.reloadData()
                scrollToBottom(animated: true)
            }
            
        default:
            break
        }
    }
}


extension ChatController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == viewModel.segueId,
            let chatVC = segue.destination as? ChatInformationController {
            chatVC.viewModel.users = viewModel.userInformations

        } else if segue.identifier == viewModel.startSegueId,
                  let chatVC = segue.destination as? StartRaceController{
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
extension ChatController : PhotoPickerDelegate {
    func didPickImageData(_ image: UIImage) {
        self.showLoader(true)
        viewModel.handleSentPhotoAction(image: image)
    }
    
    func didCancelPicking() {
        print("IMAGEDEBUG: Picker dismieed")
    }
}


extension ChatController: LoadImageDelegate {
    func didCompleteLoadingImage(payloadDate: String, imageData: Data?) {
        guard
            let cellIndex = viewModel.messages?.firstIndex(where: {$0.sendTime == payloadDate}),
            let tableView = self.tableView
        else {
            return
        }
        
        let indexPath = IndexPath(row: cellIndex, section: 0)
        if let cell = tableView.cellForRow(at: indexPath) as? ChatCellWithImage {
            cell.sentImageView.image = UIImage(data: imageData!)
            tableView.reloadData()
            print("COMPLETED")
        }
    }
}


extension ChatController : ChatControllerSentPhotoDelegate {
    func userDidSentPhoto(image: UIImage?, error: String?) {
        if error == nil {
            self.tableView.reloadData()
            self.showLoader(false)
            scrollToBottom(animated: true)
        }
    }
}


