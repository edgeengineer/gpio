import Testing
@testable import GPIO

struct GPIOTests {
    
    @Test func testGPIOInitialization() async throws {
        let gpio = try GPIO(pin: 18, direction: .output)
    }
    
    @Test func testInvalidPinThrows() async throws {
        #expect(throws: GPIOError.invalidPin) {
            try GPIO(pin: -1, direction: .output)
        }
    }
    
    @Test func testGPIODirectionValues() async throws {
        #expect(GPIODirection.input.stringValue == "in")
        #expect(GPIODirection.output.stringValue == "out")
    }
    
    @Test func testGPIOValueRawValues() async throws {
        #expect(GPIOValue.low.rawValue == 0)
        #expect(GPIOValue.high.rawValue == 1)
    }
    
    @Test func testGPIOValueFromRawValue() async throws {
        #expect(GPIOValue(rawValue: 0) == .low)
        #expect(GPIOValue(rawValue: 1) == .high)
        #expect(GPIOValue(rawValue: 2) == nil)
    }
    
    #if os(Linux)
    @Test func testGPIOLinuxOperations() async throws {
        // Note: These tests require root privileges and actual GPIO hardware
        // They are here as examples of how to test GPIO functionality
        
        // Test initialization (exports and sets direction)
        let gpio = try GPIO(pin: 18, direction: .output)
        
        // Test value setting
        gpio.value = .high
        let value = try gpio.value
        #expect(value == .high)

        // Test changing direction
        gpio.direction = .input
        
        // Test cleanup (also done automatically on deinit)
        try gpio.cleanup()
    }
    #endif
    
    #if !os(Linux)
    @Test func testNonLinuxThrowsNotSupported() async throws {
        #expect(throws: GPIOError.notSupported) {
            _ = try GPIO(pin: 18, direction: .output)
        }
    }
    #endif
}