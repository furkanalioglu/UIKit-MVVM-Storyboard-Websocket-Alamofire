//
//  AuthAPI.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 1.08.2023.
//

import Foundation
import UIKit
import Moya

enum AuthAPI {
    case register(registerUser: RegisterModel)
    case login(loginUser: LoginModel)
    case getCurrentUser
    case getAllUsers
    case updateCurrentUser(updateModel : UpdateUserModel)
    case getMessagesForId(userId: String, page: Int)
    case getAllMessages
    case getSpecificUser(userId: Int)
    case requestRefreshToken
    case handleMessageSeen(userId: Int)
}

extension AuthAPI: TargetType {
    var path: String {
        switch self {
        case .register:
            return "auth/register"
        case .login:
            return "auth/login"
        case .getCurrentUser:
            return "auth/profile"
        case .getAllUsers:
            return "auth/mainPage"
        case .updateCurrentUser:
            return "auth/profile/update"
        case .getMessagesForId(let userId, _):
            return "chats/\(userId)"
        case .getAllMessages:
            return "auth/friends"
        case .getSpecificUser(let userId):
            return "auth/profile/\(userId)"
        case .requestRefreshToken:
            return "auth/refreshToken"
        case .handleMessageSeen(let userId):
            return "chats/\(userId)/seen"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .register, .login, .requestRefreshToken:
            return .post
        case .getCurrentUser, .getAllUsers, .getMessagesForId,.getAllMessages,.getSpecificUser, .handleMessageSeen:
            return .get
        case .updateCurrentUser:
            return .patch
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .register(let userModel):
            let registerParams : [String: Any] = [
                "username": userModel.email,
                "email": userModel.email,
                "password": userModel.password,
                "firstName": userModel.firstName,
                "lastName": userModel.lastName,
                "age":userModel.age,
                "gender":userModel.gender
            ]
            return .requestParameters(parameters: registerParams, encoding: URLEncoding.default)
        case .login(let loginModel):
            let loginParameters: [String: Any] = [
                "username": loginModel.username,
                "password": loginModel.password,
                "pushToken": loginModel.pushToken
            ]
            return .requestParameters(parameters: loginParameters, encoding: URLEncoding.default)
            
        case .getCurrentUser:
            return .requestPlain
        case .getAllUsers:
            return .requestPlain
        case .getMessagesForId(let userId, let page):
            let parameters : [String: Any] = ["page": page]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
        case .getAllMessages:
            return .requestPlain
            
        case .updateCurrentUser(let updateModel):
            let parameters : [String: Any] = [
                "firstName": updateModel.firstName,
                "lastName": updateModel.lastName,
                "status": updateModel.status,
                "age": updateModel.age
            ]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
            
        case .getSpecificUser:
            return .requestPlain
        case .requestRefreshToken:
            return .requestPlain
        case .handleMessageSeen:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        switch self{
        case .getCurrentUser, .getAllUsers, .updateCurrentUser,.getMessagesForId,.getAllMessages,.getSpecificUser, .handleMessageSeen:
            return ["Authorization": "Bearer \(AuthService.instance.getToken() ?? "")"]
        case .requestRefreshToken:
            print("LIFEDEBUG",AuthService.instance.getRefreshToken())
            return ["Authorization": "Bearer \(AuthService.instance.getRefreshToken() ?? "")"]
        default:
            return [:]
        }
    }
    
    
    
}