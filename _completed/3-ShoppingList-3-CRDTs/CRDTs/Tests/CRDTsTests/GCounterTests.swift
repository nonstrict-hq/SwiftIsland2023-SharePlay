import XCTest
import CRDTs

extension GCounter: Random where Value: Random {
    static func random() -> GCounter<Value> {
        GCounter(.random())
    }
}

class GCounterTests: XCTestCase {
    func testLaws() {
        GCounter<Int>.testLaws(value: \.value)
    }
    
    func testBehavior() {
        var a = GCounter(10)
        var b = GCounter(0)
        b.merge(a)
        XCTAssertEqual(b.value, 10)
        a += 1
        b += 1
        a.merge(b)
        b.merge(a)
        XCTAssertEqual(a.value, 12)
        XCTAssertEqual(b.value, 12)
    }
}
