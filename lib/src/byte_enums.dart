/// Byte size units for standard precision conversions (up to PB).
enum SizeUnit {
  /// Petabyte (10^15 bytes)
  PB,

  /// Terabyte (10^12 bytes)
  TB,

  /// Gigabyte (10^9 bytes)
  GB,

  /// Megabyte (10^6 bytes)
  MB,

  /// Kilobyte (10^3 bytes)
  KB,

  /// Byte (8 bits)
  B,
}

/// Size units for BigByteConverter with support for larger SI magnitudes.
enum BigSizeUnit {
  /// Quettabyte (10^30)
  QB,

  /// Ronnabyte (10^27)
  RB,

  /// Yottabyte (10^24)
  YB,

  /// Zettabyte (10^21)
  ZB,

  /// Exabyte (10^18)
  EB,

  /// Petabyte (10^15)
  PB,

  /// Terabyte (10^12)
  TB,

  /// Gigabyte (10^9)
  GB,

  /// Megabyte (10^6)
  MB,

  /// Kilobyte (10^3)
  KB,

  /// Byte (8 bits)
  B,
}

/// Unit standards/prefix systems used for formatting and parsing.
/// - [si]: Decimal powers of 1000 with symbols KB, MB, GB, ...
/// - [iec]: Binary powers of 1024 with symbols KiB, MiB, GiB, ...
/// - [jedec]: Binary powers of 1024 but using KB, MB, GB symbols (common in OS/UI)
enum ByteStandard {
  /// SI decimal (powers of 1000)
  si,

  /// IEC binary (powers of 1024 with iB suffix)
  iec,

  /// JEDEC binary (powers of 1024 with KB/MB/GB)
  jedec,
}

/// Rounding modes for converting fractional values to integers.
enum RoundingMode {
  /// Round toward negative infinity.
  floor,

  /// Round toward positive infinity.
  ceil,

  /// Round to nearest, ties away from zero.
  round,
}
