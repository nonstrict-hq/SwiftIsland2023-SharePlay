//
//  Messages.swift
//  ShoppingList
//
//  Created by Nonstrict on 2023-07-19.
//

import Foundation
import SwiftUI

struct InitialListMessage: Codable {
    let items: [Item]
}

enum ModificationMessage: Codable {
    case append(Item)
    case move(source: IndexSet, destination: Int)
    case remove(IndexSet)
}
