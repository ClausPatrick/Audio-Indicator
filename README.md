# Balanced to Unbalanced Audio Level Indicator

## Project Overview

A low-level embedded system designed for professional audio signal processing, converting 8 balanced audio channels to 4 stereo unbalanced outputs with visual LED level indication.

## Hardware Configuration

### Microcontroller
- <b>Platform</b>: Atmel ATtiny2313 8-bit microcontroller
- <b>Architecture</b>: AVR

### Sensor Components
- <b>ADC</b>: 8-channel Analog-to-Digital Converter
- <b>LED Driver</b>: PCA9685 I2C-controlled LED driver

### LED Visualization
- <b>LED Configuration</b>: 16 LEDs total
  - 8 Red LEDs (1 per channel)
  - 8 Green LEDs (1 per channel)
- <b>Level Representation</b>: 8 levels per audio channel
- <b>PWM Control</b>: 4-level PWM per LED

## Key Features

- <b>Balanced to Unbalanced Audio Conversion</b>
- <b>Real-time Audio Level Monitoring</b>
- <b>Soft I2C Implementation</b>
- <b>Dynamic LED Level Indication</b>

## Software Architecture

### Core Functions
- ADC Channel Scanning
- Audio Signal Scaling
- LED Level Mapping
- Software I2C Communication

### Unique Aspects
- <b>Custom I2C Protocol</b>: Implemented without hardware I2C stack
- <b>Interrupt-Driven ADC Reading</b>
- <b>Flexible Channel Processing</b>

## Signal Processing Flow

1. Scan ADC Channels
2. Convert 256-level Audio Signal
3. Scale to 8-level Representation
4. Map to LED Intensity
5. Update PCA9685 via I2C

## Performance Characteristics

- <b>Channels</b>: 8 input channels
- <b>Resolution</b>: 8-bit ADC
- <b>Update Rate</b>: Interrupt-driven real-time updates

## Development Considerations

- <b>Language</b>: AVR Assembly
- <b>Toolchain</b>: AVR Assembler
- <b>Debugging</b>: GPIO-based status indicators

## Potential Improvements

- Add audio peak hold functionality
- Implement more advanced scaling algorithms
- Add serial communication for external monitoring

## Circuit Notes

- Balanced audio input conversion
- Unbalanced stereo output
- LED-based level visualization

## Dependencies

- AVR Libc
- Custom I2C implementation
