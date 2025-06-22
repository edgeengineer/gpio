#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if os(Linux)
import Glibc
#endif

/// A GPIO (General Purpose Input/Output) pin controller for Linux systems.
///
/// The `GPIO` class provides a Swift interface to Linux's sysfs GPIO system,
/// allowing you to control digital pins on embedded Linux devices such as
/// Raspberry Pi, Jetson Nano, and other single-board computers.
///
/// ## Overview
///
/// GPIO pins can be configured as either input or output pins:
/// - **Input pins** read digital signals from external components (buttons, sensors)
/// - **Output pins** control external components (LEDs, relays, motors)
///
/// ## Basic Usage
///
/// ```swift
/// import GPIO
///
/// do {
///     // Create an output pin for controlling an LED
///     let ledPin = try GPIO(pin: 18, direction: .output)
///     
///     // Turn LED on
///     ledPin.value = .high
///     
///     // Turn LED off
///     ledPin.value = .low
///     
///     // Toggle LED state
///     try ledPin.toggle()
///     
///     // Clean up (also done automatically on deinit)
///     try ledPin.cleanup()
/// } catch {
///     print("GPIO Error: \(error)")
/// }
/// ```
///
/// ## Platform Compatibility
///
/// This library works on Linux systems with GPIO sysfs support:
/// - **Raspberry Pi** (Zero 2W, 4, 5) - Use BCM GPIO numbering
/// - **Jetson Orin Nano** - Use Jetson-specific GPIO numbering
/// - **Generic Linux** - Any system with `/sys/class/gpio/` interface
///
/// ## Safety and Resource Management
///
/// - GPIO pins are automatically cleaned up when the object is deallocated
/// - Manual cleanup is available via the `cleanup()` method
/// - Only one GPIO object should control a specific pin at a time
/// - Root privileges are typically required for GPIO operations
///
/// ## Error Handling
///
/// All GPIO operations can throw ``GPIOError`` for various failure conditions:
/// - Permission issues (run with `sudo` or configure udev rules)
/// - Invalid pin numbers
/// - Hardware or driver problems
/// - Platform incompatibility
///
/// ## Thread Safety
///
/// This class is not thread-safe. If you need to access the same GPIO pin
/// from multiple threads, you must provide your own synchronization.
public class GPIO {
    /// The GPIO pin number.
    ///
    /// This is the platform-specific GPIO number:
    /// - On Raspberry Pi: BCM GPIO number (not physical pin number)
    /// - On Jetson: Jetson GPIO chip number
    /// - On other platforms: Check platform documentation
    private let pin: Int
    
    /// The base path to the Linux sysfs GPIO interface.
    ///
    /// This path provides access to the kernel's GPIO subsystem through
    /// the filesystem interface at `/sys/class/gpio/`.
    private let basePath = "/sys/class/gpio"
    
    /// The current direction of the GPIO pin (input or output).
    ///
    /// Setting this property automatically reconfigures the hardware pin direction.
    /// If the direction change fails, the error is silently ignored - use
    /// ``setDirection(_:)`` directly if you need error handling.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let gpio = try GPIO(pin: 18, direction: .output)
    /// 
    /// // Change to input to read a sensor
    /// gpio.direction = .input
    /// let sensorValue = try gpio.value
    /// 
    /// // Change back to output to control an LED
    /// gpio.direction = .output
    /// gpio.value = .high
    /// ```
    public var direction: GPIODirection {
        didSet {
            try? setDirection(direction)
        }
    }
    
    /// Creates a new GPIO pin controller and configures it for use.
    ///
    /// This initializer performs several operations:
    /// 1. Validates the pin number
    /// 2. Exports the pin for use (makes it available to userspace)
    /// 3. Sets the pin direction
    ///
    /// The pin will be automatically cleaned up when this object is deallocated,
    /// but you can also call ``cleanup()`` explicitly.
    ///
    /// - Parameters:
    ///   - pin: The GPIO pin number (platform-specific numbering)
    ///   - direction: The pin direction (input or output)
    ///
    /// - Throws: ``GPIOError`` if the pin cannot be initialized:
    ///   - ``GPIOError/invalidPin`` if the pin number is negative
    ///   - ``GPIOError/exportFailed`` if the pin cannot be exported
    ///   - ``GPIOError/directionSetFailed`` if the direction cannot be set
    ///   - ``GPIOError/fileSystemError(_:)`` for filesystem access issues
    ///   - ``GPIOError/notSupported`` on non-Linux platforms
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Raspberry Pi: Create output pin using BCM numbering
    /// let ledPin = try GPIO(pin: 18, direction: .output)
    ///
    /// // Jetson: Create input pin using Jetson numbering
    /// let buttonPin = try GPIO(pin: 422, direction: .input)
    /// ```
    ///
    /// ## Platform Notes
    ///
    /// - **Raspberry Pi**: Use BCM GPIO numbers, not physical pin numbers
    /// - **Jetson**: Check `/sys/kernel/debug/gpio` for pin mapping
    /// - **Root privileges**: Usually required for GPIO operations
    public init(pin: Int, direction: GPIODirection) throws {
        guard pin >= 0 else {
            throw GPIOError.invalidPin
        }
        self.pin = pin
        self.direction = direction
        try export()
        try setDirection(direction)
    }
    
