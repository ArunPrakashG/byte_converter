# ByteConverter

[![Pub Version](https://img.shields.io/pub/v/byte_converter)](https://pub.dev/packages/byte_converter)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

High-performance byte unit converter for Dart with automatic caching and fluent API inspired by ByteSize library from C#.

## Features

- 🚀 High-performance with cached calculations
- 📦 Decimal (KB, MB, GB, TB, PB) and Binary (KiB, MiB, GiB, TiB, PiB) units
- 🔢 Math operations (`+`, `-`, `*`, `/`)
- 🔄 JSON serialization
- 💫 Fluent API with extensions
- 📐 Precise number formatting
- 🧮 Storage units (sectors, blocks, pages)
- 📈 Network transfer rates
- ⏱️ Time-based calculations

## Installation

```yaml
dependencies:
  byte_converter: ^2.0.0
```

## Quick Start

```dart
// Basic Usage
final size = 1.5.gigaBytes;
print(size); // 1.5 GB

// Math Operations
final total = 1.5.gigaBytes + 500.megaBytes;
print(total); // 2 GB

// Binary Units
final ram = 16.gibiBytes;
print(ram.toHumanReadable(SizeUnit.GB)); // 17.18 GB

// Network Rates
final speed = 100.megaBytes;
print(speed.megaBitsPerSecond); // 800 Mbps

// Storage Units
final disk = 4.kibiBytes;
print(disk.sectors); // 8 sectors
```

## Advanced Usage

```dart
final data = ByteConverter.fromGigaBytes(1.5);

// Precision Control
print(data.toHumanReadable(SizeUnit.MB, precision: 3)); // 1536.000 MB

// Transfer Time
final downloadTime = data.downloadTimeAt(10.megaBitsPerSecond);
print(downloadTime); // Duration

// Storage Alignment
final aligned = data.roundToBlock();
print(aligned.isWholeBlock); // true
```

## Performance

- 🚀 Cached calculations for frequent operations
- 🧠 Lazy initialization for better memory usage
- 🔒 Immutable design for thread safety
- ⚡ Optimized string formatting

## License

This project is licensed under MIT License. Read about it here: [MIT License](license)

## Features and bugs

Please file feature requests and bugs here [issue tracker][tracker].

[tracker]: https://github.com/ArunPrakashG/byte_converter/issues
