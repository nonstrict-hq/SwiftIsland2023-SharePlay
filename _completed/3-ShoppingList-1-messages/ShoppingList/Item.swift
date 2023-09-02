//
//  Item.swift
//  ShoppingList
//
//  Created by Nonstrict on 2023-07-19.
//

import Foundation

struct Item: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
}
