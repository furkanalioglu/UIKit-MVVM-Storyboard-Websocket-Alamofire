//
//  SocketManager.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 2.08.2023.
//

import Foundation
import SocketIO
import Starscream

protocol SocketIOManagerDelegate: AnyObject {
    func didReceiveMessage(message: MessageItem)
}

protocol SocketIOManagerChatDelegate: AnyObject {
    func didReceiveChatMessage(message: MessageItem)
}
struct SocketURL {
    static let baseURL: URL = {
        guard let url = URL(string: "ws://10.82.0.93:3000/token=") else {
            fatalError("Invalid base URL.")
        }
        return url
    }()
}


class SocketIOManager {
    
    private static var privateShared : SocketIOManager?
    
    class func shared() -> SocketIOManager { // change class to final to prevent override
        guard let uwShared = privateShared else {
            privateShared = SocketIOManager()
            return privateShared!
        }
        return uwShared
    }
    
    private var manager: SocketManager?
    
    var socket: SocketIOClient?
    
    weak var delegate : SocketIOManagerDelegate?
    weak var chatDelegate : SocketIOManagerChatDelegate?
    
    private init() {}
    
    func establishConnection() {
//        guard self.manager == nil,
//              self.socket == nil,
//              AppConfig.instance.currentUser != nil
//        else {
//            print("DEBUGSOCKET: COULD NOT GET SOCKET")
//            return }
//        guard self.manager == nil else{ fatalError("SOCKET")}
//        guard self.socket == nil else { fatalError("SOCKET")}
        guard AppConfig.instance.currentUser != nil else {fatalError("SOCKET")}
                
        guard let token = UserDefaults.standard.string(forKey: userToken),
                let url = URL(string: "\(SocketURL.baseURL.absoluteString)\(token)") else {
              print("SOCKETDEBUG: Invalid token or URL.")
              return
          }
        print("SOCKETDEBUG:::: \(url)")
        
        
        let newManager = SocketManager(socketURL: url, config: [.log(true),
                                                                .forcePolling(false),
                                                                .forceWebsockets(true),
                                                                .connectParams(["token": token])

                
        ])
        
        let newSocket = newManager.defaultSocket
        self.manager = newManager
        self.socket = newSocket
        debugPrint("connecTParam", newManager.defaultSocket.manager?.socketURL ?? "")
        print("USER DEFAULTS IS \(UserDefaults.standard.string(forKey: userToken))")
        print("SOCKET DEBUG2: \(newManager.socketURL.absoluteString)")
        self.connectFunc()
        addHandlers()
    }
    
    func connectFunc() {
        guard self.socket?.status != .connected else { return }
        self.socket?.connect()
    }
    
    func closeConnection() {
        guard manager != nil,
              socket != nil else {
            print("SOCKETDEBUG::: Socket manager and/or socket is nil, aborting disconnection")
            return
        }
        
        print("SOCKETDEBUG: SOCKET DISCONNECTED")
        socket?.disconnect()
    }
    
    func sendMessage(message: String, toUser: String) {
        socket?.emit("message", Int(toUser) ?? 0, message)
    }
    
    private func addHandlers() {
        socket?.on(clientEvent: .connect) { data, _ in
            debugPrint("SOCKETDEBUG: connected to socket")
        }
        
        socket?.on("message") { (data, _) in
            print("SOCKETDEBUG: Raw message data: \(data)")

            if let data = data as? [Any] {
                let receiverId = data[3] as? Int ?? 0
                let message = data[1] as? String ?? ""
                let sendTime = data[2] as? String ?? ""
                let senderId = data[0] as? Int ?? 99

                let socketMessage = MessageItem(message: message, senderId: senderId, receiverId: receiverId, sendTime: sendTime)
 
                print("SOCKETDEBUG: SENT MESSAGE", socketMessage)
                self.delegate?.didReceiveMessage(message: socketMessage)
                self.chatDelegate?.didReceiveChatMessage(message: socketMessage)

            } else {
                print("SOCKETDEBUG: Data in received message has incorrect format.")
            }
        }

        
        socket?.on(clientEvent: .disconnect) { data, _ in
            debugPrint("disconnected")
        }
        
        socket?.on(clientEvent: .error) { err, _ in
            print("Error on connecting socket", err)
            if let error = err[0] as? String {
                print("Error",error)
            }
        }
    }
    
}
