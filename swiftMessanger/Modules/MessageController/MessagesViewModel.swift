//
//  MessagesViewModel.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 2.08.2023.
//

import Foundation

enum SegmentedIndex : Int {
    case messages, groups
}

class MessagesViewModel {
    //MARK: - Properties
    lazy var chatSegueId: String = { return "toShowChat" }()
    
    lazy var usersSegueId: String = { return "toShowUsers" }()
    
    lazy var newGroupSegueId : String = { return "toShowNewGroup" }()
    
    
    let cellId = "MessagesCell"
    let headerId = "MessagesHeader"
    
    weak var delegate : MessagesControllerDelegate?
    
    init() {
        getAllMessages()
    }
    
    
    var messages: [MessagesCellItem]?
    var groups : [GroupCell]?
    
    var currentSegment : SegmentedIndex = .messages
    
    func switchSegment(to segment: SegmentedIndex) {
        self.currentSegment = segment
        switch segment {
        case .messages:
            getAllMessages()
        case .groups:
            getAllGroups()
        }
    }
    
    var arrayCount : Int {
        switch currentSegment {
        case .messages:
            return messages?.count ?? 0
        case .groups:
            return groups?.count ?? 0
        }
    }
    
    
    
    func getAllMessages() {
        UserService.instance.getAllMessages { error, messages in
            if let error = error {
                print(error.localizedDescription)
                print("MESSAGECONTROLLERDEBUG:\(error.localizedDescription)")
                self.delegate?.messageDatasReceived(error: error)
            }else{
                self.messages = messages
                self.delegate?.messageDatasReceived(error: nil)
            }
        }
    }
    
    func getAllGroups(){
        MessagesService.instance.getAllGroups { err, results in
            if err != nil {
                self.delegate?.groupDatasReceived(error: err)
                return
            }
            self.groups = results
            self.delegate?.groupDatasReceived(error: nil)
        }
    }
    
    func generateMessageForUser(forUserId userId: Int, message: MessageItem){
        UserService.instance.getSpecificUser(userId: userId) { error, user in
            if let error = error {
                print("specificdebug: \(error.localizedDescription)")
                self.delegate?.newMessageCellDataReceived(error: error)
                return
            }
            guard let user = user else { return }
            print(user)
            if message.receiverId == Int(AppConfig.instance.currentUserId ?? "") ?? 0 {
                let newMessage = MessagesCellItem( id:message.senderId, username: user.username, status: user.status, url: user.photoUrl, lastMsg: message.message,sendTime: Date().toString(), isSeen: false)
                print("MESSAGELOFGGG generate message from current user: \(message)")
                print("NEW",newMessage)
                
                self.messages?.append(newMessage)
                self.delegate?.newMessageCellDataReceived(error: nil)
            }else{
                let newMessage = MessagesCellItem(id:message.receiverId, username: user.username, status: user.status, url: user.photoUrl, lastMsg: message.message,sendTime: Date().toString(),isSeen: true)
                self.messages?.append(newMessage)
                self.delegate?.newMessageCellDataReceived(error: nil)
            }
        }
    }
    
    
    private func updateMessageAtIndex(index: Int, withMessage message: MessageItem) {
        switch currentSegment {
        case .messages:
            messages?[index].lastMsg = message.message
            messages?[index].sendTime = Date().toString()
            print("GROUPDEBUG : GENERATE MESSAGE \(message)")
            messages?[index].isSeen = false
        case .groups:
            groups?[index].lastMsg = message.message
            groups?[index].sendTime = Date().toString()
            groups?[index].isSeen = false
            print("GROUPDEBUG UPDATING GROUPS ")
        }
    }
    
    func handleIncomingMessage(message: MessageItem) {
        switch currentSegment {
        case .messages:
            if message.senderId == Int(AppConfig.instance.currentUserId ?? "") ?? 0 {
                if let index = messages?.firstIndex(where: {$0.id == message.receiverId}) {
                    print("MESSAGELOFGGG updaet message: \(message)")
                    updateMessageAtIndex(index: index, withMessage: message)
                }
                else {
                    print("MESSAGELOFGGG generate message: \(message)")
                    generateMessageForUser(forUserId: message.receiverId, message: message)
                }
            } else {	
                if let index = messages?.firstIndex(where: {$0.id == message.senderId}) {
                    print("MESSAGELOFGGG generate message: \(message)")
                    updateMessageAtIndex(index: index, withMessage: message)
                } else {
                    print("MESSAGELOFGGG updaet message: \(message)")
                    generateMessageForUser(forUserId: message.senderId, message: message)
                }
            }
        case .groups:
            if message.senderId == Int(AppConfig.instance.currentUserId ?? "") ?? 0 {
                if let index = groups?.firstIndex(where: {$0.id == message.receiverId}) {
                    updateMessageAtIndex(index: index, withMessage: message)
                }else{
                    generateMessageForUser(forUserId: message.receiverId, message: message)
                }
            }else{
                if let index = groups?.firstIndex(where: {$0.id == message.receiverId}) {
                    updateMessageAtIndex(index: index, withMessage: message)
                }else{
                    generateMessageForUser(forUserId: message.senderId, message: message)
                }
            }
        }
    }

}
