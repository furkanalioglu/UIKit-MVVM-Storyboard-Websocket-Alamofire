//
//  MessagesViewModel.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 2.08.2023.
//

import Foundation



class MessagesViewModel {
let chatSegueId = "toShowChat"
let usersSegueId = "toShowUsers"

let cellId = "MessagesCell"

weak var delegate : MessagesControllerDelegate?

init() {
        getAllMessages()
    // coming from Splash
}


var messages: [MessagesCellItem]?




private func getAllMessages() {
    UserService.instance.getAllMessages { error, messages in
        if let error = error {
            print(error.localizedDescription)
            print("MESSAGECONTROLLERDEBUG:\(error.localizedDescription)")
            self.delegate?.messageDatasReceived(error: error)
        }else{
            self.messages = messages
            print("MESSAGECONTROLLERDEBUG:\(messages)")
            self.delegate?.messageDatasReceived(error: nil)

        }
        
    }
}

func generateMessageForUser(forUserId userId: Int, message: MessageItem){
    //MOVE THIS TO SOCKETIO DELEGATE
    UserService.instance.getSpecificUser(userId: userId) { error, user in
        if let error = error {
            print("specificdebug: \(error.localizedDescription)")
            self.delegate?.newMessageCellDataReceived(error: error)
            return
        }
        guard let user = user else { return }
        print(user)
        if message.receiverId == Int(AppConfig.instance.currentUserId ?? "") ?? 0 {
            let newMessage = MessagesCellItem(id:message.senderId, username: user.username, status: user.status, url: user.photoUrl, lastMsg: message.message,sendTime: Date().toString(), isSeen: false)
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
    messages?[index].lastMsg = message.message
    messages?[index].sendTime = message.sendTime
    print("MESSAGELOFGGG : GENERATE MESSAGE \(message)")
    messages?[index].isSeen = false
}

func handleIncomingMessage(message: MessageItem) {
    if message.senderId == Int(AppConfig.instance.currentUserId ?? "") ?? 0 {
        if let index = messages?.firstIndex(where: {$0.id == message.receiverId}) {
            print("MESSAGELOFGGG updaet message: \(message)")
            updateMessageAtIndex(index: index, withMessage: message)
        } else {
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
}
}
