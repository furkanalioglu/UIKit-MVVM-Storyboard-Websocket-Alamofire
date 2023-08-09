//
//  ChatViewModel.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 2.08.2023.
//

import Foundation

class ChatViewModel {
    
    let cellNib = "ChatCell2"
    
    var user : MessagesCellItem? {
        didSet {
            guard let uid = user?.id else { return }
            print("FETCHING CONVERSATIONS DEBUG")
            fetchMessagesForSelectedUser(userId: String(uid),page: 1)
            print("FETCHING DEBUG: \(messages)")
        }
    }
    
    var currentPage = 1 {
        didSet {
            guard let uid = user?.id else { return }
            print("FETCHING CONVERSATIONS DEBUG")

            fetchMessagesForSelectedUser(userId: String(uid), page: currentPage)
        }
    }


    var messages : [MessageItem]?
    var newMessages : [MessageItem]?
    
    weak var delegate : ChatControllerDelegate?
    weak var seenDelegate : ChatMessageSeenDelegate?
    
    func fetchMessagesForSelectedUser(userId: String, page: Int) {
        MessagesService.instance.fetchMessagesForSpecificUser(userId: userId, page: page) { error, messages in
            if let error = error {
                print("MESSAGELOG: \(error.localizedDescription)")
                self.delegate?.datasReceived(error: error.localizedDescription)
                return
            }
            //FIRSTFETCH
            if self.messages == nil {
                self.messages = messages
                self.newMessages = messages
                self.delegate?.datasReceived(error: nil)
                print("MESSAGES FETCHED")
            }else{
                if self.newMessages?.count ?? 0 > 0 {
                    self.newMessages = messages
                    self.messages?.insert(contentsOf: self.newMessages!, at: 0)
                    self.delegate?.datasReceived(error: nil)
                    print("COULD NOT FETCG MSSAGES")

                }
            }
        }
    }
    
    func fetchNewMessages() {
        currentPage += 1
    }
    
    func handleMessageSeen(forUserId userId: Int) {
        MessagesService.instance.handleMessageSeen(forUserId: userId) { err in
            if let error = err {
                print("SEENDEBUG: ", err?.localizedDescription)
                self.seenDelegate?.chatMessageSeen(error: error.localizedDescription, forId: nil)
                return
            }
            self.seenDelegate?.chatMessageSeen(error: nil, forId: userId)
            print("MESSAGE SEEN SUCCESSS!!")
        }
    }
    
    func sendMessage(myText: String?){
        guard let currentUserId = AppConfig.instance.currentUserId,
              let receiverUserId = user?.id,
              let text = myText,
              !text.isEmpty,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            print("Error: Invalid data provided for sending a message.")
            return
        }
        print("DEBUG \(receiverUserId)")
        let message = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let myMessage = MessageItem(message: message, senderId: Int(currentUserId) ?? 0, receiverId: receiverUserId, sendTime: Date().toString())
        messages?.append(myMessage)

        seenDelegate?.chatMessageReceivedFromUser(error: nil, message: myMessage)
        SocketIOManager.shared().sendMessage(message: text, toUser: String(receiverUserId))
    }
}
