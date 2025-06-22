/// The digital value of a GPIO pin.
///
/// GPIO pins can be in one of two digital states: low (0V) or high (3.3V/5V depending on the platform).
/// This enumeration represents these two states and provides the appropriate integer values
/// for the Linux sysfs GPIO interface.
///
/// ## Usage
///
/// ```swift
/// let gpio = try GPIO(pin: 18, direction: .output)
///
/// // Set pin to high state
/// gpio.value = .high
///
/// // Set pin to low state
/// gpio.value = .low
///
/// // Read current pin value
/// let currentValue = try gpio.value
/// print("Pin is \(currentValue == .high ? "HIGH" : "LOW")")
/// ```
///
/// ## Hardware Considerations
///
/// - **Low state** typically represents 0V (ground)
/// - **High state** represents the platform's logic level voltage:
///   - Raspberry Pi: 3.3V
///   - Some other platforms: 5V
/// - Voltage levels are platform-specific and should be verified before connecting external components
/// - Always check your platform's specifications to avoid damage to connected devices
public enum GPIOValue: Int {
    /// Low digital state (0V, ground).
    ///
    /// This represents the low logic level, typically 0 volts or ground potential.
    /// Used for:
    /// - Turning off LEDs or other indicators
    /// - Deactivating relays or switches
    /// - Sending a low signal to digital inputs
    /// - Representing a "false" or "off" state
    case low = 0
    
    /// High digital state (3.3V/5V depending on platform).
    ///
    /// This represents the high logic level, typically 3.3V on Raspberry Pi or 5V on other platforms.
    /// Used for:
    /// - Turning on LEDs or other indicators
    /// - Activating relays or switches
    /// - Sending a high signal to digital inputs
    /// - Representing a "true" or "on" state
    case high = 1
}

extension GPIOValue: CustomStringConvertible {
    /// A textual representation of the GPIO value.
    ///
    /// - Returns: `"high"` for high state, `"low"` for low state
    public var description: String {
        switch self {
        case .low: return "low"
        case .high: return "high"
        }
    }
}

extension GPIOValue: CaseIterable {
    /// All possible GPIO values.
    ///
    /// This can be useful for testing or iterating through states:
    /// ```swift
    /// for value in GPIOValue.allCases {
    ///     gpio.value = value
    ///     print("Set pin to \(value)")
    ///     // Add delay between states
    ///     usleep(500000) // 500ms
    /// }
    /// ```
    public static var allCases: [GPIOValue] {
        return [.low, .high]
    }
}

extension GPIOValue {
    /// The logical inverse of the current value.
    ///
    /// This property provides a convenient way to get the opposite value:
    /// - `.low.inverted` returns `.high`
    /// - `.high.inverted` returns `.low`
    ///
    /// Useful for toggling operations:
    /// ```swift
    /// gpio.value = gpio.value.inverted
    /// ```
    public var inverted: GPIOValue {
        switch self {
        case .low: return .high
        case .high: return .low
        }
    }
    
    /// Creates a GPIOValue from a boolean value.
    ///
    /// - Parameter bool: `true` maps to `.high`, `false` maps to `.low`
    /// - Returns: The corresponding GPIOValue
    ///
    /// ```swift
    /// let isEnabled = true
    /// gpio.value = GPIOValue(bool: isEnabled) // Sets to .high
    /// ```
    public init(bool: Bool) {
        self = bool ? .high : .low
    }
    
    /// Returns the boolean representation of the GPIO value.
    ///
    /// - Returns: `true` for `.high`, `false` for `.low`
    ///
    /// ```swift
    /// let gpioValue = GPIOValue.high
    /// if gpioValue.boolValue {
    ///     print("Pin is active")
    /// }
    /// ```
    public var boolValue: Bool {
        return self == .high
    }
}