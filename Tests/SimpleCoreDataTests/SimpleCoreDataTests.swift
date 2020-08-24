import XCTest
@testable import SimpleCoreData

final class SimpleCoreDataTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SimpleCoreData().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
