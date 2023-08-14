//
//  AppDelegate.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 31.07.2023.
//

import UIKit
import OneSignal

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        OneSignal.setLogLevel(.LL_VERBOSE, visualLevel: .LL_NONE)
        
        OneSignal.initWithLaunchOptions(launchOptions)
        OneSignal.setAppId("e61be51f-8367-4916-93e8-0dadcfffe0c2")
        
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            print("User accepted notifications: \(accepted)")
        })
        notificationEventHandler()
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        handleNotificationPayload(userInfo)
        print("DYNAMICLOG: handled")
    }
    
    func handleNotificationPayload(_ userInfo: [AnyHashable: Any]) {
        guard UIApplication.shared.applicationState != .active,
              let customOSPaylload = userInfo["custom"] as? [String: Any],
              let additionalData = customOSPaylload["a"] as? [String: Any],
              let pushToken = additionalData["senderId"]! as? Int
        else { fatalError("Error")}
        
        AppConfig.instance.dynamicLinkId = pushToken
        print("DYNAMICLOG LOG push token \(pushToken)")
        
        NotificationCenter.default.post(name: .notificationArrived, object: nil)
    }
    
    private func notificationEventHandler() {
        //        let notificationWillShowInForegroundBlock: OSNotificationWillShowInForegroundBlock = { notification, completion in
        //            guard let payload = userInfo["custom"] as? [String: Any],
        //                  let additionalData = payload["a"] as? [String: Any],
        //                  let pushToken = additionalData["senderId"] as? Int
        //            else { return }
        //            debugPrint("notificationWillShowInForegroundBlock")
        ////            dump(a)
        ////            if let type = a["type"] as? Int?,
        ////               let sender = a["senderId"] as? Int {
        ////                debugPrint("aaa", type, sender)
        ////            }
        //
        //            AppConfig.instance.dynamicLinkId = pushToken
        //            print("DYNAMICLOG LOG push token \(pushToken)")
        //
        //            NotificationCenter.default.post(name: .notificationArrived, object: nil)
        //
        //            completion(nil)
        //        }
        //
        //
        //        OneSignal.setNotificationWillShowInForegroundHandler(notificationWillShowInForegroundBlock)
        let notificationWillShowInForegroundBlock: OSNotificationWillShowInForegroundBlock = { notification, completion in
            //            guard let payload = notification.rawPayload as? [String: Any],
            //                  let custom = payload["custom"] as? [String: Any],
            //                  let a = custom["a"] as? [String: Any]
            //            else { return }
            debugPrint("notificationWillShowInForegroundBlock")
            //            dump(a)
            //            if let type = a["type"] as? Int?,
            //               let sender = a["senderId"] as? Int {
            //                debugPrint("aaa", type, sender)
            //            }
            
            completion(nil)
        }
        
        OneSignal.setNotificationWillShowInForegroundHandler(notificationWillShowInForegroundBlock)
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    //ios < 13
    func applicationDidEnterBackground(_ application: UIApplication) {
        SocketIOManager.shared().closeConnection()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("FOREGREOUNDDEBUG:enter foreground")
        checkAndReconnectSocketIfPossible()
    }
    
    func checkAndReconnectSocketIfPossible() {
        
    }
    
}

extension Notification.Name{
    static let notificationArrived = Notification.Name("notificationArrived")
    static let userDidEnterForeground = Notification.Name("userDidEnterForeground")
    static let newGroupCreated = Notification.Name("newGroupCreated")

}

