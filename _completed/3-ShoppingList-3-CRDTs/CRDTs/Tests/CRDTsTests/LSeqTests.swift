//
//  File.swift
//  
//
//  Created by Chris Eidhof on 05.04.22.
//

import Foundation
import XCTest
import CRDTs

class LSeqTests: XCTestCase {
    func testSingleSite() {
        for _ in 0...1000 {
            var siteA = LSeq<Character>(siteID: "a")
            var control: [Character] = []
            for _ in 1...Int.random(in: 1...10) {
                if !control.isEmpty, Int.random(in: 0..<4) == 0 {
                    let ix = control.indices.randomElement()!
                    control.remove(at: ix)
                    siteA.remove(at: ix)
                } else {
                    let randomChar = Character(UnicodeScalar(UInt8.random(in: 65...90)))
                    let randomPos = Int.random(in: 0...(control.count))
                    control.insert(randomChar, at: randomPos)
                    siteA.insert(randomChar, at: randomPos)
                }
            }
            XCTAssertEqual(siteA.elements, control)
        }
    }

    func testMerge() {
        var siteA = LSeq<Character>(siteID: "a")
        var siteB = LSeq<Character>(siteID: "b")
        siteA.insert("a", at: 0)
        siteB.merge(siteA)
        XCTAssertEqual(siteA.elements, siteB.elements)
        siteA.insert("b", at: 1)
        siteB.insert("c", at: 1)
        siteA.merge(siteB)
        XCTAssertEqual(siteA.elements, ["a", "b", "c"])
    }
    
    func testRandomMerge() {
        for _ in 0...1000 {
            var siteA = LSeq<Character>(siteID: "a")
            var siteB = LSeq<Character>(siteID: "b")
            var siteC = LSeq<Character>(siteID: "c")
            siteA.randomMutation()
            siteB.merge(siteA)
            siteC.merge(siteA)
            XCTAssertEqual(siteA.elements, siteB.elements)
            siteA.randomMutation()
            siteB.randomMutation()
            siteC.randomMutation()
            XCTAssertEqual(siteA.merged(siteB).elements, siteB.merged(siteA).elements)
            XCTAssertEqual(siteA.merged(siteB).merged(siteC).elements, siteA.merged(siteB.merged(siteC)).elements)
            XCTAssertEqual(siteA.merged(siteA).elements, siteA.elements)
        }
    }
}

extension LSeq where Element == Character {
    mutating func randomMutation() {
        for _ in 0..<5 {
            if !elements.isEmpty, Int.random(in: 0..<4) == 0 {
                let ix = elements.indices.randomElement()!
                remove(at: ix)
            } else {
                let randomChar = Character(UnicodeScalar(UInt8.random(in: 65...90)))
                let randomPos = Int.random(in: 0...(elements.count))
                insert(randomChar, at: randomPos)
            }
        }
    }
}
