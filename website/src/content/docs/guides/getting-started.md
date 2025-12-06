---
title: Getting Started
description: Learn how to install and start using the Byte Converter library in your Dart projects.
---

Welcome to **Byte Converter**! This library makes it easy to handle digital sizes (like KB, MB, GB) and data rates (like Mbps) in your Dart and Flutter applications.

Whether you are building a file manager, a download manager, or just need to display file sizes nicely, this package has you covered.

## Installation

Add the package to your `pubspec.yaml` file:

```yaml
dependencies:
  byte_converter: ^2.5.0
```

Then run the following command in your terminal:

```bash
dart pub get
```

## Quick Start

Here is a simple example to get you up and running.

1.  **Import the library:**

    ```dart
    import 'package:byte_converter/byte_converter.dart';
    ```

2.  **Create a size and format it:**

    ```dart
    void main() {
      // Create a size of 1024 bytes
      final fileSize = ByteConverter(1024);

      // Format it automatically (e.g., "1 KB")
      print(fileSize.display.auto());
    }
    ```

## Choosing the Right Import

The library is modular, so you can import only what you need.

| Import Path                                       | Best For...                                                                                  |
| :------------------------------------------------ | :------------------------------------------------------------------------------------------- |
| `package:byte_converter/byte_converter.dart`      | **Most Projects.** Includes core features like conversion, formatting, and data rates.       |
| `package:byte_converter/byte_converter_intl.dart` | **Localization.** Use this if you need locale-aware number formatting (e.g., `1.234,56 MB`). |
| `package:byte_converter/byte_converter_lite.dart` | **Minimalism.** A lightweight version without external dependencies.                         |
| `package:byte_converter/byte_converter_full.dart` | **Advanced Usage.** Includes statistics, streaming tools, and interop adapters.              |

## Next Steps

- Check out the [Usage Guide](/guides/usage/) for more examples.
- Learn about [Formatting](/guides/formatting/) options.
- See how to [Parse Strings](/guides/parsing/) like "10 MB".

// BigInt for massive values
final big = BigByteConverter.fromYottaBytes(BigInt.from(2));
print(big.toHumanReadable(BigSizeUnit.YB)); // "2 YB"

// Data rates
final rate = DataRate.megaBitsPerSecond(100);
print(rate.toHumanReadableAuto()); // "100 Mb/s"

````

## Namespace APIs

Access extended functionality through dedicated namespaces:

```dart
final size = ByteConverter.fromMegaBytes(1536); // 1.5 GB

// Display formats
print(size.display.auto());       // "1.5 GB"
print(size.display.fuzzy());      // "about 1.5 GB"
print(size.display.scientific()); // "1.5 × 10⁹ B"
print(size.display.gnu());          // "1.5G"

// Storage alignment
print(size.storage.sectors);      // disk sectors
print(size.storage.blocks);       // 4KB blocks
print(size.storage.roundToBlock()); // aligned to block boundary

// Rate calculations
print(size.rate.bitsPerSecond);   // as bits/second
final rate = DataRate.megaBitsPerSecond(100);
print(size.rate.transferTime(rate)); // Duration

// Comparisons
final total = ByteConverter.fromGigaBytes(10);
print(size.compare.percentOf(total));     // 15.0
print(size.compare.percentageBar(total)); // "███░░░░░░░"

// Structured output
print(size.output.asMap);    // {'value': 1.5, 'unit': 'GB', ...}
print(size.output.asJson()); // JSON string

// Accessibility
print(size.accessibility.screenReader()); // "one point five gigabytes"
````

## Standards

- SI (decimal): KB, MB, GB, TB… (1000 multiplier)
- IEC (binary): KiB, MiB, GiB, TiB… (1024 multiplier)
- JEDEC (binary with KB/MB/GB symbols)

Use `ByteStandard.si | iec | jedec` for parsing/formatting choices.

## Next steps

- [Usage](/guides/usage/) - Full usage examples
- [Formatting](/guides/formatting/) - Formatting options
- [Parsing](/guides/parsing/) - String parsing
- [Utilities](/guides/utilities/) - Display, comparison, accessibility utilities
- [Extensions](/guides/extensions/) - Fluent extensions on int/double/BigInt
