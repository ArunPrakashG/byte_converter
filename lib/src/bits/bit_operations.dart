import '../big_byte_converter.dart';
import '../byte_converter_base.dart';

/// Provides bit-level operations and conversions for byte values.
///
/// This class offers granular bit manipulation and querying capabilities,
/// useful for network protocols, binary data handling, and low-level operations.
///
/// Example:
/// ```dart
/// final size = ByteConverter.fromKiloBytes(1);
/// print(size.bitOps.totalBits);     // 8000
/// print(size.bitOps.kilobits);      // 8.0
/// print(size.bitOps.megabits);      // 0.008
/// print(size.bitOps.isPowerOfTwo);  // false
/// ```
class BitOperations {
  /// Creates a BitOperations instance for the given [ByteConverter].
  const BitOperations(this._converter);

  final ByteConverter _converter;

  // ============================================
  // Bit Value Accessors
  // ============================================

  /// Total number of bits.
  int get totalBits => _converter.bits;

  /// Total bits as a BigInt (for very large values).
  BigInt get asBigInt => BigInt.from(_converter.bits);

  /// Bits in kilobits (1 kb = 1000 bits).
  double get kilobits => _converter.bits / 1000.0;

  /// Bits in megabits (1 Mb = 1,000,000 bits).
  double get megabits => _converter.bits / 1000000.0;

  /// Bits in gigabits (1 Gb = 1,000,000,000 bits).
  double get gigabits => _converter.bits / 1000000000.0;

  /// Bits in kibibits (1 Kib = 1024 bits).
  double get kibibits => _converter.bits / 1024.0;

  /// Bits in mebibits (1 Mib = 1,048,576 bits).
  double get mebibits => _converter.bits / 1048576.0;

  /// Bits in gibibits (1 Gib = 1,073,741,824 bits).
  double get gibibits => _converter.bits / 1073741824.0;

  // ============================================
  // Bit Properties
  // ============================================

  /// Whether the byte count is a power of two.
  ///
  /// Useful for alignment checks and buffer sizing.
  bool get isPowerOfTwo {
    final bytes = _converter.bytes.toInt();
    return bytes > 0 && (bytes & (bytes - 1)) == 0;
  }

  /// Whether the bit count is divisible by 8 (byte-aligned).
  bool get isByteAligned => _converter.bits % 8 == 0;

  /// Whether the byte count is word-aligned (divisible by 4 bytes / 32 bits).
  bool get isWordAligned => _converter.bytes.toInt() % 4 == 0;

  /// Whether the byte count is double-word aligned (8 bytes / 64 bits).
  bool get isDoubleWordAligned => _converter.bytes.toInt() % 8 == 0;

  /// The number of leading zero bits in the binary representation.
  int get leadingZeroBits {
    final bits = _converter.bits;
    if (bits == 0) return 64;
    return 63 - _calculateBitLength(bits);
  }

  /// The number of trailing zero bits in the binary representation.
  int get trailingZeroBits {
    final bits = _converter.bits;
    if (bits == 0) return 64;
    int count = 0;
    int value = bits;
    while ((value & 1) == 0) {
      count++;
      value >>= 1;
    }
    return count;
  }

  /// The number of set bits (1s) in the binary representation.
  int get popCount {
    int count = 0;
    int value = _converter.bits;
    while (value != 0) {
      count += value & 1;
      value >>= 1;
    }
    return count;
  }

  /// The minimum number of bits needed to represent this value.
  int get bitLength => _calculateBitLength(_converter.bits);

  // ============================================
  // Bit Manipulation
  // ============================================

  /// Returns a new ByteConverter with the bit at [index] set to 1.
  ///
  /// Index 0 is the least significant bit.
  ByteConverter setBit(int index) {
    if (index < 0 || index >= 64) {
      throw RangeError.range(index, 0, 63, 'index');
    }
    final newBits = _converter.bits | (1 << index);
    return ByteConverter.withBits(newBits);
  }

  /// Returns a new ByteConverter with the bit at [index] cleared to 0.
  ByteConverter clearBit(int index) {
    if (index < 0 || index >= 64) {
      throw RangeError.range(index, 0, 63, 'index');
    }
    final newBits = _converter.bits & ~(1 << index);
    return ByteConverter.withBits(newBits);
  }

  /// Returns a new ByteConverter with the bit at [index] toggled.
  ByteConverter toggleBit(int index) {
    if (index < 0 || index >= 64) {
      throw RangeError.range(index, 0, 63, 'index');
    }
    final newBits = _converter.bits ^ (1 << index);
    return ByteConverter.withBits(newBits);
  }

  /// Tests if the bit at [index] is set (1).
  bool testBit(int index) {
    if (index < 0 || index >= 64) {
      throw RangeError.range(index, 0, 63, 'index');
    }
    return (_converter.bits & (1 << index)) != 0;
  }

