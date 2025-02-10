//
//  ClipboardItem+CoreDataProperties.swift
//  ClipZen
//
//  Created by Samet Safkan on 10.02.2025.
//
//

import Foundation
import CoreData


extension ClipboardItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ClipboardItem> {
        return NSFetchRequest<ClipboardItem>(entityName: "ClipboardItem")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var content: Data?
    @NSManaged public var timestamp: Date?
    @NSManaged public var filename: String?
    @NSManaged public var fileExtension: String?

}

extension ClipboardItem : Identifiable {

}
