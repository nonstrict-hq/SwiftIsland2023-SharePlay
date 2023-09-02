import Foundation

public typealias SiteID = String

public struct RSeq<A>: Mergable {
    var siteID: SiteID
    var root: [Node<A>] = []
    var clock = 0
    
    public init(siteID: SiteID) {
        self.siteID = siteID
    }
    
    public mutating func insert(_ value: A, at idx: Int) {
        clock += 1
        let node = Node(id: NodeID(time: clock, siteID: siteID), value: value)
        if idx == 0 {
            root.insert(node, at: 0)
        } else {
            let allNodes = Array(self)
            let parent = allNodes[idx-1]
            for i in root.indices {
                root[i].insert(node, after: parent.id)
            }
        }
    }
    
    public var elements: [A] {
        map { $0.value }
    }
    
    public mutating func merge(_ other: RSeq<A>) {
        mergeNodes(lhs: &root, rhs: other.root)
        clock = Swift.max(clock, other.clock)
    }
}

private func mergeNodes<A>(lhs: inout [Node<A>], rhs: [Node<A>]) {
    for el in rhs {
        if let idx = lhs.firstIndex(where: { $0.id == el.id }) {
            lhs[idx].merge(el)
        } else {
            lhs.append(el)
        }
    }
    lhs.sort(by: { $0.id > $1.id })
}

extension RSeq: Sequence {
    public func makeIterator() -> AnyIterator<Node<A>> {
        var remainder = root
        
        return AnyIterator<Node> {
            guard !remainder.isEmpty else { return nil }
            let result = remainder.removeFirst()
            remainder.insert(contentsOf: result.children, at: 0)
            return result
        }
    }
}

struct NodeID: Equatable, Comparable, Codable, Hashable {
    var time: Int
    var siteID: SiteID
    
    static func <(_ lhs: Self, _ rhs: Self) -> Bool {
        if lhs.time < rhs.time { return true }
        if lhs.time > rhs.time { return false }
        return lhs.siteID > rhs.siteID
    }
}

public struct Node<A> {
    var id: NodeID
    var value: A
    var children: [Node<A>] =  []
    
    mutating func insert(_ node: Self, after parentID: NodeID) {
        if id == parentID {
            children.insert(node, at: 0)
        } else {
            for i in children.indices {
                children[i].insert(node, after: parentID)
            }
        }
    }
    
    mutating func merge(_ other: Node<A>) {
        assert(id == other.id)
        mergeNodes(lhs: &children, rhs: other.children)
    }
}

// Debug printing

extension RSeq {
    public var pretty: String {
        root.map { $0.pretty(level: 0) }.joined()
    }
}

extension Node {
    func pretty(level: Int) -> String {
        let prefix = String(repeating: " ", count: level*2)
        var result = "\(prefix)\(value)\n"
        result.append(children.map { $0.pretty(level: level+1) }.joined())
        return result
    }
}
