//
//  ChatViewModel.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 2.08.2023.
//

import Foundation
import AVFoundation
import UIKit
import SDWebImage


enum ChatType {
    case user(MessagesCellItem)
    case group(GroupCell)
}

enum GroupRoles: String {
    case User, Admin
}

enum ChatStatus : String{
    case load, fetch, disableRefresh
}

enum MessageTypes : String{
    case image, text
}

enum EventResponse : Int {
    case eventAvaible = 0
    case eventFinished = -1
}

enum ActionType {
    case updateUserCircles(newUser: GroupEventModelArray?)
    case hideVideoCell
    case showVideoCell(raceDetails: [GroupEventModel], groupId: Int, countdownValue: Int)
}

class ChatViewModel {
    
    var rView:RaceView? = nil
    
    let cellNib = "ChatCell2"
    let cellWithImageNib = "ChatCellWithImage"
    lazy var segueId = "toShowInformation"
    lazy var startSegueId = "toShowStart"
    
    //Local Message Paginition
    var localMessageIndex = 0
    let messagesPerPage = 10
    
    
    var chatType : ChatType? {
        didSet{
            switch chatType {
            case .user(let user):
                handleInitialLoad()
            case .group(let group):
                fetchGroupMessagesForSelectedGroup(gid: group.id, page: 1)
            default:
                print("CHATVIEWMODELDEBUG: COULD NOT FIND GROUP/USER")
            }
        }
    }
    
    var navigationTitle: String {
        switch chatType{
        case .group(let group):
            return group.groupName
        case .user(let user):
            return user.username
        default:
            print("Could not set navigationtitle")
            return "Error"
        }
    }
    
    var isGroupOwner: Bool {
        if let currentUserInfo = userInformations?.first(where: { $0.userId == Int(AppConfig.instance.currentUserId ?? "")}) {
            return currentUserInfo.groupRole != GroupRoles.User.rawValue
        }
        return false
    }
    
    var groupOwnerId: Int? {
        if let ownerIndex = userInformations?.firstIndex(where: {$0.groupRole != GroupRoles.User.rawValue}) {
            return userInformations?[ownerIndex].userId
        }
        return nil
    }
    
    private func isEventStartedForNonStreamer(forGroup group: GroupCell, forUser userModel: GroupEventModelArray) -> Bool {
        return userModel.Array[0].groupId == group.id && userModel.Array[0].userId == EventResponse.eventAvaible.rawValue
    }
    
    private func isEventAvaible(forGroup group: GroupCell, forUser userModel: GroupEventModelArray) -> Bool {
        return userModel.Array[0].groupId == group.id
    }
    
    private func isEventFinished(forGroup group: GroupCell, forUser userModel: GroupEventModelArray) -> Bool {
        return userModel.Array[0].groupId == group.id && userModel.Array[0].userId == EventResponse.eventFinished.rawValue
    }
    
    private func isRelevantMessage(user: MessagesCellItem ,senderId: Int, receiverId: Int) -> Bool {
        guard let currentUid = Int(AppConfig.instance.currentUserId ?? "") else { return false }
        return (senderId == user.userId && receiverId == currentUid) ||
        (senderId == currentUid && receiverId == user.userId)
    }
    
    private func shouldDownloadImageForCell(messageItem: MessageItem) -> Bool {
        return messageItem.type == MessageTypes.image.rawValue && messageItem.imageData == nil
    }
    
    var shouldCreateGhostCar:  Bool {
        guard let raceDetails = raceDetails else { return false }
        guard let myId = AppConfig.instance.currentUserId else { return false}
        return !raceDetails.contains(where: {$0.userId == Int(myId)}) && !isGroupOwner
    }
    
    var currentPage = 1 {
        didSet {
            switch chatType {
            case .group(let group):
                fetchGroupMessagesForSelectedGroup(gid: group.id, page: currentPage)
            default:
                break
            }
        }
    }
    
    
    var player: AVPlayer?
    var playbackDurationToAdd: Double = 0.5
    var endPlaybackTime: CMTime?
    
    
    var messages : [MessageItem]?
    var newMessages : [MessageItem]?
    var socketMessages = [MessageItem]()
    var raceDetails : [GroupEventModel]? = []
    var newLocalMessageItems = [MessageItem]()
    