  /// Returns a new ByteConverter with bits shifted left by [count].
  ByteConverter shiftLeft(int count) {
    if (count < 0) throw ArgumentError('Shift count cannot be negative');
    return ByteConverter.withBits(_converter.bits << count);
  }

  /// Returns a new ByteConverter with bits shifted right by [count].
  ByteConverter shiftRight(int count) {
    if (count < 0) throw ArgumentError('Shift count cannot be negative');
    return ByteConverter.withBits(_converter.bits >> count);
  }

  // ============================================
  // Alignment Helpers
  // ============================================

  /// Rounds up to the next power of two.
  ///
  /// Useful for buffer allocation and alignment.
  ByteConverter get nextPowerOfTwo {
    final bytes = _converter.bytes.toInt();
    if (bytes <= 0) return ByteConverter(1);
    if (isPowerOfTwo) return _converter;

    int n = bytes - 1;
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    n |= n >> 32;
    return ByteConverter((n + 1).toDouble());
  }

  /// Rounds down to the previous power of two.
  ByteConverter get prevPowerOfTwo {
    final bytes = _converter.bytes.toInt();
    if (bytes <= 1) return ByteConverter(1);
    if (isPowerOfTwo) return _converter;

    int n = bytes;
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    n |= n >> 32;
    return ByteConverter(((n + 1) >> 1).toDouble());
  }

  /// Aligns the byte count up to the specified [alignment].
  ///
  /// Example: `alignTo(4096)` for page alignment.
  ByteConverter alignTo(int alignment) {
    if (alignment <= 0) throw ArgumentError('Alignment must be positive');
    final bytes = _converter.bytes.toInt();
    final aligned = ((bytes + alignment - 1) ~/ alignment) * alignment;
    return ByteConverter(aligned.toDouble());
  }

  /// Aligns down to the specified [alignment].
  ByteConverter alignDownTo(int alignment) {
    if (alignment <= 0) throw ArgumentError('Alignment must be positive');
    final bytes = _converter.bytes.toInt();
    final aligned = (bytes ~/ alignment) * alignment;
    return ByteConverter(aligned.toDouble());
  }

  /// Returns true if the byte count is aligned to [alignment] bytes.
  bool isAlignedTo(int alignment) {
    if (alignment <= 0) throw ArgumentError('Alignment must be positive');
    return _converter.bytes.toInt() % alignment == 0;
  }

  // ============================================
  // CPU Cache-Line Alignment
  // ============================================

  /// Aligns up to the next L1 cache-line boundary (64 bytes).
  ///
  /// L1 cache lines are typically 64 bytes on modern x86/ARM processors.
  /// Useful for false-sharing prevention and SIMD optimizations.
  ByteConverter alignToL1CacheLine() => alignTo(64);

  /// Aligns up to the next L2 cache-line boundary (128 bytes).
  ///
  /// L2 cache lines are typically 128 bytes on modern processors.
  /// Useful for larger memory structures and cache efficiency.
  ByteConverter alignToL2CacheLine() => alignTo(128);

  /// Aligns up to the next L3 cache-line boundary (256 bytes).
  ///
  /// L3 cache lines are typically 256 bytes on modern processors.
  /// Useful for system-wide cache optimization on multi-core systems.
  ByteConverter alignToL3CacheLine() => alignTo(256);

  /// Checks if this size is aligned to L1 cache-line boundary (64 bytes).
  bool get isL1CacheAligned => isAlignedTo(64);

  /// Checks if this size is aligned to L2 cache-line boundary (128 bytes).
  bool get isL2CacheAligned => isAlignedTo(128);

  /// Checks if this size is aligned to L3 cache-line boundary (256 bytes).
  bool get isL3CacheAligned => isAlignedTo(256);

  /// Aligns down to the previous L1 cache-line boundary (64 bytes).
  ByteConverter alignDownToL1CacheLine() => alignDownTo(64);

  /// Aligns down to the previous L2 cache-line boundary (128 bytes).
  ByteConverter alignDownToL2CacheLine() => alignDownTo(128);

  /// Aligns down to the previous L3 cache-line boundary (256 bytes).
  ByteConverter alignDownToL3CacheLine() => alignDownTo(256);

  // ============================================
  // Binary String Representation
  // ============================================

  /// Returns the binary representation of the bits.
  ///
  /// If [padTo] is provided, pads with leading zeros to that length.
  String toBinaryString({int? padTo}) {
    final binary = _converter.bits.toRadixString(2);
    if (padTo != null && binary.length < padTo) {
      return binary.padLeft(padTo, '0');
    }
    return binary;
  }

