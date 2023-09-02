//
//  File.swift
//  
//
//  Created by Chris Eidhof on 18.03.22.
//

import Foundation

extension Dictionary: Mergable where Value: Mergable {
    public mutating func merge(_ other: Dictionary<Key, Value>) {
        merge(other) { $0.merged($1) }
    }
}
