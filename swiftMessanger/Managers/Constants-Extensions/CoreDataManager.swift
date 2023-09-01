import Foundation
import CoreData
import UIKit

enum MessageType: String {
    case text, image
}

enum CoreDataIds : String {
    case MessageEntity
}

final class CoreDataManager {
    
    struct Static {
        fileprivate static var instance: CoreDataManager?
    }
    
    class var shared: CoreDataManager {
        if let currentInstance = Static.instance {
            return currentInstance
        } else {
            Static.instance = CoreDataManager()
            return Static.instance!
        }
    }
    
    private func dispose() {
        CoreDataManager.Static.instance = nil
    }
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        
        let container = NSPersistentCloudKitContainer(name: CoreDataIds.MessageEntity.rawValue)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    func saveMessageEntity(_ message: MessageItem) {
        let newMessageModel = MessageEntity(context: self.persistentContainer.viewContext)
        
        if message.type == "image" {
            //            newMessageModel.imageData = message.imageData
            newMessageModel.senderId = Int16(message.senderId)
            newMessageModel.receiverId = Int16(message.receiverId)
            newMessageModel.sendTime = message.sendTime
            newMessageModel.message = "image"
            newMessageModel.type = message.type
        }else{
            newMessageModel.imageData = nil
            newMessageModel.message = message.message
            newMessageModel.receiverId = Int16(message.receiverId)
            newMessageModel.senderId = Int16(message.senderId)
            newMessageModel.sendTime = message.sendTime
            newMessageModel.type = message.type
        }
        
        saveContext()
        print("COREDEBUG: Saved Message Entity")
    }
    
    func fetchMessages() -> [MessageEntity] {
        let fetchRequest: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        do {
            print("COREDEBUG: Fetched Message Entities")
            return try self.persistentContainer.viewContext.fetch(fetchRequest)
        } catch let error {
            print("Error fetching images: \(error.localizedDescription)")
            return []
        }
    }

    
}