    /// Automatically cleans up the GPIO pin when the object is deallocated.
    ///
    /// This ensures that GPIO resources are properly released even if
    /// ``cleanup()`` is not called explicitly. The cleanup operation
    /// is performed silently - any errors are ignored.
    deinit {
        try? unexport()
    }
    
    /// Exports the GPIO pin for userspace access.
    ///
    /// This method makes a GPIO pin available for use by writing the pin number
    /// to the kernel's export file. After export, the pin's control files become
    /// available in `/sys/class/gpio/gpio{pin}/`.
    ///
    /// This method is called automatically during initialization and typically
    /// doesn't need to be called manually.
    ///
    /// - Throws: ``GPIOError`` if the export operation fails:
    ///   - ``GPIOError/exportFailed`` if the pin cannot be exported
    ///   - ``GPIOError/fileSystemError(_:)`` for filesystem access issues
    ///   - ``GPIOError/notSupported`` on non-Linux platforms
    ///
    /// ## Implementation Details
    ///
    /// The method waits up to 100ms for the pin directory to appear after export,
    /// as there can be a brief delay in the kernel creating the control files.
    public func export() throws {
        #if os(Linux)
        let exportPath = "\(basePath)/export"
        try writeToFile(path: exportPath, value: "\(pin)")
        
        // Wait for the pin directory to be created
        let pinPath = "\(basePath)/gpio\(pin)"
        var attempts = 0
        while !FileManager.default.fileExists(atPath: pinPath) && attempts < 10 {
            usleep(10000) // 10ms
            attempts += 1
        }
        
        if !FileManager.default.fileExists(atPath: pinPath) {
            throw GPIOError.exportFailed
        }
        #else
        throw GPIOError.notSupported
        #endif
    }
    
    /// Unexports the GPIO pin, releasing it from userspace control.
    ///
    /// This method releases a GPIO pin by writing the pin number to the kernel's
    /// unexport file. After unexport, the pin's control files are removed and
    /// the pin becomes unavailable for userspace access.
    ///
    /// This method is called automatically during cleanup and typically
    /// doesn't need to be called manually unless you want to explicitly
    /// release the pin before object deallocation.
    ///
    /// - Throws: ``GPIOError`` if the unexport operation fails:
    ///   - ``GPIOError/unexportFailed`` if the pin cannot be unexported
    ///   - ``GPIOError/fileSystemError(_:)`` for filesystem access issues
    ///   - ``GPIOError/notSupported`` on non-Linux platforms
    public func unexport() throws {
        #if os(Linux)
        let unexportPath = "\(basePath)/unexport"
        try writeToFile(path: unexportPath, value: "\(pin)")
        #else
        throw GPIOError.notSupported
        #endif
    }
    
    /// Sets the GPIO pin direction (input or output).
    ///
    /// This method configures whether the pin should be used for reading
    /// (input) or writing (output) digital signals. The direction can be
    /// changed at any time after the pin is exported.
    ///
    /// - Parameter direction: The desired pin direction
    ///
    /// - Throws: ``GPIOError`` if the direction cannot be set:
    ///   - ``GPIOError/directionSetFailed`` if the direction change fails
    ///   - ``GPIOError/fileSystemError(_:)`` for filesystem access issues
    ///   - ``GPIOError/notSupported`` on non-Linux platforms
    ///
    /// ## Usage Notes
    ///
    /// - Changing direction may require a brief delay for hardware stabilization
    /// - Some pins may have hardware restrictions on direction changes
    /// - You can also use the ``direction`` property for automatic direction setting
    ///
    /// ## Example
    ///
    /// ```swift
    /// let gpio = try GPIO(pin: 18, direction: .output)
    /// 
    /// // Change to input for reading
    /// try gpio.setDirection(.input)
    /// let inputValue = try gpio.value
    /// 
    /// // Change back to output for writing
    /// try gpio.setDirection(.output)
    /// gpio.value = .high
    /// ```
    public func setDirection(_ direction: GPIODirection) throws {
        #if os(Linux)
        let directionPath = "\(basePath)/gpio\(pin)/direction"
        try writeToFile(path: directionPath, value: direction.stringValue)
        #else
        throw GPIOError.notSupported
        #endif
    }
    
