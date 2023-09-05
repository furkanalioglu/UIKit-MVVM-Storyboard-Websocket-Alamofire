//
//  Apo.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 1.08.2023.
//

import Foundation
import Moya
import UIKit
import SocketIO


enum API{
    static var baseURLString: String {
        return "http://chat-app-env.eba-ev2ugfcu.eu-central-1.elasticbeanstalk.com/api/v1/"
    }
    
//    static var baseURLString: String {
//        return "http://10.82.0.102:3000/api/v1/"
//    }
    
    static var baseURL : URL {
        guard let url = URL(string: baseURLString) else{
            fatalError("BASE URL IS NOT VALID")
        }
        return url
    }
}


extension TargetType {
    var baseURL: URL {
        return API.baseURL
    }
    
    
    var sampleData: Data {
        return Data()
    }
}
extension MoyaProvider {
    func requestJSON(target: Target, retryCount: Int = 1, completion: @escaping(Result<Response, MoyaError>) -> Void) -> Cancellable {
        return self.request(target, callbackQueue: .main) { result in
            switch result {
            case .success(let response):
                switch response.statusCode {
                case 200, 204:
                    print("LIFEDEBUG: \(response.statusCode)")
                    completion(.success(response))
                case 401:
                    print("LIFEDEBUG: USER GOT 401 FAILED", target.path)
                    
                    if target.path == "auth/refreshToken" {
                        RootManager.switchRoot(.auth)
                    } else {
                        AuthService.instance.requestRefreshToken { error, string in
                            if let error = error {
                                print("LIFEDEBUG CAN NOT REQUEST \(error.localizedDescription)")
                                AppConfig.instance.currentUser = nil
                                RootManager.switchRoot(.auth)
                            } else {
                                UserDefaults.standard.set(string?.accessToken, forKey: userToken)
                                self.request(target, completion: completion)
                            }
                        }
                    }
                default:
                    completion(.failure(.statusCode(response)))
                }
            case .failure(let error):
                print("LIFEDEBUG: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
            
    }
}


func JSONResponseDataFormatter(_ data: Data) -> String {
    do {
        let dataAsJSON = try JSONSerialization.jsonObject(with: data)
        let prettyData =  try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
        return String(data: prettyData, encoding: .utf8) ?? ""
    } catch {
        return String(data: data, encoding: .utf8) ?? ""
    }
}


