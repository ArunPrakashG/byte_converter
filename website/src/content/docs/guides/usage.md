---
title: Usage
description: Common usage patterns for the Byte Converter library.
---

This guide covers the most common tasks you'll perform with `ByteConverter`.

## Creating Sizes

You can create a `ByteConverter` object from various units.

```dart
// From bytes (integer)
final size1 = ByteConverter(1024);

// From other units (double)
final size2 = ByteConverter.fromMegaBytes(5.5);
final size3 = ByteConverter.fromGigaBytes(1.2);
```

## Basic Conversions

Once you have a `ByteConverter` object, you can easily convert it to any other unit.

```dart
final file = ByteConverter.fromMegaBytes(500);

print(file.kiloBytes); // 500,000.0
print(file.gigaBytes); // 0.5
print(file.bits);      // 4,000,000,000.0
```

## Formatting for Display

The library provides a powerful `display` namespace for formatting sizes into human-readable strings.

### Automatic Formatting

This automatically chooses the best unit (e.g., converting 1024 MB to 1 GB).

```dart
final size = ByteConverter.fromMegaBytes(1500);

print(size.display.auto()); // "1.5 GB"
```

### Specific Units

Force the output to be in a specific unit.

```dart
print(size.display.inUnit(SizeUnit.MB)); // "1500 MB"
print(size.display.inUnit(SizeUnit.KB)); // "1500000 KB"
```

### Standards (SI vs IEC)

You can switch between Decimal (1000-based, e.g., KB, MB) and Binary (1024-based, e.g., KiB, MiB) standards.

```dart
// SI (Decimal) - Default
print(size.display.auto(standard: ByteStandard.si)); // "1.5 GB"

// IEC (Binary)
print(size.display.auto(standard: ByteStandard.iec)); // "1.4 GiB"
```

## Arithmetic Operations

You can perform math on sizes just like regular numbers.

```dart
final fileA = ByteConverter.fromMegaBytes(100);
final fileB = ByteConverter.fromMegaBytes(50);

final total = fileA + fileB; // 150 MB
final diff = fileA - fileB;  // 50 MB
final doubleSize = fileA * 2; // 200 MB

if (fileA > fileB) {
  print('File A is larger');
}
```

## Comparison

The library implements `Comparable`, so you can sort lists of sizes easily.

```dart
final sizes = [
  ByteConverter.fromMegaBytes(10),
  ByteConverter.fromKiloBytes(500),
  ByteConverter.fromGigaBytes(1),
];

sizes.sort(); // Sorts from smallest to largest
```

### Parsing

```dart
final c1 = ByteConverter.parse('1.5 GB');
final c2 = ByteConverter.parse('2 GiB', standard: ByteStandard.iec);
```

## BigByteConverter (BigInt-based)

```dart
final huge = BigByteConverter.fromYottaBytes(BigInt.from(3));
print(huge.toHumanReadable(BigSizeUnit.YB));  // "3 YB"
print(huge.yobiBytes);                        // as double

// Interop with ByteConverter
final approx = huge.toByteConverter();

// Parsing with rounding control
final p = BigByteConverter.parse('1.2 GiB',
  standard: ByteStandard.iec,
  rounding: ByteRoundingMode.floor,
);
```

## DataRate

```dart
// Static constructors
final r1 = DataRate.megaBitsPerSecond(200);
print(r1.toHumanReadableAuto()); // "200 Mb/s"

final r2 = DataRate.kibiBytesPerSecond(2048);
print(r2.toHumanReadableAuto(standard: ByteStandard.iec, useBytes: true));

// Parse from string
final r3 = DataRate.parse('100 Mbps');
print(r3.megaBitsPerSecond); // 100.0
```

## Unified parsing (auto choose Big or normal)

```dart
final parsed = parseByteSizeAuto('12.34 ZiB', standard: ByteStandard.iec);
if (parsed.isBig) {
  print((parsed as ParsedBig).value.toHumanReadableAuto(standard: ByteStandard.iec));
} else {
  print((parsed as ParsedNormal).value.toHumanReadableAuto());
}
```

## Composite expressions

```dart
final size = ByteConverter.parse('(1 GiB + 512 MiB) - 256 MB');
final rate = DataRate.parse('2 GiB/5s + 50 Mbps');
final big = BigByteConverter.parse('2 YiB / 4 + 128 GiB');
```

## Transfer planning

````dart
final plan = ByteConverter.parse('2 GB').estimateTransfer(
  DataRate.parse('120 Mbps'),
  elapsed: const Duration(minutes: 1),
);

print(plan.percentComplete);   // progress fraction as percent
print(plan.remainingDuration); // Duration
print(plan.etaString());       // friendly ETA string
}

### Variable schedules, throttle, and pause/resume

```dart
final plan = ByteConverter.parse('10 MB').estimateTransfer(
  DataRate.megaBytesPerSecond(1),
);

plan
  ..addRateWindow(RateWindow(rate: DataRate.megaBytesPerSecond(1), duration: const Duration(seconds: 10)))
  ..addRateWindow(RateWindow(rate: DataRate.megaBytesPerSecond(3), duration: const Duration(seconds: 10)))
  ..setThrottle(0.5);

print(plan.estimatedTotalDuration); // ETA from weighted average * throttle
print(plan.remainingDuration);

plan.pause();
// while paused, remaining/ETA are null
plan.resume();
````

````

## Storage profiles

```dart
final profile = StorageProfile(
  alignments: const [
    StorageAlignment(name: 'sector', blockSizeBytes: 512),
    StorageAlignment(name: 'object', blockSizeBytes: 4 * 1024 * 1024),
  ],
);