  /// Returns the hexadecimal representation of the bytes.
  String toHexString({bool uppercase = false}) {
    final hex = _converter.bytes.toInt().toRadixString(16);
    return uppercase ? hex.toUpperCase() : hex;
  }

  /// Returns the octal representation of the bytes.
  String toOctalString() {
    return _converter.bytes.toInt().toRadixString(8);
  }

  // ============================================
  // Bit Format Display
  // ============================================

  /// Human-readable bit format (e.g., "8 Kb", "1.5 Mb").
  String humanize({int precision = 2}) {
    final bits = _converter.bits;
    if (bits < 1000) {
      return '$bits b';
    } else if (bits < 1000000) {
      return '${(bits / 1000).toStringAsFixed(precision)} Kb';
    } else if (bits < 1000000000) {
      return '${(bits / 1000000).toStringAsFixed(precision)} Mb';
    } else {
      return '${(bits / 1000000000).toStringAsFixed(precision)} Gb';
    }
  }

  /// Human-readable bit format using binary prefixes (Kib, Mib, Gib).
  String humanizeIEC({int precision = 2}) {
    final bits = _converter.bits;
    if (bits < 1024) {
      return '$bits b';
    } else if (bits < 1048576) {
      return '${(bits / 1024).toStringAsFixed(precision)} Kib';
    } else if (bits < 1073741824) {
      return '${(bits / 1048576).toStringAsFixed(precision)} Mib';
    } else {
      return '${(bits / 1073741824).toStringAsFixed(precision)} Gib';
    }
  }

  // ============================================
  // Private Helpers
  // ============================================

  static int _calculateBitLength(int value) {
    if (value == 0) return 0;
    int length = 0;
    while (value != 0) {
      length++;
      value >>= 1;
    }
    return length;
  }
}

/// Provides bit-level operations for [BigByteConverter].
class BigBitOperations {
  /// Creates a BigBitOperations instance for the given [BigByteConverter].
  const BigBitOperations(this._converter);

  final BigByteConverter _converter;

  // ============================================
  // Bit Value Accessors
  // ============================================

  /// Total number of bits as BigInt.
  BigInt get totalBits => _converter.bits;

  /// Bits in kilobits (1 kb = 1000 bits).
  double get kilobits => _converter.bits.toDouble() / 1000.0;

  /// Bits in megabits (1 Mb = 1,000,000 bits).
  double get megabits => _converter.bits.toDouble() / 1000000.0;

  /// Bits in gigabits (1 Gb = 1,000,000,000 bits).
  double get gigabits => _converter.bits.toDouble() / 1000000000.0;

  /// Bits in terabits (1 Tb = 1,000,000,000,000 bits).
  double get terabits => _converter.bits.toDouble() / 1000000000000.0;

  // ============================================
  // Bit Properties
  // ============================================

  /// Whether the byte count is a power of two.
  bool get isPowerOfTwo {
    final bytes = _converter.bytes;
    return bytes > BigInt.zero && (bytes & (bytes - BigInt.one)) == BigInt.zero;
  }

  /// Whether the bit count is divisible by 8 (byte-aligned).
  bool get isByteAligned => _converter.bits % BigInt.from(8) == BigInt.zero;

  /// The minimum number of bits needed to represent this value.
  int get bitLength => _converter.bits.bitLength;

  /// The number of set bits (1s) in the binary representation.
  int get popCount {
    int count = 0;
    BigInt value = _converter.bits;
    while (value != BigInt.zero) {
      if ((value & BigInt.one) == BigInt.one) count++;
      value >>= 1;
    }
    return count;
  }

  // ============================================
  // Bit Manipulation
  // ============================================

  /// Returns a new BigByteConverter with the bit at [index] set to 1.
  BigByteConverter setBit(int index) {
    if (index < 0) {
      throw RangeError.value(index, 'index', 'Must be non-negative');
    }
    final newBits = _converter.bits | (BigInt.one << index);
    return BigByteConverter.withBits(newBits);
  }

  /// Returns a new BigByteConverter with the bit at [index] cleared to 0.
  BigByteConverter clearBit(int index) {
    if (index < 0) {
      throw RangeError.value(index, 'index', 'Must be non-negative');
    }
    final newBits = _converter.bits & ~(BigInt.one << index);
    return BigByteConverter.withBits(newBits);
  }

  /// Tests if the bit at [index] is set (1).
  bool testBit(int index) {
    if (index < 0) {
      throw RangeError.value(index, 'index', 'Must be non-negative');
    }
    return (_converter.bits & (BigInt.one << index)) != BigInt.zero;
  }

  /// Returns a new BigByteConverter with bits shifted left by [count].
  BigByteConverter shiftLeft(int count) {
    if (count < 0) throw ArgumentError('Shift count cannot be negative');
    return BigByteConverter.withBits(_converter.bits << count);
  }

