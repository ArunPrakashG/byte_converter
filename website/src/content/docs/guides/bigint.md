---
title: BigInt / BigByteConverter 🧱
---
Use `BigByteConverter` for arbitrary precision conversions and formatting.

## Create

```dart
final x = BigByteConverter(BigInt.from(1024));
final y = BigByteConverter.fromYottaBytes(BigInt.from(1));
```

## Format

```dart
x.toHumanReadable(BigSizeUnit.KB); // "1 KB"
x.toHumanReadableAuto(standard: ByteStandard.iec); // "1 KiB"
```

## Exact vs approximate getters

- Exact integer getters (e.g., `kiloBytesExact`) return `BigInt` divisions
- Double getters (e.g., `kiloBytes`) are convenient for UI but can lose precision on huge values

## Math and rounding

```dart
final a = BigByteConverter(BigInt.from(4000));
final b = a.roundToBlock(); // -> 4096 B

final sum = a + BigByteConverter(BigInt.from(24));
final half = a ~/ BigInt.from(2);
```

## Parsing with rounding

```dart
final p = BigByteConverter.parse('1.2 GiB',
  standard: ByteStandard.iec,
  rounding: RoundingMode.floor,
);
```

## Interop

```dart
final n = BigByteConverter(BigInt.from(1024)).toByteConverter();
final b = BigByteConverter.fromByteConverter(ByteConverter(1024));
```