final payload = ByteConverter.parse('1500 KB');
final aligned = payload.roundToProfile(profile, alignment: 'object');
print(aligned.asBytes());
print(payload.alignmentSlack(profile, alignment: 'object').asBytes());
````

## Byte statistics

> **Note:** `ByteStats` requires the full import:
>
> ```dart
> import 'package:byte_converter/byte_converter_full.dart';
> ```

```dart
final samples = [
  ByteConverter.parse('256 MB'),
  512 * 1000 * 1000,
  ByteConverter.parse('1 GB'),
];

print(ByteStats.sum(samples));
print(ByteStats.percentile(samples, 90));
final histogram = ByteStats.histogram(samples, buckets: [500 * 1000 * 1000]);
for (final bucket in histogram.buckets) {
  print('${bucket.upperBound ?? '∞'} => ${bucket.count}');
}
```

### Streaming quantiles: P² vs TDigest

- Use P² (default `StreamingQuantiles([...])`) when you want a tiny-memory estimator and good speed; best for stationary distributions and a few quantiles.
- Use TDigest (`StreamingQuantiles.tDigest(compression: 200)`) when you need better tail accuracy and many quantiles across varied distributions.
- P² initializes from a small buffer and then updates online; TDigest maintains compressed centroids and interpolates between them.
- Benchmarks: see `tool/bench/bench.dart` for throughput and accuracy comparisons.

## BigDataRate

```dart
final link = BigDataRate.parse('12.5 GB/s');
final burst = link.transferableBytes(const Duration(milliseconds: 100));
print(burst.bytes); // BigInt exact bytes
print(link.toDataRate().toHumanReadableAuto());
```

## FormatterSnapshot

> **Note:** `FormatterSnapshot` requires the full import:
>
> ```dart
> import 'package:byte_converter/byte_converter_full.dart';
> ```

```dart
final snapshot = FormatterSnapshot.rate(
  rateSamples: [
    DataRate.parse('100 Mbps'),
    DataRate.parse('12.5 MB/s'),
  ],
  options: [
    const ByteFormatOptions(),
    const ByteFormatOptions(useBytes: true, precision: 1),
  ],
);

print(snapshot.toMarkdownTable());
```

## Localization & intl

```dart
enableByteConverterIntl();

final localized = ByteConverter.parse('123456 KB').toHumanReadableAuto(
  locale: 'hi_IN',
  fullForm: true,
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
);

print(localized); // १,२३,४५६.00 किलोबाइट्स (hi_IN digits + unit names)
```

- Built-in localized unit names cover English (`en`, `en_IN`), German (`de`), French (`fr`), Hindi (`hi`, `hi_IN`), Spanish (`es`), Portuguese (`pt`), Japanese (`ja`), Chinese (`zh`), and Russian (`ru`).
- Combine with `locale` and `enableByteConverterIntl()` to pick up regional number formatting (e.g., Indian digit grouping with `en_IN` or Devanagari digits with `hi_IN`).
- Use `registerLocalizedUnitNames` to add or override symbols for additional locales as needed.

## Namespace APIs

Access extended functionality through dedicated namespaces on `ByteConverter`:

### Display Namespace

```dart
final size = ByteConverter.fromMegaBytes(1.5);

print(size.display.fuzzy());        // "about 1.5 MB"
print(size.display.scientific()); // "1.5 × 10⁶ B"
print(size.display.fractional);   // "1½ MB"
print(size.display.gnu());          // "1.5M"
print(size.display.fullWords);    // "1.5 megabytes"
print(size.display.withCommas);   // "1,500,000 bytes"
```

### Output Namespace

```dart
print(size.output.asArray);   // [1.5, 'MB']
print(size.output.asTuple);   // (1.5, 'MB')
print(size.output.asMap);     // {'value': 1.5, 'unit': 'MB', 'bytes': 1500000.0}
print(size.output.asJson());  // JSON string
print(size.output.exponent);  // {'mantissa': 1.5, 'exponent': 6, 'base': 10}
```

### Comparison Namespace

```dart
final used = ByteConverter.fromGigaBytes(75);
final total = ByteConverter.fromGigaBytes(100);

print(used.compare.percentOf(total));     // 75.0
print(used.compare.percentageBar(total)); // "███████░░░"
print(used.compare.ratio(total));         // 0.75
print(used.compare.relativeTo(total));    // "75% of total"

// Clamping
final clamped = size.compare.clamp(
  ByteConverter.fromKiloBytes(100),
  ByteConverter.fromGigaBytes(1),
);
```

### Accessibility Namespace

```dart
print(size.accessibility.screenReader());    // "one point five megabytes"
print(size.accessibility.ariaLabel);       // "File size: 1.5 megabytes"
print(size.accessibility.voiceDescription); // "The file is one point five megabytes"
print(size.accessibility.summary);          // "1.5 MB (approximately 1.5 million bytes)"
```

### Bit Operations

```dart
print(size.bitOps.totalBits);      // 12000000
print(size.bitOps.isPowerOfTwo);   // false
print(size.bitOps.nextPowerOfTwo); // ByteConverter aligned to next power of 2
print(size.bitOps.isByteAligned);  // true
print(size.bitOps.toHexString());  // "16E360"
```

For more utilities, see [Utilities](/guides/utilities/).
