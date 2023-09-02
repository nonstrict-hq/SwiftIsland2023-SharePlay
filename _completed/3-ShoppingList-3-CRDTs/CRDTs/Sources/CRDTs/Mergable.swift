//
//  File.swift
//  
//
//  Created by Chris Eidhof on 15.02.22.
//

import Foundation

/**
 This protocol wants a `merge` function that's associative, commutative, and idempotent.
 
 - Associative: `a.merge(b.merge(c)) == (a.merge(b)).merge(c)`
 - Commutative: `a.merge(b) == b.merge(c)`
 - Idempotent: `a.merge(a) == a`
 */
public protocol Mergable {
    mutating func merge(_ other: Self)
}

extension Mergable {
    public func merged(_ other: Self) -> Self {
        var copy = self
        copy.merge(other)
        return copy
    }
}
