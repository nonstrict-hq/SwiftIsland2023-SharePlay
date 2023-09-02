import XCTest
import CRDTs

extension Max: Random where Value: Random {
    static func random() -> Max<Value> {
        Self(.random())
    }
}

class MaxTests: XCTestCase {
    func testMax() {
        Max<Int>.testLaws(value: \.self)
    }
    
    func testBehavior() {
        var a = Max(10)
        var b = Max(0)
        b.merge(a)
        XCTAssertEqual(b.value, 10)
        a.value += 1
        b.value += 1
        a.merge(b)
        b.merge(a)
        XCTAssertEqual(a.value, 11)
        XCTAssertEqual(b.value, 11)
    }
}
