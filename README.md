# GPIO

![Swift](https://img.shields.io/badge/Swift-6.1-orange.svg)
![Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)
![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)

A Swift package for GPIO (General Purpose Input/Output) support on Linux systems.

⚠️ **WARNING: Early Development Library** ⚠️

This library is in early development (v0.0.1) and should be considered experimental. Use with caution in production environments. APIs may change between versions without notice. Thoroughly test your specific hardware configuration before deploying.

## Features

- 🚀 Swift 6.1 support with full concurrency
- 🐧 Linux GPIO sysfs interface
- 🔧 Simple and safe API with automatic resource management
- ⚡ Lightweight with no external dependencies
- 🧪 Comprehensive test suite using Swift Testing

## Requirements

- Swift 6.1+
- Linux (tested on Ubuntu, Raspberry Pi OS, JetPack)
- Root privileges for GPIO operations

## Supported Platforms

### Raspberry Pi
- **Pi Zero 2W**: GPIO pins 0-27 (40-pin header)
- **Pi 4**: GPIO pins 0-27 (40-pin header)
- **Pi 5**: GPIO pins 0-27 (40-pin header)

Uses BCM GPIO numbering (not physical pin numbers).

### Nvidia Jetson
- **Jetson Orin Nano**: 40-pin header compatible with Pi pinout
- Uses different GPIO numbering than Raspberry Pi
- Check `/sys/kernel/debug/gpio` or `jetson-gpio` documentation for pin mapping

### Generic Linux
Any Linux system with GPIO sysfs interface support (`/sys/class/gpio/`)

## Installation

### Swift Package Manager

Add GPIO to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/edgeengineer/gpio.git", from: "0.0.1")
]
```

Then add it to your target:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["GPIO"]
    )
]
```

### Command Line

```bash
swift package init --type executable
swift package add https://github.com/edgeengineer/gpio.git
```

## Usage

### Basic GPIO Control

```swift
import GPIO

do {
    // Raspberry Pi: Initialize GPIO pin 18 as output (BCM numbering)
    let gpio = try GPIO(pin: 18, direction: .output)
    
    // Jetson Orin Nano: Use Jetson GPIO numbering
    // let gpio = try GPIO(pin: 422, direction: .output)  // Example GPIO number
    
    // Set pin high
    gpio.value = .high
    
    // Set pin low
    gpio.value = .low
    
    // Toggle pin state
    try gpio.toggle()
    
    // Clean up when done.
    // Note: Cleanup is also handled automatically when the GPIO object is deallocated.
    try gpio.cleanup()
} catch {
    print("GPIO Error: \(error)")
}
```

### Reading Input

```swift
import GPIO

do {
    // Raspberry Pi: Initialize GPIO pin 23 as input (BCM numbering)
    let gpio = try GPIO(pin: 23, direction: .input)
    
    // Jetson Orin Nano: Use appropriate GPIO number for your pin
    // let gpio = try GPIO(pin: 424, direction: .input)  // Example GPIO number
    
    // Read current value
    let value = try gpio.value
    print("Pin value is: \(value == .high ? "HIGH" : "LOW")")
    
    // Clean up
    // Note: Cleanup is also handled automatically when the GPIO object is deallocated.
    try gpio.cleanup()
} catch {
    print("GPIO Error: \(error)")
}
```

## API Reference

### GPIO Class

#### Initializers

- `init(pin: Int, direction: GPIODirection)` - Initializes, exports, and configures the GPIO pin.

#### Properties

- `var direction: GPIODirection` - Get or set the pin's direction (input/output).
- `var value: GPIOValue` - Get or set the pin's value (high/low).

#### Methods

- `toggle()` - Toggle pin state from high to low or low to high.
- `cleanup()` - Manually unexport the pin.

### Enums

#### GPIODirection
- `.input` - Configure pin as input
- `.output` - Configure pin as output

#### GPIOValue
- `.low` - Low state (0V)
- `.high` - High state (3.3V/5V)

#### GPIOError
- `.exportFailed` - Failed to export pin
- `.unexportFailed` - Failed to unexport pin
- `.directionSetFailed` - Failed to set direction
- `.valueFailed` - Failed to read/write value
- `.invalidPin` - Invalid pin number
- `.fileSystemError(String)` - File system operation failed, contains a descriptive error.
- `.notSupported` - Platform not supported

## Permissions

GPIO operations require root privileges. Run your application with `sudo`:

```bash
sudo swift run
```

Or set up udev rules for non-root access:

```bash
# Add to /etc/udev/rules.d/99-gpio.rules
SUBSYSTEM=="gpio", KERNEL=="gpiochip*", ACTION=="add", PROGRAM="/bin/sh -c 'chown root:gpio /sys/class/gpio/export /sys/class/gpio/unexport ; chmod 220 /sys/class/gpio/export /sys/class/gpio/unexport'"
SUBSYSTEM=="gpio", KERNEL=="gpio*", ACTION=="add", PROGRAM="/bin/sh -c 'chown root:gpio /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value ; chmod 660 /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value'"
```

## Testing

Run the test suite:

```bash
swift test
```

Note: Some tests require Linux and root privileges to fully test GPIO functionality.

## Platform-Specific Notes

### Finding GPIO Numbers

#### Raspberry Pi
Use BCM GPIO numbering. Common pins:
- Physical pin 7 = BCM GPIO 4
- Physical pin 11 = BCM GPIO 17
- Physical pin 12 = BCM GPIO 18
- Physical pin 13 = BCM GPIO 27

#### Jetson Orin Nano
Check GPIO mapping with:
```bash
# View all GPIO information
sudo cat /sys/kernel/debug/gpio

# Check available GPIO chips
ls /sys/class/gpio/

# Find specific pin mapping
# Physical pin 7 might be GPIO 422 (example)
# Physical pin 11 might be GPIO 424 (example)
```

Consult the [Jetson Orin Nano Developer Kit pinout](https://developer.nvidia.com/embedded/learn/jetson-developer-kits) for accurate GPIO numbers.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built for the Swift on Linux ecosystem
- Inspired by the need for simple GPIO control in Swift applications
- Uses Linux sysfs GPIO interface for maximum compatibility