enum SizeUnit { PB, TB, GB, MB, KB, B }

/// Size units for BigByteConverter with support for larger units
enum BigSizeUnit { YB, ZB, EB, PB, TB, GB, MB, KB, B }

/// Unit standards/prefix systems used for formatting and parsing
/// - si: Decimal powers of 1000 with symbols KB, MB, GB, ...
/// - iec: Binary powers of 1024 with symbols KiB, MiB, GiB, ...
/// - jedec: Binary powers of 1024 but symbols KB, MB, GB (common in OS/UI)
enum ByteStandard { si, iec, jedec }

/// Rounding modes used when converting fractional values to integers (BigInt parsing)
enum RoundingMode { floor, ceil, round }
