---
title: Parsing 🧮
---
Parse user input and strings into concrete converters and rates. Parsing is robust to different locales and spacing.

## Sizes

````dart
// SI (decimal) default
final a = ByteConverter.parse('1.5 GB');

// IEC (binary)
final b = ByteConverter.parse('2 GiB', standard: ByteStandard.iec);

// JEDEC binary with KB/MB/GB symbols
final c = ByteConverter.parse('1 MB', standard: ByteStandard.jedec); // 1 MiB

// Full-form words are supported
final d = ByteConverter.parse('1.5 megabytes');

// Bits are recognized (kb, Mb, gib, kib, etc.)
final e = ByteConverter.parse('10 megabits');

// Locale-aware: NBSP, underscore, comma as decimal

### Locale-aware parsing (parseLocalized)

Use localized unit names and localized number forms (e.g., commas as decimals) without enabling Intl:

```dart
disableDefaultLocalizedUnitNames();
registerLocalizedUnitNames('xx', {'KB': 'kilox', 'B': 'bytex'});
registerLocalizedSynonyms('xx', {'xk': 'KB', 'byte': 'B'});

final r = parseLocalized('1,5 kilox', locale: 'xx'); // -> 1.5 KB
print(r.value!.toHumanReadableAuto(forceUnit: 'KB')); // 1.5 KB

enableDefaultLocalizedUnitNames();
````

Fallback resolution: fr-FR → fr → en (if defaults are enabled).
final f = ByteConverter.parse('1\u00A0234,56 KB');

````

## Big sizes

```dart
final big = BigByteConverter.parse('1.2 GiB',
  standard: ByteStandard.iec,
  rounding: ByteRoundingMode.floor,
);
````

Rounding modes: `floor`, `ceil`, `round` (applies when the fractional value converts to bytes).

## Unified parse (auto Big/normal)

```dart
final r = parseByteSizeAuto('12.34 ZiB', standard: ByteStandard.iec);
if (r.isBig) {
  // use (r as ParsedBig).value
} else {
  // use (r as ParsedNormal).value
}
```

## Data rates

```dart
final r1 = DataRate.parse('100 Mbps');
final r2 = DataRate.parse('12.5 MB/s');
final r3 = DataRate.parse('1 KiB/s', standard: ByteStandard.iec); // throws in SI
```

Errors are thrown for invalid formats or units inconsistent with selected standard.

### Strict bits parsing

When `strictBits: true`, fractional bit inputs are rejected (both simple literals and within expressions):

```dart
ByteConverter.tryParse('1.5 Mb', strictBits: true).isSuccess; // false
ByteConverter.tryParse('2 Mb', strictBits: true).isSuccess;   // true

// Expressions
ByteConverter.tryParse('1.5 Mb + 1 Mb', strictBits: true).isSuccess; // false
```

### Expressions support

You can add/subtract/multiply/divide values; parentheses are supported. Rate literals like `/s`, `ps`, and spelled-out `/ second` are treated as units, not division operators.

```dart
ByteConverter.parse('(1 GiB + 512 MiB)');
DataRate.parse('(100 Mbps + 50 Mbps) / 2');
```

## Safe parsing with tryParse (NEW in 2.3.0)

Non-throwing `tryParse` methods return detailed diagnostics instead of throwing exceptions:

```dart
// ByteConverter
final result = ByteConverter.tryParse('1.5 GB');
if (result.isSuccess) {
  final value = result.value!;
  print('Parsed: ${value.gigaBytes} GB');
  print('Normalized input: ${result.normalizedInput}');
  print('Detected unit: ${result.detectedUnit}');
  print('Is bit input: ${result.isBitInput}');
  print('Parsed number: ${result.parsedNumber}');
} else {
  print('Error: ${result.error!.message}');
  if (result.error!.position != null) {
    print('At position: ${result.error!.position}');
  }
}

// BigByteConverter
final bigResult = BigByteConverter.tryParse('1 EB');
if (bigResult.isSuccess) {
  print('Success: ${bigResult.value!.exaBytes} EB');
}

// DataRate
final rateResult = DataRate.tryParse('100 Mbps');
if (rateResult.isSuccess) {
  print('Rate: ${rateResult.value!.megaBitsPerSecond} Mbps');
  print('Unit: ${rateResult.detectedUnit}');
}

// Handling errors gracefully
final failed = ByteConverter.tryParse('invalid input');
if (!failed.isSuccess) {
  print('Failed: ${failed.error!.message}');
  // Can still access normalizedInput if available
  print('Attempted: ${failed.normalizedInput}');
}
```

### ParseResult properties

- `isSuccess`: Boolean indicating successful parse
- `value`: The parsed converter/rate (null on failure)
- `originalInput`: Input string as provided
- `normalizedInput`: Cleaned/canonical form of input
- `detectedUnit`: Unit symbol detected (e.g., "MB", "Gb")
- `isBitInput`: Whether the unit was bits-based
- `parsedNumber`: Numeric value before unit conversion
- `error`: ParseError with message, position, and exception details
