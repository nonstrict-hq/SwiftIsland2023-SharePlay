//
//  File.swift
//  
//
//  Created by Chris Eidhof on 18.03.22.
//

import Foundation
import XCTest
import CRDTs

fileprivate let testCycles = 1000

extension Int: Random {
    static func random() -> Int {
        Int.random(in: -10_000..<10_000)
    }
}

protocol Random {
    static func random() -> Self
}

extension Mergable where Self: Random {
    static func testLaws<Value: Equatable>(value: KeyPath<Self, Value>) {
        for _ in 0..<testCycles {
            let a = Self.random()
            let b = Self.random()
            let c = Self.random()
            XCTAssertEqual(a.merged(b)[keyPath: value], b.merged(a)[keyPath: value])
            XCTAssertEqual(a.merged(a)[keyPath: value], a[keyPath: value])
            XCTAssertEqual((a.merged(b)).merged(c)[keyPath: value], a.merged(b.merged(c))[keyPath: value])
        }
    }
}
