//
//  UsersService.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 1.08.2023.
//

import Foundation
import OneSignal
import Moya

final class AuthService {
    
    private var provider = MoyaProvider<AuthAPI>(plugins: [NetworkLoggerPlugin(configuration: .init(formatter: .init(responseData: JSONResponseDataFormatter),
    logOptions: .verbose))])
    
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: userToken)
    }
    
    func getRefreshToken() -> String? {
        print("REFRESHTOKEN",UserDefaults.standard.string(forKey: refreshToken))
        return UserDefaults.standard.string(forKey: refreshToken)
    }
    
    static public let instance = AuthService()
    
    func register(withUser user: RegisterModel, completion: @escaping(Error?) -> Void) {
        provider.requestJSON(target: .register(registerUser: user),retryCount: 1) { apiResult in
            switch apiResult{
            case .success(let response):
                print("DEBUG3:",response.statusCode)
                completion(nil)
            case .failure(let error):
                print("DEBUG2: \(error.localizedDescription)")
                completion(error)
            }
        }
    }
    	
    func login(withLoginModel loginModel: LoginModel, completion: @escaping(Error?) -> Void) {
        provider.requestJSON(target: .login(loginUser: loginModel),retryCount: 1) { apiResult in
            switch apiResult{
            case .success(let response):
                do {
                    //TODO: - USE MAP RATHER THAT DECODER
                    let loginResponse = try JSONDecoder().decode(LoginData.self, from: response.data)
                    UserDefaults.standard.set(loginResponse.accessToken, forKey: userToken)
                    UserDefaults.standard.set(loginResponse.userId, forKey: currentUserIdK)
                    print("IDKDEBUG: \(UserDefaults.standard.set(loginResponse.userId, forKey: currentUserIdK))")
                    UserDefaults.standard.set(loginResponse.refreshToken, forKey: refreshToken)                    
                    print(loginResponse.accessToken)
                    print("debugLOGINNNN: \(loginResponse.userId)")
                    completion(nil)
                } catch let error {
                    print("DEBUG: Failed to decode \(error)")
                    completion(error)
                }
                //TODO: savetolocal
            case .failure(let error):
                print("DEBUG2: \(error.localizedDescription)")
                completion(error)
            }
        }
    }
    
    func requestRefreshToken(completion: @escaping(Error?, TokenModel?) -> Void) {
        provider.requestJSON(target: .requestRefreshToken,retryCount: 1) { apiResult in
            switch apiResult{
            case .success(let response):
                do {
                    let decodedResponse = try JSONDecoder().decode(TokenModel.self, from: response.data)
                    print("RefreshDEBUG: \(decodedResponse)")
                    completion(nil,decodedResponse)
                }catch{
                    completion(error,nil)
                    print("RefreshDEBUG",error.localizedDescription)
                }
            case .failure(let error ):
                completion(error,nil)
            }
        }
    }
}
