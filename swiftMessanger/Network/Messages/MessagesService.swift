//
//  MessagesService.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 3.08.2023.
//

import Foundation
import Moya

class MessagesService {
    
    static let instance = MessagesService()
    
    private var provider = MoyaProvider<AuthAPI>(plugins: [NetworkLoggerPlugin(configuration: .init(formatter: .init(responseData: JSONResponseDataFormatter),
    logOptions: .verbose))])
    
    private init() {}
    
    //TODO: - USE MAP RATHER THAN DECODE LATER
    func fetchMessagesForSpecificUser(userId: String,page: Int, completion: @escaping(Error?, [MessageItem]?) -> Void) {
        provider.requestJSON(target: .getMessagesForId(userId: userId,page: page),retryCount: 1) { result in
            switch result {
            case .success(let response):
                let messagesResponse = try? JSONDecoder().decode([MessageItem].self, from: response.data)
                print("MESSAGELOG2:", messagesResponse)
                completion(nil, messagesResponse.self)
            case .failure(let error):
                print("MESSAGELOGError: \(error.localizedDescription)")
                completion(error, nil)
            }
        }
    }
    
    func handleMessageSeen(forUserId userId: Int,completion: @escaping(Error?) -> Void) {
        provider.requestJSON(target: .handleMessageSeen(userId: userId),retryCount: 1) { result in
            switch result {
            case .success(let response):
                print("SEENDEBUG: MESSAGE SEEN FOR USER \(userId)!")
                completion(nil)
            case .failure(let error):
                print("SEENDEBUG: COULD NOT SEEN MESSAGE FROM USER \(userId)")
                completion(error)
            }
        }
    }
}