  /// Returns a new BigByteConverter with bits shifted right by [count].
  BigByteConverter shiftRight(int count) {
    if (count < 0) throw ArgumentError('Shift count cannot be negative');
    return BigByteConverter.withBits(_converter.bits >> count);
  }

  // ============================================
  // Alignment Helpers
  // ============================================

  /// Aligns the byte count up to the specified [alignment].
  ///
  /// Example: `alignTo(4096)` for page alignment.
  BigByteConverter alignTo(int alignment) {
    if (alignment <= 0) throw ArgumentError('Alignment must be positive');
    final bytes = _converter.bytes;
    final a = BigInt.from(alignment);
    final aligned = ((bytes + a - BigInt.one) ~/ a) * a;
    return BigByteConverter(aligned);
  }

  /// Aligns down to the specified [alignment].
  BigByteConverter alignDownTo(int alignment) {
    if (alignment <= 0) throw ArgumentError('Alignment must be positive');
    final bytes = _converter.bytes;
    final a = BigInt.from(alignment);
    final aligned = (bytes ~/ a) * a;
    return BigByteConverter(aligned);
  }

  /// Returns true if the byte count is aligned to [alignment] bytes.
  bool isAlignedTo(int alignment) {
    if (alignment <= 0) throw ArgumentError('Alignment must be positive');
    final a = BigInt.from(alignment);
    return _converter.bytes % a == BigInt.zero;
  }

  // ============================================
  // CPU Cache-Line Alignment
  // ============================================

  /// Aligns up to the next L1 cache-line boundary (64 bytes).
  BigByteConverter alignToL1CacheLine() => alignTo(64);

  /// Aligns up to the next L2 cache-line boundary (128 bytes).
  BigByteConverter alignToL2CacheLine() => alignTo(128);

  /// Aligns up to the next L3 cache-line boundary (256 bytes).
  BigByteConverter alignToL3CacheLine() => alignTo(256);

  /// Checks if this size is aligned to L1 cache-line boundary (64 bytes).
  bool get isL1CacheAligned => isAlignedTo(64);

  /// Checks if this size is aligned to L2 cache-line boundary (128 bytes).
  bool get isL2CacheAligned => isAlignedTo(128);

  /// Checks if this size is aligned to L3 cache-line boundary (256 bytes).
  bool get isL3CacheAligned => isAlignedTo(256);

  /// Aligns down to the previous L1 cache-line boundary (64 bytes).
  BigByteConverter alignDownToL1CacheLine() => alignDownTo(64);

  /// Aligns down to the previous L2 cache-line boundary (128 bytes).
  BigByteConverter alignDownToL2CacheLine() => alignDownTo(128);

  /// Aligns down to the previous L3 cache-line boundary (256 bytes).
  BigByteConverter alignDownToL3CacheLine() => alignDownTo(256);

  // ============================================
  // Binary String Representation
  // ============================================

  /// Returns the binary representation of the bits.
  String toBinaryString() => _converter.bits.toRadixString(2);

  /// Returns the hexadecimal representation of the bytes.
  String toHexString({bool uppercase = false}) {
    final hex = _converter.bytes.toRadixString(16);
    return uppercase ? hex.toUpperCase() : hex;
  }

  // ============================================
  // Bit Format Display
  // ============================================

  /// Human-readable bit format (e.g., "8 Kb", "1.5 Mb").
  String humanize({int precision = 2}) {
    final bits = _converter.bits;
    if (bits < BigInt.from(1000)) {
      return '$bits b';
    } else if (bits < BigInt.from(1000000)) {
      return '${(bits.toDouble() / 1000).toStringAsFixed(precision)} Kb';
    } else if (bits < BigInt.from(1000000000)) {
      return '${(bits.toDouble() / 1000000).toStringAsFixed(precision)} Mb';
    } else if (bits < BigInt.from(1000000000000)) {
      return '${(bits.toDouble() / 1000000000).toStringAsFixed(precision)} Gb';
    } else {
      return '${(bits.toDouble() / 1000000000000).toStringAsFixed(precision)} Tb';
    }
  }
}

/// Extension providing bit operations accessor for [ByteConverter].
extension BitOperationsExtension on ByteConverter {
  /// Access bit-level operations and properties.
  ///
  /// Example:
  /// ```dart
  /// final size = ByteConverter.fromKiloBytes(1);
  /// print(size.bitOps.totalBits);    // 8000
  /// print(size.bitOps.isPowerOfTwo); // false
  /// print(size.bitOps.humanize());   // "8.00 Kb"
  /// ```
  BitOperations get bitOps => BitOperations(this);
}

/// Extension providing bit operations accessor for [BigByteConverter].
extension BigBitOperationsExtension on BigByteConverter {
  /// Access bit-level operations and properties.
  BigBitOperations get bitOps => BigBitOperations(this);
}
