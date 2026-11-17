import XCTest

@testable import Fmsh

@MainActor
final class ModelTests: XCTestCase {
  func testIncrement() {
    let model = Model()
    model.increment()
    model.increment()
    XCTAssertEqual(model.count, 2)
  }
}
