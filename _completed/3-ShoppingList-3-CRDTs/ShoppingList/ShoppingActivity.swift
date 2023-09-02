//
//  ShoppingActivity.swift
//  ShoppingList
//
//  Created by Nonstrict on 2023-07-19.
//

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif
import Foundation
import GroupActivities

// A type that represents a shopping list to edit with others.
struct ShoppingList: Hashable, Codable {
    var title: String
    var createdAt: Date
}

struct ShoppingActivity: GroupActivity {

    // The shopping list to edit.
    let shoppingList: ShoppingList

    // Metadata that the system displays to participants.
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = shoppingList.title
        metadata.subtitle = "Created at: \(shoppingList.createdAt.formatted())"
        metadata.type = .generic
#if canImport(UIKit)
        metadata.previewImage = UIImage(named: "apples")?.cgImage
        if #available(iOS 17, *) {
            metadata.type = .shopTogether
        }
#else
        metadata.previewImage = NSImage(named: "apples")?.cgImage(forProposedRect: nil, context: nil, hints: nil)
#endif
        return metadata
    }
}
