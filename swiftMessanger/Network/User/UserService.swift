//
//  UserService.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 1.08.2023.
//

import Foundation
import Moya

class UserService {
    
    static let instance = UserService()
    
    private init() {}
    
    private var provider = MoyaProvider<AuthAPI>(plugins: [NetworkLoggerPlugin(configuration: .init(formatter: .init(responseData: JSONResponseDataFormatter),
                                                                                                    logOptions: .verbose))])
    
    
    func getAllUsers(completion: @escaping(Error?, [MessagesCellItem]?) -> Void) {
        provider.requestJSON(target: .getAllUsers,retryCount: 1) { apiResult in
            switch apiResult{
            case .success(let response):
                let usersResponse = try? JSONDecoder().decode([MessagesCellItem].self, from: response.data)
                print("DEBUG5:",usersResponse)
                completion(nil, usersResponse)
            case .failure(let error):
                print("DEBUG3: Failed to fetch all users\(error.localizedDescription)")
                completion(error,nil)
            }
        }
    }
    
    
    func getCurrentUser(completion: @escaping(Error?, CurrentUserModel?) -> Void) {
        provider.requestJSON(target: .getCurrentUser,retryCount: 1) { apiResult in
            switch apiResult{
            case .success(let response):
                let response = try? JSONDecoder().decode(CurrentUserModel.self, from: response.data)
                completion(nil,response)
            case .failure(let error):
                print("DEBUG3AG: Failed to fetch CURRENT USER \(error.localizedDescription)")
                completion(error, nil)
            }
        }
    }
    
    func updateCurrentUser(updates: UpdateUserModel ,completiton: @escaping(Error?) -> Void){
        provider.requestJSON(target: .updateCurrentUser(updateModel: updates),retryCount: 1) { apiResult in
            switch apiResult{
            case .success(let response):
                print(response.statusCode)
            case .failure(let error):
                print("DEBUG2::",error.localizedDescription)
            }
        }
    }
    
    func getAllMessages(completion: @escaping(Error?, [MessagesCellItem]?) -> Void) {
        provider.requestJSON(target: .getAllMessages,retryCount: 1) { apiResult in
            switch apiResult {
            case .success(let response):
                let response = try? JSONDecoder().decode([MessagesCellItem].self, from: response.data)
                completion(nil, response)
            case .failure(let error):
                print("DEBUG11:", error.localizedDescription)
                completion(error,nil)
            }
        }
    }
    
    func getSpecificUser(userId: Int, completion: @escaping(Error?, SpecificUser?) -> Void) {
        provider.requestJSON(target: .getSpecificUser(userId: userId),retryCount: 1) { apiResult in
            switch apiResult {
            case .success(let response):
                let response = try? JSONDecoder().decode(SpecificUser.self, from: response.data)
                completion(nil, response)
                print("SPECIFICDEBUG:", "\(response)")
            case .failure(let error):
                print("DEBUGSPECIFICUSER: \(error.localizedDescription)")
                completion(error,nil)
            }
        }
    }
    
    func getAllUsersForGroups(completion: @escaping(Error?, [MessagesCellItem]?) -> Void) {
        provider.requestJSON(target: .getAllGroupUsers) { apiResult in
            switch apiResult {
            case .success(let response):
                let usersResponse = try? response.map([MessagesCellItem].self)
            
                print("asdasdasd \(usersResponse)")
                completion(nil,usersResponse)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }
}
