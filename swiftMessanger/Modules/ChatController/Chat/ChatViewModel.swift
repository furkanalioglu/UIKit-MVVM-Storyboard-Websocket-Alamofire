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
    case updateUserCircles(newUser: GroupEventModelArray?)
    case hideVideoCell
    case showVideoCell(raceDetails: [GroupEventModel], groupId: Int, countdownValue: Int)
    
}

class ChatViewModel {
    
    var rView:RaceView? = nil
    
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
    var userItemCount : Int?
    var timeLeft : Int?
    
    var userInformations: [UserModel]?
    
    weak var delegate : ChatControllerDelegate?
    weak var seenDelegate : ChatMessageSeenDelegate?
    
    func fetchMessagesForSelectedUser(userId: String, page: Int) {
        MessagesService.instance.fetchMessagesForSpecificUser(userId: userId, page: page) { error, messages in
            if let error = error {
                self.delegate?.datasReceived(error: error.localizedDescription)
                return
            }
            if self.messages == nil {
                self.messages = messages
                self.newMessages = messages
                self.delegate?.datasReceived(error: nil)
            }else{
                if self.newMessages?.count ?? 0 > 0 {
                    self.newMessages = messages
                    self.messages?.insert(contentsOf: self.newMessages!, at: 0)
                    self.delegate?.datasReceived(error: nil)
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
        currentPage += 1
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
    
    
    //MARK: - deprecated
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
            if CMTimeCompare(time, strongSelf.endPlaybackTime!) != -1 {
                strongSelf.player?.pause()
            }else{
            }
        }
    }
    //MARK: - deprecated
    
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
    
    //    func handleEventActions(userModelArray: GroupEventModelArray, group: ChatType, completion: (ActionType) -> Void) {
    //        switch chatType {
    //        case .group(let group):
    //            for userModel in userModelArray.Array {
    //                if isEventStartedForNonStreamer(forGroup: group, forUser: userModel){
    //                    guard var raceDetails = raceDetails,
    //                          let myId = Int(AppConfig.instance.currentUserId ?? "") else { return }
    //                    if shouldCreateGhostCar{
    //                        raceDetails.append(GroupEventModel(userId: myId,
    //                                                           itemCount: 0,
    //                                                           groupId: group.id,
    //                                                           carId: 4))
    //                    }
    //                    completion(.showVideoCell(raceDetails: raceDetails,
    //                                              groupId: group.id,
    //                                              countdownValue: userModel.itemCount))
    //                }
    //
    //
    //                if isEventAvaible(forGroup: group, forUser: userModel){
    //                    //                if let existedUserIndex = rView?.handler?.userModels.firstIndex(where: {$0.userId == userModel.userId}) {
    //                    //                    rView?.handler?.userModels[existedUserIndex] = userModel
    //                    //                    if let matchingCircle = rView?.userCircles.first(where: { $0.userId == userModel.userId }) {
    //                    //                        DispatchQueue.main.async {
    //                    //                            matchingCircle.updateItemCount(user: userModel)
    //                    //                        }
    //                    //                    }
    //                    //                    completion(.updateUserCircles(newUser: nil))
    //                    //                } else{
    //                    //                    if userModel.userId != EventResponse.eventAvaible.rawValue {
    //                    //                        //checking is it a user or not?
    //                    //                        rView?.handler?.userModels.append(userModel)
    //                    //                        completion(.updateUserCircles(newUser: userModel))
    //                    //                    }
    //                    //                }
    //                    rView?.handler?.userModels = userModelArray[i]
    //                }
    //                if isEventFinished(forGroup: group, forUser: userModel){
    //                    completion(.hideVideoCell)
    //                }
    //            }
    //        default:
    //            break
    //        }
    //
    //    }
    
}