    var userItemCount : Int?
    var timeLeft : Int?
    
    var userInformations: [UserModel]?
    
    weak var delegate : ChatControllerDelegate?
    weak var seenDelegate : ChatMessageSeenDelegate?
    weak var photoSentDelegate : ChatControllerSentPhotoDelegate?
    
    
    func handleDismissView() {
        switch chatType {
        case .user(let user):
            AppConfig.instance.currentChat = nil
            handleMessageSeen(forUserId: user.userId)
        case .group(let group):
            player?.pause()
            AppConfig.instance.currentChat = nil
            rView?.handler?.stopTimer()
            rView?.raceViewDispose()
            SocketIOManager.shared().sendRaceEventRequest(groupId: String(group.id), seconds: "100",status: 1)
        default:
            break
        }
    }
    
    func updateRaceViewWithHandler(handler: RaceHandler) {
        guard let timeLeft = timeLeft else { return }
        guard let userItemCount = userItemCount else { return }
        rView?.handler?.countdownValue = timeLeft
        rView?.handler?.startTimer()
        rView?.ghostCarView.itemCount = userItemCount
        rView?.ghostCarView.updateItemCountForGhostCar(itemCount: userItemCount)
        
    }
    
    func createHandlerForNewEvent(raceDetails: [GroupEventModel], groupId: Int, countdownValue : Int) -> RaceHandler{
        let handler = RaceHandler(userModels: raceDetails,
                                  isAnyRaceAvailable: true,
                                  countdownValue: countdownValue,raceOwnerId: groupOwnerId)
        return handler
    }
    
    func hideVideoCell() {
        raceDetails = []
        rView?.raceViewDispose()
    }
        
    func fetchMessagesForSelectedUser(userId: String, lastMsgTime: String?, firstMsgTime: String?, completion: @escaping(Error?, [MessageItem]?) -> Void) {
        let lastMsgTime = lastMsgTime ?? nil
        let firstMsgTime = firstMsgTime ?? nil
        var output = [MessageItem]()
        print("Fetching messages from time: \(lastMsgTime ?? "nil")")
        MessagesService.instance.fetchMessagesForSpecificUser(userId: userId, lastMsgTime: lastMsgTime, firstMsgTime: firstMsgTime) { error, messages in
            if let error = error {
                completion(error,nil)
                return
            }
            
            guard let newMessages = messages, !newMessages.isEmpty else {
                print("FETCHLOG: No new messages fetched. Messages might exist in DB.")
                completion(nil, [MessageItem]())
                return
            }
            let dispatchGroup = DispatchGroup() // Creating a DispatchGroup

            for newMessage in newMessages {
                self.delegate?.newMessageDatasExist(status: ChatStatus.fetch.rawValue)
                output.append(newMessage)

                if newMessage.type == MessageTypes.image.rawValue, let imageURL = URL(string: newMessage.message) {
                    dispatchGroup.enter()  // Notify the group that a task has started
                    
                    ImageLoader.shared.getData(from: imageURL) { data, _, err in
                        if let err = err {
                            print("LOXS:Error fetching image data for message: \(newMessage.message). Error: \(err.localizedDescription)")
                            self.saveToLocal(newMessage, payloadDate: newMessage.sendTime, imageData: nil)
                            
                        } else if let imageData = data {
                            let index = output.firstIndex(where: { $0.sendTime == newMessage.sendTime })
                            output[index!].imageData = imageData
                            self.saveToLocal(newMessage, payloadDate: newMessage.sendTime, imageData: imageData)
                            
                        } else {
                            print("LOXS:Failed to process image for message: \(newMessage.message)")
                            self.saveToLocal(newMessage, payloadDate: newMessage.sendTime, imageData: nil)
                        }
                        dispatchGroup.leave()
                    }
                } else {
                    self.saveToLocal(newMessage, payloadDate: newMessage.sendTime, imageData: nil)
                }
            }
            
            dispatchGroup.notify(queue: .main) {  // This block will be triggered once all the async tasks inside the dispatchGroup have finished
                self.delegate?.newMessageDatasExist(status: ChatStatus.load.rawValue)
                completion(nil, output)
            }
        }
    }
    
