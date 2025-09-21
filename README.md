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
- ✨ **NEW**: BigInt support for arbitrary precision calculations
- 🌌 **NEW**: Large units (EB, ZB, YB) for massive data handling
- 🧩 **NEW**: Parsing from strings (`"1.5 GB"`, `"2GiB"`, `"100 Mbps"`)
- 🧭 **NEW**: Auto human-readable formatting with SI/IEC/JEDEC and bits
- 🚦 **NEW**: DataRate helper (`MB/s`, `Mbps`) for network speeds
- 🗣️ **NEW**: Full-form unit parsing (e.g., "megabytes", "kibibits") and locale-friendly input (NBSP/commas/underscores)
- 🧷 **NEW**: Advanced formatting options (full-form names, custom separators/spacers, min/max fraction digits, signed, forced unit)
- 🧮 **NEW**: Extended IEC rate units through YiB/s

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
final speed = 100.megaBytes; // size
print(speed.megaBitsPerSecond); // 800 Mbps (size to rate helpers)

// DataRate (network speeds)
final rate = DataRate.parse('100 Mbps');
print(rate.toHumanReadableAuto()); // 100 Mb/s
print(rate.toHumanReadableAuto(useBytes: true)); // 12.5 MB/s

// Storage Units
final disk = 4.kibiBytes;
print(disk.sectors); // 8 sectors
```

## BigInt Support for Large Data

For scenarios requiring arbitrary precision or handling extremely large values:

```dart
// BigInt Constructor
final dataCenter = BigByteConverter.fromExaBytes(BigInt.from(5));
print(dataCenter); // 5 EB

// Ultra-precise calculations
final precise = BigInt.parse('123456789012345678901234567890').bytes;
print(precise.asBytes); // Exact value preserved

// Large units support
final cosmic = BigByteConverter.fromYottaBytes(BigInt.one);
print(cosmic); // 1 YB

// BigInt Extensions
final huge = BigInt.from(1024).exaBytes;
print(huge.exaBytesExact); // Exact BigInt result

// Conversion between types
final normal = ByteConverter(1048576);
final big = BigByteConverter.fromByteConverter(normal);
final backToNormal = big.toByteConverter();
```

### When to Use BigInt vs Regular Converter

- **ByteConverter**: General use cases, good performance, handles up to ~15 digits precision
- **BigByteConverter**: Exact calculations, data center scales, scientific computing, crypto applications

## Advanced Usage

```dart
final data = ByteConverter.fromGigaBytes(1.5);

// Precision Control
print(data.toHumanReadable(SizeUnit.MB, precision: 3)); // 1536.000 MB

// Auto Humanize (SI/IEC/JEDEC + bits)
print(1024.bytes.toHumanReadableAuto(standard: ByteStandard.iec)); // 1 KiB
print(1024.bytes.toHumanReadableAuto(standard: ByteStandard.si)); // 1.02 KB

// Transfer Time
final downloadTime = data.downloadTimeAt(10.megaBitsPerSecond);
print(downloadTime); // Duration

// Storage Alignment
final aligned = data.roundToBlock();
print(aligned.isWholeBlock); // true

// BigInt exact arithmetic
// Parsing
final p1 = ByteConverter.parse('1.5 GB');
final p2 = BigByteConverter.parse('2TiB', standard: ByteStandard.iec);
final p3 = DataRate.parse('12.5 MB/s');
print(p1); // 1.5 GB
print(p2); // 2 TiB
print(p3); // 12.5 MB/s
final bigData = BigByteConverter.fromGigaBytes(BigInt.from(1000));
print(bigData.gigaBytesExact); // BigInt.from(1000) - no precision loss
print(bigData.gigaBytes); // 1000.0 - converted to double

// Unified parse API (auto normal vs big)
final parsed = parseByteSizeAuto('1 EB', thresholdBytes: 1e12);
if (parsed.isBig) {
  final b = (parsed as ParsedBig).value; // BigByteConverter
  print(b.toHumanReadableAuto());
} else {
  final n = (parsed as ParsedNormal).value; // ByteConverter
  print(n.toHumanReadableAuto());
}

// Reusable formatter options
final opts = ByteFormatOptions(
  standard: ByteStandard.iec,
  useBytes: true,
  precision: 1,
  showSpace: true,
);
print(ByteConverter(1024).toHumanReadableAutoWith(opts)); // 1 KiB
print(DataRate.megaBitsPerSecond(100).toHumanReadableAutoWith(opts)); // 100 Mb/s
```

## Parsing and localization (NEW)

The parser understands both symbols and full-form names, and is resilient to locale separators:

```dart
// Full-form units (bytes and IEC bytes/bits)
final a = ByteConverter.parse('1.5 megabytes'); // SI bytes
final b = ByteConverter.parse('2 kibibytes', standard: ByteStandard.iec); // IEC bytes
final c = ByteConverter.parse('10 megabits'); // SI bits -> bytes

