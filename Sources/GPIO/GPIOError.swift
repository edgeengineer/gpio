// LocalizedError is only available in Foundation, not FoundationEssentials
import Foundation

/// Errors that can occur during GPIO operations.
///
/// This enumeration defines all possible errors that can be thrown by GPIO operations,
/// providing detailed error information for debugging and error handling.
///
/// ## Usage
///
/// ```swift
/// do {
///     let gpio = try GPIO(pin: 18, direction: .output)
/// } catch GPIOError.invalidPin {
///     print("Invalid GPIO pin number")
/// } catch GPIOError.fileSystemError(let message) {
///     print("File system error: \(message)")
/// } catch {
///     print("Other error: \(error)")
/// }
/// ```
public enum GPIOError: Error {
    /// Failed to export the GPIO pin for use.
    ///
    /// This error occurs when the system cannot make a GPIO pin available for use,
    /// typically due to permission issues or if the pin is already in use by another process.
    case exportFailed
    
    /// Failed to unexport the GPIO pin.
    ///
    /// This error occurs when the system cannot release a GPIO pin from use,
    /// which may happen if the pin was not properly exported or if there are permission issues.
    case unexportFailed
    
    /// Failed to set the GPIO pin direction.
    ///
    /// This error occurs when the system cannot configure a GPIO pin as input or output,
    /// typically due to permission issues or hardware limitations.
    case directionSetFailed
    
    /// Failed to read or write the GPIO pin value.
    ///
    /// This error occurs when the system cannot read the current state of a pin
    /// or cannot set a pin to a specific value (high or low).
    case valueFailed
    
    /// The specified GPIO pin number is invalid.
    ///
    /// This error occurs when attempting to use a negative pin number or a pin number
    /// that doesn't exist on the current hardware platform.
    case invalidPin
    
    /// A file system operation failed.
    ///
    /// This error occurs when the underlying sysfs GPIO interface cannot be accessed,
    /// typically due to permission issues, missing GPIO support, or hardware problems.
    ///
    /// - Parameter message: A descriptive error message providing additional context about the failure.
    case fileSystemError(String)
    
    /// The current platform does not support GPIO operations.
    ///
    /// This error occurs when attempting to use GPIO functionality on non-Linux platforms
    /// or systems without GPIO sysfs support.
    case notSupported
}

extension GPIOError: LocalizedError {
    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case .exportFailed:
            return "Failed to export GPIO pin"
        case .unexportFailed:
            return "Failed to unexport GPIO pin"
        case .directionSetFailed:
            return "Failed to set GPIO pin direction"
        case .valueFailed:
            return "Failed to read or write GPIO pin value"
        case .invalidPin:
            return "Invalid GPIO pin number"
        case .fileSystemError(let message):
            return "GPIO file system error: \(message)"
        case .notSupported:
            return "GPIO operations not supported on this platform"
        }
    }
    
    /// A localized message describing the reason for the failure.
    public var failureReason: String? {
        switch self {
        case .exportFailed:
            return "The GPIO pin could not be made available for use"
        case .unexportFailed:
            return "The GPIO pin could not be released from use"
        case .directionSetFailed:
            return "The GPIO pin direction could not be configured"
        case .valueFailed:
            return "The GPIO pin value could not be accessed"
        case .invalidPin:
            return "The GPIO pin number is not valid for this hardware"
        case .fileSystemError:
            return "The GPIO sysfs interface is not accessible"
        case .notSupported:
            return "This platform does not support GPIO operations"
        }
    }
    
    /// A localized message providing "help" text if the user requests help.
    public var recoverySuggestion: String? {
        switch self {
        case .exportFailed, .unexportFailed, .directionSetFailed, .valueFailed, .fileSystemError:
            return "Try running with sudo or check GPIO permissions and hardware availability"
        case .invalidPin:
            return "Use a valid GPIO pin number for your hardware platform"
        case .notSupported:
            return "Use this library on a Linux system with GPIO sysfs support"
        }
    }
}