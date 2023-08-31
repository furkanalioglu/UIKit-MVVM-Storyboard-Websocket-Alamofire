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
    case logout
    case getAllGroupUsers
    case createGroup(groupModel : CreateGroupModel)
    case getAllGroups
    case getMessagesForGroup(groupId: Int, page: Int)
    case uploadImageToDB(image: MultipartFormBodyPart)
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
            return "chats/mainPage"
        case .updateCurrentUser:
            return "auth/profile/update"
        case .getMessagesForId(let userId, _):
            return "chats/\(userId)"
        case .getAllMessages:
            return "chats/friends"
        case .getSpecificUser(let userId):
            return "auth/profile/\(userId)"
        case .requestRefreshToken:
            return "auth/refreshToken"
        case .handleMessageSeen(let userId):
            return "chats/\(userId)/seen"
        case .logout:
            return "auth/logout"
        case .getAllGroupUsers:
            return "chats/allUsers"
        case .createGroup:
            return "chats/createGroup"
        case .getAllGroups:
            return "chats/groups"
        case .getMessagesForGroup(let groupId, _):
            return "chats/group/\(groupId)"
        case .uploadImageToDB(_):
            return "auth/profile/addPhoto"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .register, .login, .requestRefreshToken, .logout, .createGroup, .uploadImageToDB:
            return .post
        case .getCurrentUser, .getAllUsers, .getMessagesForId,.getAllMessages,.getSpecificUser, .handleMessageSeen, .getAllGroupUsers,.getAllGroups,.getMessagesForGroup:
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
        case .logout:
            return .requestPlain
        case .getAllGroupUsers:
            return .requestPlain
        case .createGroup(let groupModel):
            let parameters : [String : Any] = [
                "groupName" : groupModel.groupName,
                "ids": groupModel.ids
            ]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
        case .getAllGroups:
            return .requestPlain
        case .getMessagesForGroup(groupId: let groupId, page: let page):
            let parameters : [String: Any] = ["page": page]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
        case .uploadImageToDB(let image):
            return .uploadMultipartFormData([image])
        }
        
    }
    
    var headers: [String : String]? {
        switch self{
        case .getCurrentUser, .getAllUsers, .updateCurrentUser,.getMessagesForId,.getAllMessages,.getSpecificUser, .handleMessageSeen, .logout, .getAllGroupUsers,.createGroup,.getAllGroups,.getMessagesForGroup,.uploadImageToDB:
            return ["Authorization": "Bearer \(AuthService.instance.getToken() ?? "")"]
        case .requestRefreshToken:
            return ["Authorization": "Bearer \(AuthService.instance.getRefreshToken() ?? "")"]
        default:
            return [:]
        }
    }
    
    
    
}
