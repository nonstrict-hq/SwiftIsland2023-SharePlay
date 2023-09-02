//
//  File.swift
//  
//
//  Created by Chris Eidhof on 24.03.22.
//

import Foundation
import XCTest
import CRDTs

class RSeqTests: XCTestCase {
    func testSimple() {
        var seq = RSeq<Character>(siteID: "siteA")
        seq.insert("a", at: 0)
        seq.insert("b", at: 1)
        seq.insert("c", at: 1)
        XCTAssertEqual(seq.elements, ["a", "c", "b"])
    }
    
    func testMerge() {
        var siteA = RSeq<Character>(siteID: "siteA")
        siteA.insert("a", at: 0)
        siteA.insert("b", at: 1)
        
        var siteB = RSeq<Character>(siteID: "siteB")
        siteB.merge(siteA)
        XCTAssertEqual(siteA.elements, siteB.elements)
        
        siteA.insert("c", at: 2)
        siteA.insert("d", at: 3)
        
        siteB.insert("e", at: 2)
        siteB.insert("f", at: 3)
        
        XCTAssertEqual(String(siteA.merged(siteB).elements), "abcdef")
    }
    
    func testRandom() {
        for _ in 0..<1000 {
            var siteA = RSeq<Character>(siteID: "siteA")
            siteA.randomMutation()
            
            var siteB = RSeq<Character>(siteID: "siteB")
            siteB.merge(siteA)
            XCTAssertEqual(siteA.elements, siteB.elements)
            
            var siteC = RSeq<Character>(siteID: "siteC")
            siteC.merge(siteA)
            
            siteB.randomMutation()
            siteC.randomMutation()
            
            XCTAssertEqual(siteA.merged(siteB).elements, siteB.merged(siteA).elements)
            XCTAssertEqual(siteA.merged(siteB).merged(siteC).elements, siteA.merged(siteB.merged(siteC)).elements)
            XCTAssertEqual(siteA.merged(siteA).elements, siteA.elements)
        }
    }
}

extension RSeq where A == Character {
    mutating func randomMutation() {
        for _ in 0..<5 {
            let randomChar = Character(UnicodeScalar(UInt8.random(in: 65...90)))
            let randomPos = Int.random(in: 0...(elements.count))
            insert(randomChar, at: randomPos)
        }
    }
}
