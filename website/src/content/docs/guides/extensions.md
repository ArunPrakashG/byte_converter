---
title: Extensions 🧩
---
Fluent constructors on `int`, `double`, and `BigInt`.

## int

```dart
10.kiloBytes; // ByteConverter from KB
512.kibiBytes; // ByteConverter from KiB
2048.bits;     // ByteConverter from bits
```

## double

```dart
1.5.gigaBytes; // ByteConverter
1024.0.bytes;  // ByteConverter
```

## BigInt

```dart
BigInt.one.yottaBytes; // BigByteConverter
BigInt.from(1024).kibiBytes; // BigByteConverter
```
