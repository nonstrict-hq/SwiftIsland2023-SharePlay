//
//  Messages.swift
//  ShoppingList
//
//  Created by Nonstrict on 2023-07-19.
//

import Foundation
import SwiftUI

struct InitialMessage: Codable {
    let modifications: Set<ModificationMessage>
}

struct ModificationMessage: Codable, Hashable {
    let clientID: UUID
    let order: Int
    let operation: ModificationOperation
}

enum ModificationOperation: Codable, Hashable {
    case append(Item)
    case move(source: Int, destination: Int)
    case remove(Int)
}
