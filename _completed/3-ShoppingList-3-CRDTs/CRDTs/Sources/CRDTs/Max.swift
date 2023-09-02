public struct Max<Value: Comparable>: Equatable, Mergable {
    public init(_ value: Value) {
        self.value = value
    }
    
    public var value: Value
    
    mutating public func merge(_ other: Self) {
        value = max(value, other.value)
    }
}

extension Max: Decodable where Value: Decodable { }
extension Max: Encodable where Value: Encodable { }