    /// The current digital value of the GPIO pin.
    ///
    /// This property allows reading the pin's digital state:
    /// - For **input pins**: Returns the current signal level (high or low)
    /// - For **output pins**: Returns the current output level (high or low)
    ///
    /// To write values to output pins, use the ``setValue(_:)`` method.
    ///
    /// ## Reading Values (Input Mode)
    ///
    /// ```swift
    /// let buttonPin = try GPIO(pin: 23, direction: .input)
    /// let isPressed = try buttonPin.value == .high
    /// print("Button is \(isPressed ? "pressed" : "not pressed")")
    /// ```
    ///
    /// ## Reading Values (Output Mode)
    ///
    /// ```swift
    /// let ledPin = try GPIO(pin: 18, direction: .output)
    /// 
    /// // Set LED state using setValue
    /// try ledPin.setValue(.high)
    /// 
    /// // Read current output state
    /// let currentState = try ledPin.value
    /// print("LED is \(currentState == .high ? "on" : "off")")
    /// ```
    ///
    /// - Throws: ``GPIOError`` when reading fails:
    ///   - ``GPIOError/valueFailed`` if the value cannot be read or parsed
    ///   - ``GPIOError/fileSystemError(_:)`` for filesystem access issues
    ///   - ``GPIOError/notSupported`` on non-Linux platforms
    ///
    /// ## Hardware Considerations
    ///
    /// - **High state**: Platform voltage level (3.3V on Raspberry Pi, varies on others)
    /// - **Low state**: Ground level (0V)
    /// - **Pull resistors**: May be needed for reliable input reading
    /// - **Current limits**: Check platform specifications for output current limits
    public var value: GPIOValue {
        get throws {
            try getValue()
        }
    }
    
    /// Sets the GPIO pin to a specific digital value.
    ///
    /// This method directly sets the output state of a GPIO pin configured
    /// as an output. For input pins, this operation may not have any effect
    /// or may fail depending on the hardware.
    ///
    /// - Parameter value: The digital value to set (high or low)
    ///
    /// - Throws: ``GPIOError`` if the value cannot be set:
    ///   - ``GPIOError/valueFailed`` if the value write operation fails
    ///   - ``GPIOError/fileSystemError(_:)`` for filesystem access issues
    ///   - ``GPIOError/notSupported`` on non-Linux platforms
    ///
    /// ## Example
    ///
    /// ```swift
    /// let gpio = try GPIO(pin: 18, direction: .output)
    /// 
    /// // Set pin high (3.3V on Raspberry Pi)
    /// try gpio.setValue(.high)
    /// 
    /// // Set pin low (0V)
    /// try gpio.setValue(.low)
    /// ```
    ///
    /// ## Performance Notes
    ///
    /// - Each call involves a filesystem write operation
    /// - For high-frequency switching, consider the performance implications
    /// - The ``value`` property setter provides the same functionality with automatic error handling
    public func setValue(_ value: GPIOValue) throws {
        #if os(Linux)
        let valuePath = "\(basePath)/gpio\(pin)/value"
        try writeToFile(path: valuePath, value: "\(value.rawValue)")
        #else
        throw GPIOError.notSupported
        #endif
    }
    
    /// Reads the current digital value from the GPIO pin.
    ///
    /// This private method handles the low-level reading of the pin's digital state
    /// from the sysfs interface. It reads the value file and converts the string
    /// representation to a ``GPIOValue``.
    ///
    /// - Returns: The current digital value of the pin
    /// - Throws: ``GPIOError`` if the value cannot be read or parsed
    private func getValue() throws -> GPIOValue {
        #if os(Linux)
        let valuePath = "\(basePath)/gpio\(pin)/value"
        let valueString = try readFromFile(path: valuePath)
        let trimmedValue = valueString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let intValue = Int(trimmedValue),
              let gpioValue = GPIOValue(rawValue: intValue) else {
            throw GPIOError.valueFailed
        }
        
        return gpioValue
        #else
        throw GPIOError.notSupported
        #endif
    }
    
