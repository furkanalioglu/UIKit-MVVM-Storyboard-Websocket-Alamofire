//
//  MessageEntity+CoreDataProperties.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 1.09.2023.
//
//

import Foundation
import CoreData


extension MessageEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MessageEntity> {
        return NSFetchRequest<MessageEntity>(entityName: "MessageEntity")
    }

    @NSManaged public var message: String?
    @NSManaged public var senderId: Int16
    @NSManaged public var receiverId: Int16
    @NSManaged public var sendTime: String?
    @NSManaged public var type: String?
    @NSManaged public var imageData: Data?

}

extension MessageEntity : Identifiable {

}
