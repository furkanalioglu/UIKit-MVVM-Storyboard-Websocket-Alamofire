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
            
            if let newMessages = messages, newMessages.count > 0 {
                self.messages?.append(contentsOf: newMessages)

                print("FETCHLOG: FETCHING \(newMessages.count) NEW MESSAGES....")
                for newMessage in newMessages {
                    self.saveToLocal(newMessage,payloadDate: newMessage.sendTime)
                }
                self.fetchMessagesForSelectedUser(userId: userId, page: page + 1)

            }else{
                print("FETCHLOG: MESSAGES EXIST IN DB")
                self.delegate?.datasReceived(error: nil)
            }
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
        case .user(let user):
            currentPage += 1
        case .group(let group):
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
            ImageManager.instance.convertUIImage(image: image, compressionQuality: 1.0) { err, MPData in
                if err == nil {
                    guard let MPData = MPData else { return }
                    MessagesService.instance.uploadImageToUser(userId: user.userId, imageData: MPData ) { err, response in
                        if err == nil {
                            guard let imageURL = response?.url else { return }
                            guard let currentUid = AppConfig.instance.currentUserId else { return }
                            
                            
//                            SDWebImageManager.shared.loadImage(with: URL(string:imageURL), progress: nil) { image, data, error, _, _, _ in
//                                if let error = error {
//                                    print("Error fetching image data: \(error.localizedDescription)")
//                                    return
//                                }
//                                print("asfddfadafsfads",imageURL)
//                                let myMessage = MessageItem(message: imageURL, senderId: Int(currentUid) ?? 0, receiverId: user.userId, sendTime: Date().toTimestampString(), type: MessageTypes.image.rawValue, imageData: data)
//                                self.messages?.append(myMessage)
//                                self.saveToLocal(myMessage,payloadDate: "")
//                                print("FETCHLOG: Saving From Photosent \(myMessage)")
                                SocketIOManager.shared().sendMessage(message:imageURL , toUser: String(user.userId), type: MessageTypes.image.rawValue)
//                                self.photoSentDelegate?.userDidSentPhoto(image: image, error: nil)
//                            }
                        }else{
//                            self.photoSentDelegate?.userDidSentPhoto(image: nil, error: err?.localizedDescription)
                        }
                    }
                }
            }
        default:
            break
        }
    }
    
    func saveToLocal(_ message: MessageItem,payloadDate: String) {
        switch chatType {
        case .user(_):
            CoreDataManager.shared.saveMessageEntity(message, payloadDate: payloadDate)
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
                    let messageItem = MessageItem(message: messages,
                                                  senderId: senderId,
                                                  receiverId: receiverId,
                                                  sendTime: sendTime,
                                                  type: type,
                                                  imageData: message.imageData)
                    newLocalMessageItems.append(messageItem)
                }
            }
            let sortedMessages = newLocalMessageItems.sorted(by: { ($0.sendTime.timeStampToDate()!) < ($1.sendTime.timeStampToDate()!) })
            print("DEBUGLOC:\(sortedMessages)")

            if messages == nil {
                self.messages = sortedMessages
                self.delegate?.datasReceived(error: nil)
            }else{
                
                self.messages?.insert(contentsOf: newLocalMessageItems, at: 0)
                self.delegate?.datasReceived(error: nil)
            }
        default:
            break
        }
    }
    
    func fetchMessagesForPaginiton() {
        
    }
}
    
