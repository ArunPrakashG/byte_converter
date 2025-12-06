---
title: Data Rate 📶
---
`DataRate` represents network/data throughput stored as bits per second.

## Create

```dart
const r0 = DataRate.zero;
final r1 = DataRate.megaBitsPerSecond(100); // 100 Mb/s
final r2 = DataRate.kibiBytesPerSecond(2);  // 2 KiB/s

// Parse from string
final r3 = DataRate.parse('100 Mbps');
final r4 = DataRate.parse('12.5 MB/s');
```

## Format

```dart
r1.toHumanReadableAuto();                        // "100 Mb/s"
r2.toHumanReadableAuto(standard: ByteStandard.iec, useBytes: true); // "2 KiB/s"

// Force a unit and tweak digits
r1.toHumanReadableAuto(
  forceUnit: 'Mb',
  minimumFractionDigits: 1,
  maximumFractionDigits: 1,
  spacer: '',
  signed: true,
); // "+100,0Mb/s" (with separator: ',')
```

## Parse

```dart
final p1 = DataRate.parse('12.5 MB/s');           // bytes per second
final p2 = DataRate.parse('100 kibps', standard: ByteStandard.iec);
```

## Transfer time

```dart
final file = ByteConverter.fromMegaBytes(1500);
final rate = DataRate.megaBitsPerSecond(100);

// Using rate namespace (recommended)
final duration = file.rate.transferTime(rate);
print(duration); // Duration

// Legacy method
final t = rate.transferTimeForBytes(file.asBytes().toDouble());
```

Edge cases and large IEC units (PiB/s, EiB/s, ZiB/s, YiB/s) are supported when using the IEC standard.

## Time-base formatting

You can format per millisecond, minute, or hour using the `per` option:

```dart
final r = DataRate.megaBitsPerSecond(200);
print(r.toHumanReadableAuto(per: 'ms'));  // "200 Mb/ms"
print(r.toHumanReadableAuto(per: 'min')); // "12.0 Gb/min"
print(r.toHumanReadableAuto(per: 'h'));   // "720 Gb/h"
// Fixed-width alignment of the numeric portion (unit unchanged)
print(r.toHumanReadableAuto(per: 'min', fixedWidth: 6)); // e.g., "  12.0 Gb/min"
```

### CLI examples

Use the `bytec` CLI to format rates with time bases and fixed width:

```bash
# Seconds (default)
bytec rate "200 Mb/s"

# Per minute and hour
bytec rate "200 Mb/s" --per min
bytec rate "200 Mb/s" --per h

# Fixed-width padding of numeric portion for alignment
bytec rate "200 Mb/s" --per min --fixed-width 6

# Bytes instead of bits
bytec rate "12.5 MB/s" --bytes --per min --fixed-width 8
```

## OS parsing adapters

> **Note:** `OSParsingModes` requires the full import:
> ```dart
> import 'package:byte_converter/byte_converter_full.dart';
> ```

```dart
final fromLs  = OSParsingModes.parseLinuxHuman('1.1K');  // 1024-based, e.g., ~1126 B
final fromGci = OSParsingModes.parseWindowsShort('20MB'); // 1000-based, 20,000,000 B
```
