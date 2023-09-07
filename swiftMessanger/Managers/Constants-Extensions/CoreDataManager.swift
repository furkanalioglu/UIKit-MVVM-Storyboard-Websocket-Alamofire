import Foundation
import CoreData
import UIKit
import Kingfisher

enum MessageType: String {
    case text, image
}

enum CoreDataIds : String {
    case MessageEntity
}


protocol LoadImageDelegate : AnyObject {
    func didCompleteLoadingImage(payloadDate:String, imageData: Data?)
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
    
    weak var loadImageDelegate : LoadImageDelegate?
    
    private func dispose() {
        CoreDataManager.Static.instance = nil
    }
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        
        let container = NSPersistentCloudKitContainer(name: CoreDataIds.MessageEntity.rawValue)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            print("asadasfdsgdafasfad",storeDescription)
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
//            context.perform {
                do {
                    try context.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                    let nserror = error as NSError
//                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
//    }
    
    
    func doesMessageExist(with sendTime: String) -> Bool {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "MessageEntity")
        fetchRequest.predicate = NSPredicate(format: "sendTime == %@", sendTime)
        
        do {
            let count = try self.persistentContainer.viewContext.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error checking for duplicates: \(error.localizedDescription)")
            return false
        }
    }
    

    func saveMessageEntity(_ message: MessageItem, payloadDate: String, imageData: Data?) {
        // Check if the message with the same sendTime already exists
        if !doesMessageExist(with: payloadDate) {
            let newMessageModel = MessageEntity(context: self.persistentContainer.viewContext)

            if message.type == MessageTypes.image.rawValue {
                newMessageModel.imageData = imageData
                newMessageModel.senderId = Int16(message.senderId)
                newMessageModel.receiverId = Int16(message.receiverId)
                newMessageModel.sendTime = payloadDate
                newMessageModel.message = message.message
                newMessageModel.type = message.type
                print("messagelog: \(newMessageModel)")
            } else {
                newMessageModel.imageData = nil
                newMessageModel.message = message.message
                newMessageModel.receiverId = Int16(message.receiverId)
                newMessageModel.senderId = Int16(message.senderId)
                newMessageModel.sendTime = message.sendTime
                newMessageModel.type = message.type
                print("messagelog2: \(newMessageModel)")
            }

            saveContext()
            print("COREDEBUG: Saved Message Entity")
        } else {
            print("COREDEBUG: Message with the same sendTime already exists. Skipping save.")
        }
    }

    
    
    func updateImageDataInCoreData(forMessageWithSendTime sendTime: String, with imageData: Data?) {
        let context = self.persistentContainer.viewContext
        context.perform {
            let fetchRequest: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "sendTime == %@", sendTime)
            do {
                let results = try context.fetch(fetchRequest)
                if let messageEntityToUpdate = results.first {
                    messageEntityToUpdate.imageData = imageData
                    // Save the changes to persist the updated imageData
                    do {
                        try context.save()
                        self.loadImageDelegate?.didCompleteLoadingImage(payloadDate: sendTime, imageData: imageData)
                        print("COREDEBUG: Updated Image Data for Message Entity with sendTime: \(sendTime)")
                        
                    } catch {
                        print("Error saving after updating image data: \(error.localizedDescription)")
                    }

                } else {
                    print("COREDEBUG: No Message Entity found with sendTime: \(sendTime)")
                }
            } catch {
                print("Error updating image data: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchMessages(currentUserId: Int, userId: Int, before sendTime: String) -> [MessageEntity] {
        let fetchRequest: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        let itemsPerPage = 10
        
        // The predicate now includes a condition for the sendTime
        let predicate = NSPredicate(format: "((senderId == %d AND receiverId == %d) OR (senderId == %d AND receiverId == %d)) AND sendTime < %@", currentUserId, userId, userId, currentUserId, sendTime)
        fetchRequest.predicate = predicate
        
        fetchRequest.fetchLimit = itemsPerPage
        
        let dateSortDescriptor = NSSortDescriptor(key: "sendTime", ascending: false)
        fetchRequest.sortDescriptors = [dateSortDescriptor]
        
        do {
            print("COREDEBUG: Fetched Message Entities")
            return try self.persistentContainer.viewContext.fetch(fetchRequest)
        } catch let error {
            print("Error fetching images: \(error.localizedDescription)")
            return []
        }
    }

}


