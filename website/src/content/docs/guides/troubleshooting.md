---
title: Troubleshooting & Common Pitfalls 🧯
---
## Parsing errors (FormatException)

- Symptom: `FormatException: Invalid size format`
- Causes:
  - Typos or unknown symbols (e.g., `XB`)
  - JEDEC/IEC mismatch (e.g., `KiB` parsed under SI)
- Fixes:
  - Ensure `standard` matches your input: `si | iec | jedec`
  - Use full-form words when unsure (e.g., `megabytes`, `kibibytes`)

[[images/parsing-error.svg]]

## Negative values

- `ByteConverter(-1)` or parsing a negative size throws `ArgumentError`.
- Ensure upstream inputs are sanitized before parsing.

## Bits vs Bytes confusion

- Lowercase `b` denotes bits; uppercase `B` denotes bytes.
- Using `useBytes: false` formats values in bits; set `useBytes: true` to force bytes.

## Forced unit doesn’t change scale

- `forceUnit` pins the unit (e.g., `MB`, `MiB`, `Gb`) and disables auto-scaling.
- When using bits, byte units are mapped to bit units where possible (e.g., `KB` -> `Kb`).

## Locale formatting

- Use `separator` (e.g., `,`) and `spacer` (e.g., empty string) to control visuals.
- `minimumFractionDigits`/`maximumFractionDigits` override `precision` rounding style.

## Data rates

- `DataRate.parse('1 MB/s', standard: ByteStandard.iec)` will throw (unit inconsistent with IEC).
- Prefer `DataRate.parse('1 MiB/s', standard: ByteStandard.iec)` for IEC.

## Very large values

- Prefer `BigByteConverter` for exact integer math at EB/ZB/YB scales.
- Use `parseByteSizeAuto` to decide automatically.

## Debugging tips

- Log the normalized number/string or run with simpler inputs (e.g., remove grouping) to isolate issues.
- Cross-check with tests in `test/` for expected behaviors and edge cases.

## Common CLI errors

- Using size parser for rates:

  - Symptom: `FormatException` when parsing `"MB/s"` or `"Mbps"` with `ByteConverter.parse`.
  - Fix: Use `DataRate.parse('100 MB/s')` or `DataRate.parse('100 Mbps')`. `ByteConverter.parse` is for sizes (no per-second suffix).

- Unknown unit for chosen standard:

  - Symptom: `Unknown SI unit`, `Unknown IEC unit`, or `Unknown unit for JEDEC`.
  - Fix: Pass the correct `standard` matching your input, or change the unit symbol.
    - Example: `ByteConverter.parse('1.5 GiB', standard: ByteStandard.iec)` or `ByteConverter.parse('1.5 GB', standard: ByteStandard.si)`.

- Bits vs Bytes capitalization:

  - Symptom: `mb` (bits) vs `MB` (bytes) gives unexpected value or error under a given standard.
  - Fix: Use the intended case. Lowercase `b` is bits, uppercase `B` is bytes. For rates, prefer `DataRate`.

- JEDEC limitations:

  - JEDEC supports `KB/MB/GB/TB`; symbols like `KiB/GiB` are IEC-only and will fail under JEDEC.
  - If you need `KiB/MiB/GiB`, select `ByteStandard.iec`.

- Mixed context tokens:
  - Inputs like `"100 GBps"` (bytes per second) vs `"100 Gbps"` (bits per second) represent different magnitudes; ensure you pick the intended symbol and use `DataRate` for per-second values.

## Auto-detecting the standard (heuristics)

The library does not auto-detect SI/IEC/JEDEC, but you can implement light heuristics:

1. Prefer IEC if you see an `i` before `B` (e.g., `KiB`, `MiB`, `GiB`).
2. If there's a per-second indicator (`/s`, `ps`, `bps`, `Bps`), parse as a data rate with `DataRate.parse`.
3. If units are `KB/MB/GB` without `i`, default to SI unless your domain expects JEDEC (many storage devices). Optionally fall back to JEDEC on SI failure.
4. For lowercase `b` suffix (`kb`, `mb`, `gb`), that's bits; handle via `DataRate` where appropriate or ensure you intend a size in bits.

Example heuristic parser for sizes:

```dart
import 'package:byte_converter/byte_converter.dart';

ByteConverter parseSizeSmart(String input) {
  final t = input.trim();
  final lower = t.toLowerCase();
  // Reject rates up-front
  if (lower.contains('/s') || lower.endsWith('ps') || lower.endsWith('bps')) {
    throw FormatException('Looks like a data rate; use DataRate.parse');
  }
  // IEC detection by iB suffix
  final hasIec = RegExp(r'\b([kmgtpezy]i)b\b', caseSensitive: false)
      .hasMatch(lower);
  if (hasIec) {
    return ByteConverter.parse(t, standard: ByteStandard.iec);
  }
  // Try SI first, then JEDEC as fallback for binary-1000 confusion contexts
  try {
    return ByteConverter.parse(t, standard: ByteStandard.si);
  } catch (_) {
    return ByteConverter.parse(t, standard: ByteStandard.jedec);
  }
}
```

And for rates:

```dart
import 'package:byte_converter/byte_converter.dart';

DataRate parseRateSmart(String input) {
  final t = input.trim();
  // IEC-like units in rates (e.g., MiB/s) imply IEC
  final isIec = RegExp(r'\b([kmgtpezy]i)b/s\b', caseSensitive: false)
      .hasMatch(t);
  final std = isIec ? ByteStandard.iec : ByteStandard.si;
  return DataRate.parse(t, standard: std);
}
```

## Quick mapping: inputs → parser & standard

| Input example    | Use this                                                     | Standard | Notes                                               |
| ---------------- | ------------------------------------------------------------ | -------- | --------------------------------------------------- |
| `1.5 GB`         | `ByteConverter.parse('1.5 GB')`                              | SI       | Decimal units without `i` default to SI.            |
| `1.5 GiB`        | `ByteConverter.parse('1.5 GiB', standard: ByteStandard.iec)` | IEC      | `iB` indicates IEC (binary).                        |
| `100 MB/s`       | `DataRate.parse('100 MB/s')`                                 | SI       | Per-second bytes; no `i` → SI.                      |
| `100 MiB/s`      | `DataRate.parse('100 MiB/s', standard: ByteStandard.iec)`    | IEC      | `MiB/s` clearly IEC.                                |
| `100 Mbps`       | `DataRate.parse('100 Mbps')`                                 | SI       | Lowercase `b` = bits per second.                    |
| `1536 KB`        | `ByteConverter.parse('1536 KB')`                             | SI       | Will auto-scale when formatted (≈1.5 MB).           |
| `10 Mb`          | `ByteConverter.parse('10 Mb')`                               | SI       | Bits as size (not rate); for per-second use `Mbps`. |
| `1 TB` (storage) | `ByteConverter.parse('1 TB', standard: ByteStandard.jedec)`  | JEDEC    | Many storage specs use JEDEC; choose per domain.    |
