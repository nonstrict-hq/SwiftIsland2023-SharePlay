//
//  File.swift
//  
//
//  Created by Chris Eidhof on 05.04.22.
//

import Foundation

extension LWW: Encodable where Value: Encodable { }
extension LWW: Decodable where Value: Decodable { }
extension LWW: Equatable where Value: Equatable { }
extension LWW: Hashable where Value: Hashable { }


public struct LWW<Value>: Mergable {
    public init(siteID: SiteID, _ value: Value) {
        self.siteID = siteID
        self.value = value
    }
    
    var siteID: SiteID
    var clock = 0
    public var value: Value {
        didSet {
            clock += 1
        }
    }
    
    public mutating func merge(_ other: LWW<Value>) {
        guard other.clock > clock || (other.clock == clock && other.siteID > siteID) else {
            return
        }
        value = other.value
        clock = other.clock
    }
}
