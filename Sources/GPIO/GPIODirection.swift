/// The direction configuration for a GPIO pin.
///
/// GPIO pins can be configured as either input or output pins. This enumeration
/// defines the two possible directions and provides the appropriate string values
/// for the Linux sysfs GPIO interface.
///
/// ## Usage
///
/// ```swift
/// // Configure a pin as output for controlling LEDs, relays, etc.
/// let outputPin = try GPIO(pin: 18, direction: .output)
///
/// // Configure a pin as input for reading buttons, sensors, etc.
/// let inputPin = try GPIO(pin: 23, direction: .input)
///
/// // Change direction after initialization
/// outputPin.direction = .input
/// ```
///
/// ## Hardware Considerations
///
/// - **Output pins** can drive external components like LEDs, relays, or other digital inputs
/// - **Input pins** can read the state of buttons, switches, sensors, or other digital outputs
/// - Changing direction may require a brief delay for the hardware to stabilize
/// - Some pins may have hardware limitations that prevent certain direction changes
public enum GPIODirection {
    /// Configure the GPIO pin as an input.
    ///
    /// Input pins are used to read digital signals from external components such as:
    /// - Push buttons and switches
    /// - Digital sensors (motion, proximity, etc.)
    /// - Output signals from other devices
    ///
    /// Input pins typically have high impedance and do not source or sink current.
    case input
    
    /// Configure the GPIO pin as an output.
    ///
    /// Output pins are used to control external components such as:
    /// - LEDs and indicator lights
    /// - Relays and switching circuits
    /// - Input signals to other devices
    /// - Motor control circuits (with appropriate drivers)
    ///
    /// Output pins can source or sink current within the platform's specifications.
    case output
    
    /// The string value used by the Linux sysfs GPIO interface.
    ///
    /// This property provides the string representation required by the Linux kernel's
    /// GPIO sysfs interface for setting pin direction.
    ///
    /// - Returns: `"in"` for input direction, `"out"` for output direction
    var stringValue: String {
        switch self {
        case .input: return "in"
        case .output: return "out"
        }
    }
}

extension GPIODirection: CustomStringConvertible {
    /// A textual representation of the GPIO direction.
    public var description: String {
        switch self {
        case .input: return "input"
        case .output: return "output"
        }
    }
}

extension GPIODirection: CaseIterable {
    /// All possible GPIO direction values.
    ///
    /// This can be useful for testing or UI generation:
    /// ```swift
    /// for direction in GPIODirection.allCases {
    ///     print("Direction: \(direction)")
    /// }
    /// ```
    public static var allCases: [GPIODirection] {
        return [.input, .output]
    }
}