    /// Writes a string value to a file in the GPIO sysfs interface.
    ///
    /// This private method handles low-level file writing operations for the
    /// GPIO sysfs interface. It provides proper error handling and uses C-level
    /// file operations for reliability.
    ///
    /// - Parameters:
    ///   - path: The filesystem path to write to
    ///   - value: The string value to write
    /// - Throws: ``GPIOError/fileSystemError(_:)`` with detailed error information
    private func writeToFile(path: String, value: String) throws {
        #if os(Linux)
        let file = fopen(path, "w")
        guard let file = file else {
            throw GPIOError.fileSystemError("Could not open file at \(path). Error: \(String(cString: strerror(errno)))")
        }
        defer { fclose(file) }
        
        let result = fputs(value, file)
        if result == EOF {
            throw GPIOError.fileSystemError("Could not write to file at \(path). Error: \(String(cString: strerror(errno)))")
        }
        #else
        throw GPIOError.notSupported
        #endif
    }
    
    /// Reads a string value from a file in the GPIO sysfs interface.
    ///
    /// This private method handles low-level file reading operations for the
    /// GPIO sysfs interface. It reads the entire file contents and converts
    /// them to a UTF-8 string.
    ///
    /// - Parameter path: The filesystem path to read from
    /// - Returns: The file contents as a UTF-8 string
    /// - Throws: ``GPIOError/fileSystemError(_:)`` with detailed error information
    private func readFromFile(path: String) throws -> String {
        #if os(Linux)
        guard let data = FileManager.default.contents(atPath: path) else {
            throw GPIOError.fileSystemError("Could not read file at \(path).")
        }
        
        guard let string = String(data: data, encoding: .utf8) else {
            throw GPIOError.fileSystemError("Could not decode file contents from \(path).")
        }
        
        return string
        #else
        throw GPIOError.notSupported
        #endif
    }
}

public extension GPIO {
    /// Manually cleans up the GPIO pin by unexporting it.
    ///
    /// This method provides explicit cleanup of GPIO resources. While cleanup
    /// is performed automatically when the GPIO object is deallocated, you may
    /// want to call this method explicitly to release resources earlier.
    ///
    /// After calling this method, the GPIO pin becomes unavailable for use
    /// until it's exported again.
    ///
    /// - Throws: ``GPIOError`` if the cleanup operation fails:
    ///   - ``GPIOError/unexportFailed`` if the pin cannot be unexported
    ///   - ``GPIOError/fileSystemError(_:)`` for filesystem access issues
    ///   - ``GPIOError/notSupported`` on non-Linux platforms
    ///
    /// ## Example
    ///
    /// ```swift
    /// let gpio = try GPIO(pin: 18, direction: .output)
    /// gpio.value = .high
    /// 
    /// // Explicitly clean up when done
    /// try gpio.cleanup()
    /// // Pin is now unavailable until exported again
    /// ```
    ///
    /// ## Usage Notes
    ///
    /// - This method is idempotent - calling it multiple times is safe
    /// - Automatic cleanup in `deinit` will still occur even after manual cleanup
    /// - You cannot use the GPIO pin after cleanup without reinitializing
    func cleanup() throws {
        try unexport()
    }
    
    /// Toggles the GPIO pin between high and low states.
    ///
    /// This convenience method reads the current pin value and sets it to the
    /// opposite state. If the pin is currently high, it becomes low, and vice versa.
    ///
    /// This method is most useful for output pins where you want to alternate
    /// between states, such as blinking an LED or generating a square wave.
    ///
    /// - Throws: ``GPIOError`` if the toggle operation fails:
    ///   - ``GPIOError/valueFailed`` if the current value cannot be read or the new value cannot be set
    ///   - ``GPIOError/fileSystemError(_:)`` for filesystem access issues
    ///   - ``GPIOError/notSupported`` on non-Linux platforms
    ///
    /// ## Example
    ///
    /// ```swift
    /// let ledPin = try GPIO(pin: 18, direction: .output)
    /// 
    /// // Start with LED off
    /// ledPin.value = .low
    /// 
    /// // Blink the LED
    /// for _ in 0..<10 {
    ///     try ledPin.toggle()  // LED changes state
    ///     usleep(500000)       // Wait 500ms
    /// }
    /// ```
    ///
    /// ## Performance Notes
    ///
    /// - This method performs both a read and write operation
    /// - For high-frequency toggling, consider caching the state if performance is critical
    /// - Each call involves two filesystem operations (read current value, write new value)
    func toggle() throws {
        try setValue(try value == .high ? .low : .high)
    }
}