// Locale-friendly numbers: NBSP, commas as decimal separator, underscores as group separators
final nb = ByteConverter.parse('1\u00A0234,56 KB'); // "1 234,56 KB" -> 1,234.56 KB
final us = ByteConverter.parse('12_345.67 MB');
```

Data rates support IEC units up to YiB/s and standard SI symbols:

```dart
final p = DataRate.parse('1 PiB/s', standard: ByteStandard.iec); // parses correctly
final e = DataRate.parse('2 EiB/s', standard: ByteStandard.iec);
```

## Advanced humanize formatting (NEW)

You can precisely control how sizes and rates are formatted via `ByteFormatOptions` or method parameters:

- `fullForm`: Use full names (e.g., "kilobytes", "megabits").
- `fullForms`: Override specific names (e.g., translate to "kilo-octets").
- `separator`: Decimal separator (e.g., ",").
- `spacer`: String between number and unit (e.g., "" for no space).
- `minimumFractionDigits`/`maximumFractionDigits`: Clamp fraction digits.
- `signed`: Always show a sign (+, -, or space for 0).
- `forceUnit`: Force a specific unit symbol instead of auto-scaling (supports bit units like `Mb`).

Examples:

```dart
// ByteConverter full-form output with custom override
final size = ByteConverter(1500);
print(size.toHumanReadableAutoWith(const ByteFormatOptions(
  standard: ByteStandard.si,
  useBytes: true,
  fullForm: true,
))); // 1.5 kilobytes

print(size.toHumanReadableAutoWith(const ByteFormatOptions(
  standard: ByteStandard.si,
  useBytes: true,
  fullForm: true,
  fullForms: {'kilobytes': 'kilo-octets'},
))); // 1.5 kilo-octets

// Custom separators/spacer, fixed fraction digits, signed, forced unit
final s = ByteConverter(1920);
print(s.toHumanReadableAuto(
  standard: ByteStandard.si,
  useBits: false,
  minimumFractionDigits: 1,
  maximumFractionDigits: 1,
  separator: ',',
  spacer: '',
  signed: true,
  forceUnit: 'KB',
)); // +1,9KB

// DataRate with forced unit and sign
final r = DataRate.megaBitsPerSecond(1920);
print(r.toHumanReadableAuto(
  standard: ByteStandard.si,
  useBytes: false,
  minimumFractionDigits: 1,
  maximumFractionDigits: 1,
  separator: ',',
  spacer: '',
  signed: true,
  forceUnit: 'Mb',
)); // +1920,0Mb/s
```

## Unit Support

### Regular Units (ByteConverter)

- Decimal: B, KB, MB, GB, TB, PB (auto humanize supports EB, ZB, YB too)
- Binary: B, KiB, MiB, GiB, TiB, PiB

### Extended Units (BigByteConverter)

- Decimal: B, KB, MB, GB, TB, PB, EB, ZB, YB
- Binary: B, KiB, MiB, GiB, TiB, PiB, EiB, ZiB, YiB

## Upgrade notes

This release introduces several new formatting and parsing capabilities while preserving backwards compatibility:

- New parsing paths accept full-form names (e.g., "megabytes", "kibibits") in addition to symbols.
- Locale-friendly number parsing: NBSP, underscores, and a trailing-decimal comma or dot are handled.
- Advanced formatting options are now available across `ByteConverter`, `BigByteConverter`, and `DataRate` humanize methods.
- `DataRate.toHumanReadableAuto` now delegates to the shared humanizer to ensure consistent separators, signs, and forced unit behavior.

Behavior notes:

- Forcing a unit with `forceUnit` disables auto-scaling. You can also force bit units like `Mb`.
- When `signed` is true, zero values display a leading space to keep alignment with positive/negative outputs.
- If both `minimumFractionDigits` and `maximumFractionDigits` are provided, the value is clamped to that range; otherwise `precision` is used.

## ByteFormatOptions quick reference

| Field                   | Type                  | Default                                    | Purpose                                                               |
| ----------------------- | --------------------- | ------------------------------------------ | --------------------------------------------------------------------- |
| `standard`              | `ByteStandard`        | `ByteStandard.si`                          | Select SI, IEC, or JEDEC scaling and symbols                          |
| `useBytes`              | `bool`                | `true` for sizes, `false` for rates helper | Toggle bytes vs bits in humanize methods                              |
| `precision`             | `int`                 | `2`                                        | Decimal places when min/max fraction digits aren’t specified          |
| `showSpace`             | `bool`                | `true`                                     | Insert a space between the number and unit                            |
| `fullForm`              | `bool`                | `false`                                    | Use full unit names (e.g., "kilobytes")                               |
| `fullForms`             | `Map<String,String>?` | `null`                                     | Override specific full-form names (e.g., translations)                |
| `separator`             | `String?`             | `.`                                        | Decimal separator (e.g., `,`)                                         |
| `spacer`                | `String?`             | `null`                                     | Custom string between number and unit (overrides `showSpace`)         |
| `minimumFractionDigits` | `int?`                | `null`                                     | Minimum fraction digits (pads/trims)                                  |
| `maximumFractionDigits` | `int?`                | `null`                                     | Maximum fraction digits (rounds)                                      |
| `signed`                | `bool`                | `false`                                    | Always show sign: `+`, `-`, or space for 0                            |
| `forceUnit`             | `String?`             | `null`                                     | Force a unit symbol (e.g., `KB`, `GiB`, `Mb`) instead of auto-scaling |

Tip: Use `toHumanReadableAutoWith(ByteFormatOptions(...))` to apply the same formatting consistently across sizes and rates.

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
