import Foundation

public struct GCounter<Value: Comparable & AdditiveArithmetic>: Equatable, Mergable {
    private var storage: [UUID: Max<Value>]
    private var siteID = UUID()
    
    public init(_ value: Value) {
        self.storage = [siteID: Max(value)]
    }
    
    public static func +=(lhs: inout Self, rhs: Value) {
        assert(rhs >= .zero, "GCounter cannot be decremented")
        lhs.storage[lhs.siteID, default: Max(.zero)].value += rhs
    }
    
    public var value: Value {
        storage.values.reduce(.zero) { $0 + $1.value }
    }
    
    mutating public func merge(_ other: Self) {
        storage.merge(other.storage)
    }
}

extension GCounter: Decodable where Value: Decodable { }
extension GCounter: Encodable where Value: Encodable { }