    func handleInitialLoad() {
        switch chatType {
        case .user(let user):
            guard let currentUid = Int(AppConfig.instance.currentUserId ?? "") else { return }
            let localMessages = CoreDataManager.shared.fetchMessages(currentUserId: currentUid, userId: user.userId, before: Date().toTimestampString())
            if localMessages.first == nil {
                fetchMessagesForSelectedUser(userId: String(user.userId), lastMsgTime: nil, firstMsgTime: nil) { err, messages in
                    if err == nil, let messages = messages {
                        self.messages = messages
                        self.delegate?.datasReceived(error: nil)
                        print("debug6: we didnt have any new  messahe ")
                    }
                }
            }else{
                self.messages = convertEntityToItem(messageEntity: localMessages, forUser: user)
                print("debug6: we fetched new according to \(messages?.last?.sendTime)")
                print("debug6: we fetched new according to \(messages?.last?.message)")
                //ahmetdebug
                guard let lastMsgTime = messages?.last?.sendTime else { return }
                fetchMessagesForSelectedUser(userId: String(user.userId), lastMsgTime: lastMsgTime, firstMsgTime: nil) { err, messages in
                    if err == nil, let newMessages = messages {
                        self.messages?.append(contentsOf:newMessages)
                        self.delegate?.datasReceived(error: nil)
                        print("debug6: we fetched new \(newMessages)")
                    }
                }
            }

        default:
            break
        }
    }

    
    func addNewChatMessage(payloadDate: String, messageText: String, type:String, completion: @escaping(Error?) -> Void) {
        switch chatType {
        case .user(let user):
            guard let currentUid = Int(AppConfig.instance.currentUserId ?? "") else { return }
            if type == MessageTypes.text.rawValue {
                let myMessage = MessageItem(message: messageText, senderId: currentUid, receiverId: user.userId, sendTime: payloadDate,type: type, imageData: nil)
                messages?.append(myMessage)
                saveToLocal(myMessage, payloadDate: payloadDate,imageData: nil)
                seenDelegate?.chatMessageReceivedFromUser(error: nil, message: myMessage)
                completion(nil)
            }else{
                var myMessage = MessageItem(message: messageText, senderId:  currentUid, receiverId: user.userId, sendTime: payloadDate, type: type, imageData: nil)
                SDWebImageManager.shared.loadImage(with: URL(string:messageText), progress: nil) { image, data, error, _, _, _ in
                    if let error = error{
                        completion(error)
                    }
                    if error == nil {
                        myMessage.imageData = data
                        myMessage.message = "Photo"
                        self.messages?.append(myMessage)
                        self.saveToLocal(myMessage, payloadDate: payloadDate, imageData: data)
                        self.seenDelegate?.chatMessageReceivedFromUser(error: nil, message: myMessage)
                        completion(nil)
                    }
                }
            }
        default:
            break
        }
    }
    
    
    func fetchGroupMessagesForSelectedGroup(gid : Int, page: Int ){
        MessagesService.instance.getGroupMessages(groupId: gid, page: page) { err, messages in
            if err != nil {
                self.delegate?.datasReceived(error: err?.localizedDescription)
                return
            }
            if self.messages == nil{
                self.messages = messages?.messages
                self.newMessages = messages?.messages
                self.userInformations = messages?.users
                self.raceDetails = messages?.race
                self.userItemCount = messages?.userItemCount
                self.timeLeft = messages?.timeLeft
                self.delegate?.datasReceived(error: nil)
            }else{
                if self.newMessages?.count ?? 0 > 0 {
                    self.newMessages = messages?.messages
                    self.messages?.insert(contentsOf: self.newMessages!, at: 0)
                    self.delegate?.datasReceived(error: nil)
                }
            }
        }
    }
    
    
    func fetchNewMessages() {
        switch chatType {
        case .user(_):
            guard let sendTime = messages?.first?.sendTime else { return }
            fetchLocalMessages(beforeTime: sendTime)
        case .group(_ ):
            currentPage += 1
        default:
            break
        }
    }
    
    func handleMessageSeen(forUserId userId: Int) {
        MessagesService.instance.handleMessageSeen(forUserId: userId) { err in
            if let error = err {
                self.seenDelegate?.chatMessageSeen(error: error.localizedDescription, forId: nil)
                return
            }
            self.seenDelegate?.chatMessageSeen(error: nil, forId: userId)
        }
    }
    
