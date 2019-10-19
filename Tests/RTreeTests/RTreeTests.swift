import XCTest
@testable import RTree

final class RTreeTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(RTree().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
