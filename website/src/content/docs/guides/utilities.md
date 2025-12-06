---
title: Utilities
---

The `byte_converter` library provides a rich set of utility classes and extensions for common tasks beyond basic byte conversion.

> **Import Note:** Most utilities work with the standard import. Advanced features like `ByteStats`, `TDigest`, `StreamInstrumentation`, and `InteropAdapters` require the full import:
>
> ```dart
> import 'package:byte_converter/byte_converter_full.dart';
> ```

## Table of Contents

- [Namespaces Overview](#namespaces-overview)
- [Display Namespace](#display-namespace)
- [Output Namespace](#output-namespace)
- [Comparison Namespace](#comparison-namespace)
- [Accessibility Namespace](#accessibility-namespace)
- [Bit Operations](#bit-operations)
- [Bandwidth Accumulator](#bandwidth-accumulator)
- [Byte Constants](#byte-constants)
- [Byte Validation](#byte-validation)
- [Time Utilities](#time-utilities)
- [Number Formatting](#number-formatting)
- [Negative Values](#negative-values)
- [Pluralization](#pluralization)
- [Network Overhead](#network-overhead)

---

## Namespaces Overview

Access extended functionality through dedicated namespace properties on `ByteConverter`:

```dart
import 'package:byte_converter/byte_converter.dart';

final size = ByteConverter.fromMegaBytes(1.5);

size.display        // ByteDisplayOptions - fuzzy, scientific, fractional formats
size.output         // ByteOutputFormats - array, map, JSON outputs
size.compare        // ByteComparison - percentages, ratios, clamping
size.accessibility  // ByteAccessibility - screen reader, ARIA labels
size.bitOps         // BitOperations - bit-level inspection and manipulation
```

---

## Display Namespace

Alternative display formats for human-friendly output.

### Fuzzy Descriptions

```dart
final size = ByteConverter.fromMegaBytes(1.5);
print(size.display.fuzzy());
// "about 1.5 MB"

final exact = ByteConverter.fromGigaBytes(1);
print(exact.display.fuzzy());
// "exactly 1 GB"

final almost = ByteConverter.fromMegaBytes(0.95);
print(almost.display.fuzzy());
// "almost 1 MB"
```

### Scientific Notation

```dart
print(size.display.scientific());
// "1.5 × 10⁶ B"

print(size.display.scientific(precision: 3, useUnicode: false));
// "1.500e6 B"
```

### Fractional Representation

```dart
final half = ByteConverter.fromMegaBytes(1.5);
print(half.display.fractional);
// "1½ MB"

final quarter = ByteConverter.fromGigaBytes(2.25);
print(quarter.display.fractional);
// "2¼ GB"
```

### GNU Short Format

```dart
print(size.display.gnu());
// "1.5M"

print(size.display.gnuWithUnit);
// "1.5MB"
```

### Full Word Output

```dart
print(size.display.fullWords);
// "1.5 megabytes"

print(size.display.fullWords(capitalize: true));
// "1.5 Megabytes"
```

### Comma Formatting

```dart
final large = ByteConverter(1536000);
print(large.display.withCommas);
// "1,536,000 bytes"
```

---

## Output Namespace

Structured output formats for data interchange.

```dart
final size = ByteConverter.fromKiloBytes(1536);

// Array format
print(size.output.asArray);
// [1.5, 'MB']

// Tuple format (Dart 3+)
print(size.output.asTuple);
// (1.5, 'MB')

// Map format
print(size.output.asMap);
// {'value': 1.5, 'unit': 'MB', 'bytes': 1536000.0}

// JSON string
print(size.output.asJson());
// '{"value":1.5,"unit":"MB","bytes":1536000.0}'

// Exponent info
print(size.output.exponent);
// {'mantissa': 1.5, 'exponent': 6, 'base': 10}
```

---

## Comparison Namespace

Tools for comparing and relating byte values.

### Percentage Calculations

```dart
final used = ByteConverter.fromGigaBytes(75);
final total = ByteConverter.fromGigaBytes(100);

print(used.compare.percentOf(total));
// 75.0

print(used.compare.percentageBar(total));
// "███████░░░" (7.5 of 10 blocks filled)

print(used.compare.percentageBar(total, width: 20, filled: '█', empty: '░'));
// "███████████████░░░░░"
```

### Relative Comparisons

```dart
print(used.compare.relativeTo(total));
// "75% of total"

print(used.compare.difference(total));
// ByteConverter(25 GB)

print(used.compare.ratio(total));
// 0.75
```

### Clamping

```dart
final size = ByteConverter.fromGigaBytes(150);
final min = ByteConverter.fromGigaBytes(10);
final max = ByteConverter.fromGigaBytes(100);

final clamped = size.compare.clamp(min, max);
print(clamped.gigaBytes);
// 100.0
```

---

## Accessibility Namespace

Accessible output formats for assistive technologies.

```dart
final size = ByteConverter.fromMegaBytes(1.5);

// Screen reader friendly
print(size.accessibility.screenReader());
// "one point five megabytes"

// ARIA label
print(size.accessibility.ariaLabel);
// "File size: 1.5 megabytes"

// Voice description
print(size.accessibility.voiceDescription);
// "The file is one point five megabytes"

// Summary for announcements
print(size.accessibility.summary);
// "1.5 MB (approximately 1.5 million bytes)"
```

---

## Bit Operations

Bit-level inspection and manipulation.

```dart
final size = ByteConverter.fromKiloBytes(1);

// Basic info
print(size.bitOps.totalBits);     // 8000
print(size.bitOps.kilobits);      // 8.0
print(size.bitOps.megabits);      // 0.008

// Power of two checks
print(size.bitOps.isPowerOfTwo);  // false
print(size.bitOps.nextPowerOfTwo); // ByteConverter(1024 bytes)

// Alignment checks
print(size.bitOps.isByteAligned); // true
print(size.bitOps.isWordAligned); // true (8-byte boundary)

// Bit manipulation
final withBit = size.bitOps.setBit(0);    // Set LSB
final cleared = size.bitOps.clearBit(0);  // Clear LSB
final toggled = size.bitOps.toggleBit(7); // Toggle bit 7

// Shifts
final doubled = size.bitOps.shiftLeft(1);  // × 2
final halved = size.bitOps.shiftRight(1);  // ÷ 2

// String representations
print(size.bitOps.toBinaryString());  // "11111010000..."
print(size.bitOps.toHexString());     // "3E8"

// Alignment
print(size.bitOps.isAlignedTo(4096)); // true if aligned to 4KB
print(size.bitOps.alignTo(4096));     // Align to 4KB boundary
print(size.bitOps.alignDownTo(4096)); // Round down to 4KB boundary
```

---

## Bandwidth Accumulator

Track streaming bandwidth statistics over time.

```dart
final accumulator = BandwidthAccumulator();

// Add samples
accumulator.add(ByteConverter.fromMegaBytes(10));
accumulator.add(ByteConverter.fromMegaBytes(15));
accumulator.add(ByteConverter.fromMegaBytes(12));

// Get statistics
print(accumulator.total.megaBytes);      // 37.0
print(accumulator.average.megaBytes);    // 12.33...
print(accumulator.peak.megaBytes);       // 15.0
print(accumulator.min.megaBytes);        // 10.0
print(accumulator.sampleCount);          // 3

// Rate calculation (if timestamps provided)
print(accumulator.currentRate);  // DataRate

// Moving average
print(accumulator.movingAverage(windowSize: 2).megaBytes);

// Standard deviation
print(accumulator.standardDeviation.megaBytes);

// Reset
accumulator.reset();
```

---

## Byte Constants

Pre-defined constants for common storage sizes.

### Physical Media

```dart
print(ByteConstants.floppyDisk.megaBytes);      // 1.44
print(ByteConstants.cdCapacity.megaBytes);      // 700.0
print(ByteConstants.dvdCapacity.gigaBytes);     // 4.7
print(ByteConstants.bluRayCapacity.gigaBytes);  // 25.0
print(ByteConstants.dualLayerBluRay.gigaBytes); // 50.0
```

### Cloud Service Limits

```dart
print(ByteConstants.githubFileSizeLimit.megaBytes);      // 100.0
print(ByteConstants.githubRepoSizeWarning.gigaBytes);    // 1.0
print(ByteConstants.npmPackageSizeLimit.megaBytes);      // 500.0
print(ByteConstants.dockerHubLayerLimit.gigaBytes);      // 10.0
```

### Email Limits

```dart
print(ByteConstants.gmailAttachmentLimit.megaBytes);     // 25.0
print(ByteConstants.outlookAttachmentLimit.megaBytes);   // 20.0
```

### Memory Boundaries

```dart
print(ByteConstants.maxInt32.gigaBytes);    // ~2.1
print(ByteConstants.maxInt64.exaBytes);     // ~9.2
print(ByteConstants.pageSize.kiloBytes);    // 4.0
print(ByteConstants.sectorSize.bytes);      // 512.0
```

---

## Byte Validation

Validate sizes against constraints.

```dart
final fileSize = ByteConverter.fromMegaBytes(150);

// Check against limits
print(ByteValidation.isValidFileSize(
  fileSize,
  maxSize: ByteConstants.githubFileSizeLimit,
));
// false (150 MB > 100 MB)

// Check quota
print(ByteValidation.isWithinQuota(
  fileSize,
  used: ByteConverter.fromGigaBytes(8),
  quota: ByteConverter.fromGigaBytes(10),
));
// false (8 GB + 150 MB > 10 GB quota)

// Full validation with diagnostics
final result = ByteValidation.validate(
  fileSize,
  maxSize: ByteConstants.gmailAttachmentLimit,
  minSize: ByteConverter(1),
);
print(result.isValid);    // false
print(result.message);    // "Size exceeds maximum of 25 MB"

// Assert positive (throws on negative)
ByteValidation.assertPositive(fileSize);
```

---

## Time Utilities

### Natural Time Delta

Format durations in natural language.

```dart
final duration = Duration(hours: 2, minutes: 30);

print(duration.natural);    // "2 hours, 30 minutes"
print(duration.precise);    // "2h 30m 0s"
print(duration.short);      // "2.5h"
print(duration.countdown);  // "2:30:00"
```

### Relative Time

Format relative time expressions.

```dart
// Duration extensions
print(Duration(hours: 2).ago);        // "2 hours ago"
print(Duration(minutes: 30).fromNow); // "in 30 minutes"
print(Duration(days: 1).relative);    // "1 day"
print(Duration(hours: 2).humanRelative); // uses "yesterday", "tomorrow" etc.

// DateTime extensions
final pastDate = DateTime.now().subtract(Duration(days: 3));
print(pastDate.relative);    // "3 days ago"
print(pastDate.timeAgo);     // "3 days ago"

// Utility class
print(RelativeTime.formatAgo(Duration(hours: 2)));
// "2 hours ago"

print(RelativeTime.humanize(Duration(days: 1), isPast: true));
// "yesterday"

print(RelativeTime.detailed(Duration(hours: 2, minutes: 30)));
// "2 hours, 30 minutes"

print(RelativeTime.countdown(Duration(hours: 1, minutes: 30, seconds: 45)));
// "1:30:45"

// Progress formatting
print(RelativeTime.progress(
  Duration(seconds: 30),
  Duration(seconds: 60),
));
// "30s / 60s (50%)"

// ETA estimation
print(RelativeTime.eta(Duration(minutes: 5), 0.25));
// "15 minutes" (estimated remaining)
```

---

## Number Formatting

### SI Number Formatting

Format any number with SI prefixes.

```dart
// Basic humanization
print(SINumber.humanize(1500000));     // "1.5M"
print(SINumber.humanize(0.000001));    // "1µ"

// With units
print(SINumber.humanize(1500000, unit: 'Hz'));
// "1.5MHz"

// Full prefix names
print(SINumber.humanizeFull(1500000));
// "1.5 mega"

// Engineering notation
print(SINumber.engineering(1500));
// "1.5 × 10³"

// Parse SI strings
print(SINumber.parse("1.5M"));
// 1500000.0

// Extensions on num
print(1500000.siFormat);  // "1.5M"
print(1500000.siFull);    // "1.5 mega"
```

### Ordinal Numbers

```dart
print(ByteOrdinal.format(1));   // "1st"
print(ByteOrdinal.format(2));   // "2nd"
print(ByteOrdinal.format(3));   // "3rd"
print(ByteOrdinal.format(11));  // "11th"
print(ByteOrdinal.format(21));  // "21st"
print(ByteOrdinal.format(42));  // "42nd"

// Extension on int
print(1.ordinal);        // "1st"
print(42.ordinalSuffix); // "nd"
```

---

## Negative Values

Handle size changes and deltas with sign awareness.

### Basic Formatting

```dart
// Default (minus sign)
print(NegativeByteFormatter.format(-500000));
// "-488.28 KB"

// Parentheses style
print(NegativeByteFormatter.format(
  -500000,
  options: NegativeValueOptions.parentheses,
));
// "(488.28 KB)"

// Verbose style
print(NegativeByteFormatter.format(
  -500000,
  options: NegativeValueOptions.verbose,
));
// "488.28 KB reduction"

// With arrows
print(NegativeByteFormatter.formatWithArrow(-500000));
// "↓ 488.28 KB"

print(NegativeByteFormatter.formatWithArrow(500000));
// "↑ 488.28 KB"
```

### Size Delta Tracking

```dart
final delta = SizeDelta(1000000, 500000); // from 1MB to 500KB

print(delta.difference);           // -500000
print(delta.absoluteDifference);   // 500000
print(delta.isDecrease);           // true
print(delta.isIncrease);           // false
print(delta.direction);            // DeltaDirection.decrease
print(delta.percentageChange);     // -0.5
print(delta.percentageChangeFormatted); // "-50.0%"
print(delta.format());             // "-488.28 KB"
```

### Comparison Formatting

```dart
print(NegativeByteFormatter.formatComparison(1000000, 500000));
// "976.56 KB → 488.28 KB (-488.28 KB, -50.0%)"
```

### Summary of Multiple Changes

```dart
final deltas = [
  SizeDelta(1000, 500),   // decrease
  SizeDelta(2000, 3000),  // increase
];

print(NegativeByteFormatter.formatSummary(deltas));
// "Net: +512 B (1 increase, 1 decrease)"
```

### ByteConverter Extensions

```dart
final fileA = ByteConverter.fromMegaBytes(10);
final fileB = ByteConverter.fromMegaBytes(8);

// Create delta between values
final delta = fileA.deltaTo(fileB);
print(delta.format());  // "-2 MB"

// Format with sign
print(fileA.formatSigned(showPlus: true));
// "+10 MB"
```

---

## Rounding Modes

Extended rounding strategies for precise control.

```dart
final value = 1.5;

print(value.round(ByteRoundingMode.halfUp));      // 2
print(value.round(ByteRoundingMode.halfDown));    // 1
print(value.round(ByteRoundingMode.halfEven));    // 2 (banker's rounding)
print(value.round(ByteRoundingMode.floor));       // 1
print(value.round(ByteRoundingMode.ceil));        // 2
print(value.round(ByteRoundingMode.truncate));    // 1
```

---

## Pluralization

Smart pluralization utilities for byte-related terms with locale-aware rules.

### Basic Usage

```dart
import 'package:byte_converter/byte_converter.dart';

// Format value with pluralized unit
print(BytePluralization.format(1, 'byte'));     // "1 byte"
print(BytePluralization.format(2, 'byte'));     // "2 bytes"
print(BytePluralization.format(0, 'byte'));     // "0 bytes"
print(BytePluralization.format(1.5, 'megabyte')); // "1.5 megabytes"

// Get just the unit name
print(BytePluralization.unitFor(1, 'kilobyte'));  // "kilobyte"
print(BytePluralization.unitFor(2, 'kilobyte'));  // "kilobytes"

// Pluralize a word
print(BytePluralization.pluralize('byte'));       // "bytes"
print(BytePluralization.pluralize('entry'));      // "entries"
```

### With Formatting Options

```dart
// Use comma separators
final options = PluralizationOptions(useCommaSeparator: true);
print(BytePluralization.format(1536, 'byte', options: options));
// "1,536 bytes"

// Without value
final unitOnly = PluralizationOptions(includeValue: false);
print(BytePluralization.format(5, 'gigabyte', options: unitOnly));
// "gigabytes"

// Custom plural form
print(BytePluralization.format(2, 'byte', plural: 'octets'));
// "2 octets"
```

### Locale-Aware Rules

Different languages have different pluralization rules:

```dart
// French: 0 and 1 are singular
final frOptions = BytePluralization.optionsForLocale('fr');
print(BytePluralization.format(0, 'octet', options: frOptions)); // "0 octet"
print(BytePluralization.format(1, 'octet', options: frOptions)); // "1 octet"
print(BytePluralization.format(2, 'octet', options: frOptions)); // "2 octets"

// East Asian: no grammatical plural
final jaOptions = BytePluralization.optionsForLocale('ja');
print(BytePluralization.format(5, 'バイト', options: jaOptions)); // "5 バイト"

// Slavic: complex rules (1, 21, 31 = singular; 2-4, 22-24 = few; rest = plural)
final ruOptions = BytePluralization.optionsForLocale('ru');
print(BytePluralization.shouldUseSingular(1, options: ruOptions));  // true
print(BytePluralization.shouldUseSingular(21, options: ruOptions)); // true
print(BytePluralization.shouldUseSingular(11, options: ruOptions)); // false
```

### Supported Locales

| Rule Type  | Languages                                                    |
| ---------- | ------------------------------------------------------------ |
| English    | English, German, Spanish, Italian                            |
| French     | French, Portuguese (Brazilian)                               |
| East Asian | Japanese, Chinese, Korean, Vietnamese, Thai                  |
| Slavic     | Russian, Ukrainian, Polish, Czech, Slovak, Croatian, Serbian |
| Arabic     | Arabic, Hebrew                                               |

### Extension Methods

Quick pluralization on numbers:

```dart
// Integer extension
print(1.withUnit('byte'));          // "1 byte"
print(2.withUnit('byte'));          // "2 bytes"
print(1536.withUnit('byte', useCommas: true)); // "1,536 bytes"

// Double extension
print(1.0.withUnit('megabyte'));    // "1 megabyte"
print(1.5.withUnit('megabyte'));    // "1.5 megabytes"
print(2.345.withUnit('gigabyte', precision: 1)); // "2.3 gigabytes"
```

---

## Network Overhead

Model protocol/link overhead to estimate effective payload throughput and realistic ETAs.

### Packet Overhead Fraction

Estimate the fraction of overhead vs payload for a single packet:

```dart
import 'package:byte_converter/byte_converter.dart';

// MTU=1500, Ethernet(18), IPv4(20), TCP(20), preamble(8), IFG(12)
final fraction = NetworkOverhead.fractionForPacket(payloadBytes: 1442);
// ~ 78 / 1520 ≈ 0.0513
```

### Effective Payload Rate

Apply a simple overhead fraction to a nominal data rate:

```dart
final nominal = DataRate.megaBitsPerSecond(100);  // 100 Mb/s
final payload = NetworkOverhead.effectiveRate(nominal, overheadFraction: 0.1);
print(payload.toHumanReadableAuto()); // ~90 Mb/s
```

Compute payload rate using a packet-level model (assumes full-size packets):

```dart
final nominal = DataRate.gigaBitsPerSecond(1);  // 1 Gb/s
final payload = NetworkOverhead.effectiveRateForPacket(nominal);
print(payload.toHumanReadableAuto()); // ~0.95 Gb/s
```

### Presets

Convenience helpers for common stacks:

```dart
// Typical Ethernet + IPv4 + TCP
final fraction = NetworkOverhead.typicalFractionEthernetIpv4Tcp(mtu: 1500);
final nominal  = DataRate.gigaBitsPerSecond(1);
final payload  = NetworkOverhead.effectiveRateEthernetIpv4Tcp(nominal, mtu: 1500);
```

### Overhead-Aware TransferPlan

Estimate ETAs with an overhead fraction:

```dart
final total = ByteConverter.fromGigaBytes(1);          // 1 GB
final rate  = DataRate.megaBytesPerSecond(100);        // 100 MB/s nominal
final plan  = total.estimateTransfer(rate);

print(plan.estimatedTotalDuration);                    // ~10 s
print(plan.estimatedTotalDurationWithOverhead(0.1));   // ~11.1 s
```

Notes:

- Defaults approximate common Ethernet + IPv4 + TCP base headers with wire overhead (preamble + IFG).
- For more precision, adjust header sizes and MTU to match your environment.

## Next Steps

- [Extensions](/guides/extensions/) - Fluent extensions on int, double, BigInt
- [Formatting](/guides/formatting/) - Advanced formatting options
- [Recipes](/guides/recipes/) - Real-world usage examples
- [API Reference](/reference/api/) - Complete API documentation
