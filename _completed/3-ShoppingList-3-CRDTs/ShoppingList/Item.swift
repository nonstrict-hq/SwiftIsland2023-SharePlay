//
//  Item.swift
//  ShoppingList
//
//  Created by Nonstrict on 2023-07-19.
//

import Foundation
import CRDTs

struct Item: Identifiable, Codable, Hashable, Mergable {
    var id = UUID()
    var title: String

    func merge(_ other: Item) {
        assert(id == other.id)
        assert(title == other.title)
    }
}
