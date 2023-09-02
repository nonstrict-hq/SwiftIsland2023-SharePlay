//
//  File.swift
//  
//
//  Created by Chris Eidhof on 05.04.22.
//

import Foundation

extension LSeq: Encodable where Element: Encodable { }
extension LSeq: Decodable where Element: Decodable { }
extension LSeq: Equatable where Element: Equatable { }
extension LSeq: Hashable where Element: Hashable { }

public struct LSeq<Element: Mergable>: Mergable {
    public init(siteID: SiteID) {
        self.siteID = siteID
    }
    
    var siteID: SiteID
    var _elements: [LSeqNode<Element>] = []
    var clock: Int = 0
    
    mutating public func insert(_ value: Element, at idx: Int) {
        let parentID = idx > 0 ? _elements[nonDeletedIndices[idx-1]].id : nil
        let newID = NodeID(time: clock, siteID: siteID)
        let node = LSeqNode(parentID: parentID, id: newID, value: value)
        _insert(node)
        clock += 1
    }
    
    var nonDeletedIndices: [Int] {
        _elements.indices.filter { !_elements[$0].deleted }
    }
    
    mutating public func remove(at idx: Int) {
        _elements[nonDeletedIndices[idx]].deleted = true
    }
    
    mutating func _insert(_ node: LSeqNode<Element>) {
        let idx: Int
        if let pID = node.parentID {
            idx = _elements.firstIndex(where: { $0.id == pID })! + 1
        } else {
            idx = 0
        }
        for existingIx in _elements[idx...].indices {
            let existing = _elements[existingIx]
            if existing.id == node.id {
                _elements[existingIx].merge(node)
                return
            }
            if existing.id < node.id {
                _elements.insert(node, at: existingIx)
                return
            }
        }
        _elements.append(node)
    }
    
    public var elements: [Element] {
        Array(self)
    }
    
    public mutating func merge(_ other: LSeq<Element>) {
        for node in other._elements {
            _insert(node)
        }
    }
}

extension LSeq: Collection, RandomAccessCollection, MutableCollection {
    public struct Index: Comparable {
        var internalIndex: Int
        
        public static func <(lhs: Self, rhs: Self) -> Bool {
            lhs.internalIndex < rhs.internalIndex
        }
    }
    
    public var startIndex: Index {
        guard let ix = _elements.firstIndex(where: { !$0.deleted }) else { return endIndex }
        return Index(internalIndex: ix)
    }
    
    public var endIndex: Index {
        Index(internalIndex: _elements.endIndex)
    }
    
    public func index(after i: Index) -> Index {
        if let ix = _elements[(i.internalIndex+1)...].firstIndex(where: { !$0.deleted }) {
            return Index(internalIndex: ix)
        }
        return endIndex
    }
    
    public func index(before i: Index) -> Index {
        guard let ix = _elements[..<i.internalIndex].lastIndex(where: { !$0.deleted }) else {
            return startIndex // todo should we crash instead?
        }
        return Index(internalIndex: ix)
    }
    
    public subscript(position: Index) -> Element {
        get {
            _elements[position.internalIndex].value
        }
        set {
            _elements[position.internalIndex].value = newValue
        }
    }
}

struct LSeqNode<Element: Mergable> {
    var parentID: NodeID?
    var id: NodeID
    var value: Element
    var deleted = false
    
    mutating func merge(_ other: Self) {
        assert(parentID == other.parentID)
        assert(id == other.id)
        deleted = deleted || other.deleted
        value.merge(other.value)
    }
}

extension LSeqNode: Encodable where Element: Encodable { }
extension LSeqNode: Decodable where Element: Decodable { }
extension LSeqNode: Equatable where Element: Equatable { }
extension LSeqNode: Hashable where Element: Hashable { }