    func sendMessage(myText: String?){
        guard let currentUserId = AppConfig.instance.currentUserId,
              let text = myText,
              !text.isEmpty,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }
        let message = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch chatType {
        case .group(let group):
            let myMessage = MessageItem(message: message, senderId: Int(currentUserId) ?? 0, receiverId: group.id, sendTime: Date().toString(),type:MessageTypes.text.rawValue, imageData: nil)
            messages?.append(myMessage)
            seenDelegate?.chatMessageReceivedFromUser(error: nil, message: myMessage)
            SocketIOManager.shared().sendGroupMessage(message: text, toGroup: String(group.id),type: myMessage.type)
        case .user(let user):
            SocketIOManager.shared().sendMessage(message: text, toUser: String(user.userId),type: MessageTypes.text.rawValue)
        default:
            print("CHATVIEWMODELDEBUG: COULD NOT SEND MESSAGE ")
        }
    }
    
    func finishEventForCurrentUser() {
        switch chatType {
        case .group(let group):
            SocketIOManager.shared().sendRaceEventRequest(groupId:String(group.id)
                                                          , seconds: "0", status: 1)
        default:
            break
        }
    }
    
    
    
    func handleEventActions(userModelArray: GroupEventModelArray, group: ChatType, completion: (ActionType) -> Void) {
        switch chatType {
        case .group(let group):
            if isEventStartedForNonStreamer(forGroup: group, forUser: userModelArray) {
                guard let raceDetails = raceDetails else { return }
                completion(.showVideoCell(raceDetails: raceDetails,
                                          groupId: group.id,
                                          countdownValue: userModelArray.Array[0].itemCount))
            }
            if isEventAvaible(forGroup: group, forUser: userModelArray) {
                completion(.updateUserCircles(newUser: userModelArray))
                
            }
            if isEventFinished(forGroup: group,forUser: userModelArray) {
                completion(.hideVideoCell)
            }
        default:
            break
        }
    }
    
    func handleSentPhotoAction(image: UIImage) {
        switch chatType {
        case .group(_):
            print("No image send for groups")
        case .user(let user):
            ImageManager.instance.convertUIImage(image: image, compressionQuality: 0.5) { err, MPData in
                if err == nil {
                    guard let MPData = MPData else { return }
                    MessagesService.instance.uploadImageToUser(userId: user.userId, imageData: MPData ) { err, response in
                        if err == nil {
                            guard let imageURL = response?.url else { return }
                            SocketIOManager.shared().sendMessage(message:imageURL , toUser: String(user.userId), type: MessageTypes.image.rawValue)
                        }else{
                        }
                    }
                }
            }
        default:
            break
        }
    }
    
    func saveToLocal(_ message: MessageItem,payloadDate: String, imageData: Data?) {
        switch chatType {
        case .user(_):
            CoreDataManager.shared.saveMessageEntity(message, payloadDate: payloadDate,imageData: imageData)
        default:
            break
        }
        
    }
    
    private func convertEntityToItem(messageEntity: [MessageEntity], forUser user: MessagesCellItem) -> [MessageItem] {
        var convertedMessages = [MessageItem]()
        for message in messageEntity {
            guard let messages = message.message,
                  let sendTime = message.sendTime,
                  let type = message.type,
                  isRelevantMessage(user: user, senderId: Int(message.senderId), receiverId: Int(message.receiverId))
            else { continue }
            
            let messageItem = MessageItem(message: messages,
                                          senderId: Int(message.senderId),
                                          receiverId: Int(message.receiverId),
                                          sendTime: sendTime,
                                          type: type,
                                          imageData: message.imageData)
        
            if shouldDownloadImageForCell(messageItem: messageItem) {
                downloadImageAndUpdateItem(messageItem) { updatedMessageItem in
                    if let updatedItem = updatedMessageItem {
                        convertedMessages.append(updatedItem)
                        print(updatedItem)
                    }
                }
            } else {
                convertedMessages.append(messageItem)
            }
        }
        
        let sortedMessages = convertedMessages.sorted {
            $0.sendTime.timeStampToDate() ?? Date() < $1.sendTime.timeStampToDate() ?? Date()
        }
        return sortedMessages
    }
    
    func areLastMessagesVisible(numberOfMessages: Int, indexPaths: [IndexPath], lastRow: Int) -> Bool {
        guard numberOfMessages > 0 else { return false }
        
        let thresholdRow = max(0, lastRow - numberOfMessages)
        
        for indexPath in indexPaths {
            if indexPath.row > thresholdRow {
                return true
            }
        }
        return false
    }

    
    func fetchLocalMessages(beforeTime payloadDate: String) {
        switch chatType {
        case .user(let user):
            guard let currentUid = Int(AppConfig.instance.currentUserId ?? "") else { return }
            let localMessages = CoreDataManager.shared.fetchMessages(currentUserId: currentUid, userId: user.userId, before: payloadDate)
            newLocalMessageItems = convertEntityToItem(messageEntity: localMessages, forUser: user)
            
            print("debug7: get local messages \(newLocalMessageItems)")
            let sortedMessages = newLocalMessageItems.sorted {
                $0.sendTime.timeStampToDate() ?? Date() < $1.sendTime.timeStampToDate() ?? Date()
            }
            
            if sortedMessages.isEmpty {
                print("debug7: since no local messages getting from backend")
                guard let sendTime = messages?.first?.sendTime else { return }
                guard let sendTime2 = messages?.first?.message else { return }
                fetchMessagesForSelectedUser(userId: String(user.userId), lastMsgTime: nil, firstMsgTime: sendTime) { error, messages in
                    if error == nil, let messages = messages {
                        if messages.isEmpty{
                            self.delegate?.datasReceived(error: ChatStatus.disableRefresh.rawValue)
                            print("debug7: No messages exist disable scroll")
                        }
                        self.messages?.insert(contentsOf: messages, at: 0)
                        self.delegate?.datasReceived(error: nil)
                        print("debug7: local messages appending \(messages)")
                        print("debug7: local message send time \(sendTime)")
                        print("debug7 local message message \(sendTime2)")
                    }
                    
                }
            }else{
                print("debug7: since local messages exist appending")
                self.messages?.insert(contentsOf: sortedMessages, at: 0)
                self.delegate?.datasReceived(error: nil)
            }
            
        default:
            break
        }
    }
    
    private func downloadImageAndUpdateItem(_ messageItem: MessageItem, completion: @escaping (MessageItem?) -> Void) {
        guard let imageURL = URL(string: messageItem.message) else {
            completion(nil)
            return
        }
        
        ImageLoader.shared.getData(from: imageURL) { data, _, err in
            if err == nil, let imageData = data {
                var updatedMessageItem = messageItem
                updatedMessageItem.imageData = data
                CoreDataManager.shared.updateImageDataInCoreData(forMessageWithSendTime: updatedMessageItem.sendTime, with: imageData)
                completion(updatedMessageItem)
            } else {
                completion(nil)
            }
        }
    }
    
    func didReceiveChatMessage(message: MessageItem) {
        switch chatType {
        case .user(let user):
            if message.senderId == user.userId || message.senderId == Int(AppConfig.instance.currentUserId ?? "") {
                messages?.append(message)

                if message.type == MessageTypes.text.rawValue {
                    self.photoSentDelegate?.userDidReceivePhotoMessage(error: nil)
                }else{
                    guard let url = URL(string:message.message) else { return }
                    guard let index = self.messages?.firstIndex(where: {$0.sendTime == message.sendTime}) else { return }

                    ImageLoader.shared.getData(from: url) { data, _, err in
                        if err == nil {
                            if let data = data{
                                CoreDataManager.shared.updateImageDataInCoreData(forMessageWithSendTime: message.sendTime, with: data)
                                self.messages?[index].imageData = data
                            }else{
                                CoreDataManager.shared.updateImageDataInCoreData(forMessageWithSendTime: message.sendTime, with: nil)
                                self.messages?[index].imageData = nil
                            }

                        }else{
                            self.photoSentDelegate?.userDidReceivePhotoMessage(error: err?.localizedDescription)
                        }
                    }
                    self.photoSentDelegate?.userDidReceivePhotoMessage(error: nil)
                }
            }
        default:
            break
        }
    }
}

