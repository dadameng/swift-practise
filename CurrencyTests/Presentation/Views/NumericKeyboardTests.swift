@testable import Currency
import XCTest

@MainActor
final class NumericKeyboardTests: XCTestCase {
    func testNumberInput() {
        let handler = KeyboardInputHandler(state: .initial, displayedText: "")
        try? handler.handleInput("1")
        XCTAssertEqual(handler.displayedText, "1")
    }

    func testDecimalInput() {
        let handler = KeyboardInputHandler(state: .numberInput, displayedText: "1")
        try? handler.handleInput(".")
        XCTAssertEqual(handler.displayedText, "1.")
    }

    func testDeleteInput() {
        let handler = KeyboardInputHandler(state: .numberInput, displayedText: "12")
        try? handler.handleInput("-")
        XCTAssertEqual(handler.displayedText, "1")
    }

    func testInputExceedingMaxLimit() {
        let handler = KeyboardInputHandler(state: .numberInput, displayedText: "88888888888888888888888888888888888888")
        var errorOccurred = false

        do {
            try handler.handleInput("8")
        } catch KeyboardInputError.maxLimit {
            errorOccurred = true
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertTrue(errorOccurred, "Input exceeding max limit should throw 'maxLimit' error")
    }

    func testDeleteInputWhenEmpty() {
        let handler = KeyboardInputHandler(state: .initial, displayedText: "")
        var errorOccurred = false

        do {
            try handler.handleInput("-")
        } catch KeyboardInputError.emptyDelete {
            errorOccurred = true
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertTrue(errorOccurred, "Deleting from an empty string should throw 'emptyDelete' error")
    }
}