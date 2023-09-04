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
        guard let sendTime = Int(message.sendTime) else { return }


        if message.type == "image" {
            if let imageData = message.imageData{
                newMessageModel.imageData = imageData
            }else if let imageUrl = URL(string: message.message){
                KingfisherManager.shared.retrieveImage(with: imageUrl) { result in
                    switch result {
                    case .success(let imageResult):
                        newMessageModel.imageData = imageResult.image.pngData()
                        print("trying to download")
                    case .failure:
                        newMessageModel.imageData = nil
                    }
                }
            }
            newMessageModel.senderId = Int16(message.senderId)
            newMessageModel.receiverId = Int16(message.receiverId)
            newMessageModel.sendTime = message.sendTime
            newMessageModel.message = message.message
            newMessageModel.type = message.type
            print("messagelog: \(newMessageModel)")
        }else{
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
    }
    
    func doesMessageExistWithSendTime(_ sendTime: Int) -> Bool {
        let fetchRequest: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "sendTime == %d", sendTime)
        fetchRequest.fetchLimit = 1 // We just need to check the existence, not fetch all
        
        do {
            let fetchedResults = try self.persistentContainer.viewContext.fetch(fetchRequest)
            return !fetchedResults.isEmpty
        } catch let error {
            print("Error fetching messages with sendTime: \(error.localizedDescription)")
            return false
        }
    }
    
    func fetchMessages(currentUserId: Int, userId: Int, page: Int) -> [MessageEntity] {
        let fetchRequest: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        
        let itemsPerPage = 10 // you can change this to whatever number you like
        fetchRequest.fetchLimit = 10
        fetchRequest.fetchOffset = (page - 1) * itemsPerPage // If page = 1, then offset is 0, which means it starts from the first record. If page = 2, it will skip the first 10 records, and so on.
        
        let predicate = NSPredicate(format: "(senderId == %d AND receiverId == %d) OR (senderId == %d AND receiverId == %d)", currentUserId, userId, userId, currentUserId)

        fetchRequest.predicate = predicate
        
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


