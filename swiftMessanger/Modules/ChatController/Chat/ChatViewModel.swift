//
//  ChatViewModel.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 2.08.2023.
//

import Foundation
import AVFoundation

enum ChatType {
    case user(MessagesCellItem)
    case group(GroupCell)
}

enum EventResponse : Int {
    case eventAvaible = 0
    case eventFinished = -1
}

enum ActionType {
    case updateUserCircles(newUser: GroupEventModel?)
    case hideVideoCell
    case showVideoCell(raceDetails: [GroupEventModel], groupId: Int, countdownValue: Int)

}

class ChatViewModel {
    
    var rView: RaceView? = nil
    
    let cellNib = "ChatCell2"
    lazy var segueId = "toShowInformation"
    lazy var startSegueId = "toShowStart"
    
    var chatType : ChatType? {
        didSet{
            switch chatType {
            case .user(let user):
                fetchMessagesForSelectedUser(userId: String(user.id), page: 1)
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
    
    
    var currentPage = 1 {
        didSet {
            switch chatType {
            case .group(let group):
                fetchGroupMessagesForSelectedGroup(gid: group.id, page: currentPage)
            case .user(let user):
                fetchMessagesForSelectedUser(userId: String(user.id), page: currentPage)
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
    var timeLeft : Int?
    
    var userInformations: [UserModel]?
    
    weak var delegate : ChatControllerDelegate?
    weak var seenDelegate : ChatMessageSeenDelegate?
    
    func fetchMessagesForSelectedUser(userId: String, page: Int) {
        MessagesService.instance.fetchMessagesForSpecificUser(userId: userId, page: page) { error, messages in
            if let error = error {
                print("MESSAGELOG: \(error.localizedDescription)")
                self.delegate?.datasReceived(error: error.localizedDescription)
                return
            }
            if self.messages == nil {
                self.messages = messages
                self.newMessages = messages
                self.delegate?.datasReceived(error: nil)
                print("MESSAGES FETCHED : \(messages)")
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
                self.timeLeft = messages?.timeLeft
                self.delegate?.datasReceived(error: nil)
                print("MESSAGES FETCHED")
            }else{
                if self.newMessages?.count ?? 0 > 0 {
                    self.newMessages = messages?.messages
                    self.messages?.insert(contentsOf: self.newMessages!, at: 0)
                    self.delegate?.datasReceived(error: nil)
                    print("COULD NOT FETCG MSSAGES")
                    
                }
            }
        }
    }
    
    func fetchNewMessages() {
        currentPage += 1
        print("PAGEBUG: \(currentPage)")
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
            let myMessage = MessageItem(message: message, senderId: Int(currentUserId) ?? 0, receiverId: group.id, sendTime: Date().toString())
            messages?.append(myMessage)
            seenDelegate?.chatMessageReceivedFromUser(error: nil, message: myMessage)
            SocketIOManager.shared().sendGroupMessage(message: text, toGroup: String(group.id))
            print("MESSAGELOFGGG \(group.id)")
        case .user(let user):
            let myMessage = MessageItem(message: message, senderId: Int(currentUserId) ?? 0, receiverId: user.id, sendTime: Date().toString())
            messages?.append(myMessage)
            seenDelegate?.chatMessageReceivedFromUser(error: nil, message: myMessage)
            SocketIOManager.shared().sendMessage(message: text, toUser: String(user.id))
        default:
            print("CHATVIEWMODELDEBUG: COULD NOT SEND MESSAGE ")
        }
    }
    
    
    func configureVideo(ofType type: String = "mp4") -> AVPlayerLayer? {
        guard let path = Bundle.main.path(forResource:  "superanimation1_3" , ofType: type) else {
            debugPrint("superanimation1_3.\(type) not found")
            return nil
        }
        player = AVPlayer(url: URL(fileURLWithPath: path))
        return AVPlayerLayer(player: player)
    }
    
    
    func playVideoForDuration(_ duration: Double) {
        
        guard let player = self.player else { return }
        
        let currentTime = player.currentTime()
        let endTime = CMTimeAdd(currentTime, CMTimeMakeWithSeconds(duration, preferredTimescale: 600))
        endPlaybackTime = endTime
        
        player.play()
        
        player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.1, preferredTimescale: 600), queue: .main) { [weak self] time in
            guard let strongSelf = self else { return }
            
            if CMTimeCompare(time, strongSelf.endPlaybackTime!) != -1 { // if time is not less than endPlaybackTime
                strongSelf.player?.pause()
            }else{
            }
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
    
    func handleEventActions(userModel: GroupEventModel, group: ChatType, completion: (ActionType) -> Void) {
        switch chatType {
        case .group(let group):
            if userModel.groupId == group.id && userModel.userId != EventResponse.eventFinished.rawValue {
                if let existedUserIndex = rView?.handler?.userModels.firstIndex(where: {$0.userId == userModel.userId}) {
                    rView?.handler?.userModels[existedUserIndex].itemCount += 1
                    completion(.updateUserCircles(newUser: nil))
                } else {
                    rView?.handler?.userModels.append(userModel)
                    completion(.updateUserCircles(newUser: userModel))
                }
            }
                            
            if userModel.groupId == group.id && userModel.userId == EventResponse.eventAvaible.rawValue {
                guard var raceDetails = raceDetails else { return }
                guard let myId = Int(AppConfig.instance.currentUserId ?? "") else { return }
                if !raceDetails.contains(where: {$0.userId == myId}) && !isGroupOwner {
                    raceDetails.append(GroupEventModel(userId: myId, itemCount: 0, groupId: group.id))
                }
                completion(.showVideoCell(raceDetails: raceDetails, groupId: group.id, countdownValue: userModel.itemCount))
            }

            if userModel.groupId == group.id && userModel.userId == EventResponse.eventFinished.rawValue {
                completion(.hideVideoCell)
            }
        default:
            break
        }
    }

}
