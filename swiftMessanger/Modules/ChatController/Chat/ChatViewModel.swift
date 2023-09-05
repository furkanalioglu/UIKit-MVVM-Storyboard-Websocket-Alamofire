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
                fetchLocalMessages(forPage: 1)
                fetchMessagesForSelectedUser(userId: String(user.userId), page: 1)
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
        if let currentUserInfo = userInformations?.first(where: { $0.id == Int(AppConfig.instance.currentUserId ?? "")}) {
            return currentUserInfo.groupRole != "User"
        }
        return false
    }
    
    var groupOwnerId: Int? {
        if let ownerIndex = userInformations?.firstIndex(where: {$0.groupRole != "User"}) {
            return userInformations?[ownerIndex].id
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
            case .user(let user):
                print("* FETCHHHHHH ")
                fetchLocalMessages(forPage: currentPage)
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
    
    func fetchMessagesForSelectedUser(userId: String, page: Int) {
        let lastMsgTime = Int(messages?.last?.sendTime ?? "") ?? 0
        print("*..... \(lastMsgTime)")
        
        MessagesService.instance.fetchMessagesForSpecificUser(userId: userId, page: page, lastMsgTime: lastMsgTime) { error, messages in
            print("lox: \(messages)")
            if let error = error {
                self.delegate?.datasReceived(error: error.localizedDescription)
                return
            }
            
            guard let newMessages = messages, newMessages.count > 0 else {
                print("FETCHLOG: MESSAGES EXIST IN DB")
                self.delegate?.newMessageDatasExist(status: "load")
                return
            }
            self.delegate?.newMessageDatasExist(status: "fetch")
            self.messages?.append(contentsOf: newMessages)
            print("FETCHLOG: FETCHING \(newMessages.count) NEW MESSAGES....")
            
            let downloadGroup = DispatchGroup()
            
            for newMessage in newMessages {
                if newMessage.type == "image" {
                    print("aaaaa",newMessage)
                    if let URL = URL(string: newMessage.message) {
                        downloadGroup.enter()
                        ImageLoader.shared.getData(from: URL) { data, _, err in
                            if let err = err {
                                print("aaaaaMESSAGE", err.localizedDescription)
                                return
                                
                            }
                            if let imageData = data {
                                if let index = self.messages?.firstIndex(where: { $0.sendTime == newMessage.sendTime }) {
                                    self.messages?[index].imageData = data
                                    self.saveToLocal(newMessage, payloadDate: newMessage.sendTime, imageData: imageData)
                                    print("aaaaaMESSAGE GET DATA FOR",index)
                                    
                                    
                                }else{
                                    print("COULD NOT GET DATA: \(newMessage.message)")
                                    
                                }
                                
                            }
                            downloadGroup.leave()
                            
                        }
                    } else {
                        self.saveToLocal(newMessage, payloadDate: newMessage.sendTime, imageData: nil)
                    }
                } else {
                    self.saveToLocal(newMessage, payloadDate: newMessage.sendTime, imageData: nil)
                }
            }
            
            
            downloadGroup.notify(queue: .main) {
                self.fetchMessagesForSelectedUser(userId: userId, page: page + 1)
            }
        }
        self.delegate?.newMessageDatasExist(status: "load")
    }
    
    
    
    func addNewChatMessage(payloadDate: String, messageText: String, type:String, completion: @escaping(Error?) -> Void) {
        switch chatType {
        case .user(let user):
            guard let currentUid = Int(AppConfig.instance.currentUserId ?? "") else { return }
            if type == MessageTypes.text.rawValue {
                let myMessage = MessageItem(message: messageText, senderId: currentUid, receiverId: user.userId, sendTime: payloadDate,type: type, imageData: nil)
                messages?.append(myMessage)
                saveToLocal(myMessage, payloadDate: payloadDate,imageData: nil)
                print("FETCHLOG: Saving From MY SEND MESSAGE \(myMessage)")
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
                        print("FETCHLOG: Saving From MY SEND MESSAGE \(myMessage)")
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
            currentPage += 1
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
            //TODO: - FIX TYPE ACCORDING TO MESSAGE
            let myMessage = MessageItem(message: message, senderId: Int(currentUserId) ?? 0, receiverId: group.id, sendTime: Date().toString(),type:MessageTypes.text.rawValue, imageData: nil)
            messages?.append(myMessage)
            seenDelegate?.chatMessageReceivedFromUser(error: nil, message: myMessage)
            SocketIOManager.shared().sendGroupMessage(message: text, toGroup: String(group.id),type: myMessage.type)
            //NO Local message save on groups
        case .user(let user):
            //USER SENT MESSAGE WITH ACK
            //MARK: - Send Message for user
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
                            guard let currentUid = AppConfig.instance.currentUserId else { return }
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
    
    
    
    func fetchLocalMessages(forPage page: Int) {
        switch chatType {
        case .user(let user):
            print("page: \(page)")
            guard let currentUid = Int(AppConfig.instance.currentUserId ?? "") else { return }
            let localMessages = CoreDataManager.shared.fetchMessages(currentUserId: currentUid, userId: user.userId, page: page)
            newLocalMessageItems = []
            
            for message in localMessages {
                guard let messages = message.message,
                      let sendTime = message.sendTime,
                      let type = message.type
                else { continue }
                
                let senderId = Int(message.senderId)
                let receiverId = Int(message.receiverId)
                
                if isRelevantMessage(user: user, senderId: senderId, receiverId: receiverId) {
                    var messageItem = MessageItem(message: messages,
                                                  senderId: senderId,
                                                  receiverId: receiverId,
                                                  sendTime: sendTime,
                                                  type: type,
                                                  imageData: message.imageData)
                    if shouldDownloadImageForCell(messageItem: messageItem){
                        guard let imageURL = URL(string:messageItem.message) else { continue }
                        ImageLoader.shared.getData(from: imageURL) { data, _, err in
                            if err == nil, let imageData = data {
                                messageItem.imageData = data
                                CoreDataManager.shared.updateImageDataInCoreData(forMessageWithSendTime: messageItem.sendTime, with: imageData)
                                let messageItem = MessageItem(message: messages,
                                                              senderId: senderId,
                                                              receiverId: receiverId,
                                                              sendTime: messageItem.sendTime,
                                                              type: type,
                                                              imageData: imageData)
                                self.newLocalMessageItems.append(messageItem)
                                CoreDataManager.shared.updateImageDataInCoreData(forMessageWithSendTime: messageItem.sendTime, with: imageData)
                                print("DOWNLOADEBUG:  Downlading image data: for \(messageItem)")
                            }
                        }
                    }else{
                        newLocalMessageItems.append(messageItem)
                    }
                    print("DOWNLOADEBUG: Download \(messageItem)")
                }
            }
            let sortedMessages = newLocalMessageItems.sorted { (message1, message2) -> Bool in
                guard let date1 = message1.sendTime.timeStampToDate(),
                      let date2 = message2.sendTime.timeStampToDate() else {
                    return false
                }
                return date1 < date2
            }
            
            print("DEBUGLOC:\(sortedMessages)")
            
            if messages == nil {
                self.messages = sortedMessages
                self.delegate?.datasReceived(error: nil)
            }else{
                self.messages?.insert(contentsOf: sortedMessages, at: 0)
                self.delegate?.datasReceived(error: nil)
            }
        default:
            break
        }
    }
    
    
    func fetchMessagesForPaginiton() {
        
    }
}

