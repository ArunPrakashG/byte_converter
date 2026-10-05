import 'dart:math' as math;

import '_parsing.dart';
import 'byte_enums.dart';
import 'parse_result.dart';
// ignore_for_file: prefer_constructors_over_static_methods

/// High-performance byte unit converter with caching.
///
/// Represents a quantity of data stored as bytes (and equivalent bits),
/// with helpers for arithmetic, alignment, parsing, and human-readable
/// formatting across SI/IEC/JEDEC standards.
class ByteConverter implements Comparable<ByteConverter> {
  /// Creates a converter from a [bytes] value.
  ///
  /// Throws [ArgumentError] if [bytes] is negative, NaN or infinite.
  ByteConverter(double bytes) : this._(bytes, _bitsFor(bytes));

  // Constructors
  ByteConverter._(this._bytes, this._bits) {
    if (_bytes.isNaN || _bytes.isInfinite) {
      throw ArgumentError('Bytes must be a finite number');
    }
    if (_bytes < 0) throw ArgumentError('Bytes cannot be negative');
  }

  // Beyond this many bytes, `bytes * 8` no longer fits exactly in an int
  // (or a double mantissa), so ordering/equality fall back to [_bytes].
  static const _exactBitsLimit = 1e15;

  static int _bitsFor(double bytes) =>
      bytes.isNaN || bytes.isInfinite || bytes < 0 ? 0 : (bytes * 8.0).ceil();

  bool get _bitsExact => _bytes < _exactBitsLimit;

  /// Creates a converter from [bits].
  ///
  /// Throws [ArgumentError] if [bits] is negative.
  factory ByteConverter.withBits(int bits) {
    if (bits < 0) throw ArgumentError('Bits cannot be negative');
    return ByteConverter._(bits / 8.0, bits);
  }

  // Named constructors for decimal units
  /// Creates a converter from kilobytes (SI, 1000^1).
  ByteConverter.fromKiloBytes(double value) : this(value * _KB);

  /// Creates a converter from megabytes (SI, 1000^2).
  ByteConverter.fromMegaBytes(double value) : this(value * _MB);

  /// Creates a converter from gigabytes (SI, 1000^3).
  ByteConverter.fromGigaBytes(double value) : this(value * _GB);

  /// Creates a converter from terabytes (SI, 1000^4).
  ByteConverter.fromTeraBytes(double value) : this(value * _TB);

  /// Creates a converter from petabytes (SI, 1000^5).
  ByteConverter.fromPetaBytes(double value) : this(value * _PB);

  // Named constructors for binary units
  /// Creates a converter from kibibytes (IEC, 1024^1).
  ByteConverter.fromKibiBytes(double value) : this(value * _KIB);

  /// Creates a converter from mebibytes (IEC, 1024^2).
  ByteConverter.fromMebiBytes(double value) : this(value * _MIB);

  /// Creates a converter from gibibytes (IEC, 1024^3).
  ByteConverter.fromGibiBytes(double value) : this(value * _GIB);

  /// Creates a converter from tebibytes (IEC, 1024^4).
  ByteConverter.fromTebiBytes(double value) : this(value * _TIB);

  /// Creates a converter from pebibytes (IEC, 1024^5).
  ByteConverter.fromPebiBytes(double value) : this(value * _PIB);

  /// Reconstructs a [ByteConverter] from a JSON map produced by [toJson],
  /// expecting a numeric value under the key `bytes`.
  ///
  /// Accepts any JSON number (`int` or `double`) as well as numeric strings.
  factory ByteConverter.fromJson(Map<String, dynamic> json) {
    final raw = json['bytes'];
    final value = switch (raw) {
      num n => n.toDouble(),
      String s => double.tryParse(s),
      _ => null,
    };
    if (value == null) {
      throw FormatException('Expected a numeric "bytes" value, got: $raw');
    }
    return ByteConverter(value);
  }

  // Unit conversion constants
  static const _KB = 1000.0;
  static const _MB = _KB * 1000;
  static const _GB = _MB * 1000;
  static const _TB = _GB * 1000;
  static const _PB = _TB * 1000;

  static const _KIB = 1024.0;
  static const _MIB = _KIB * 1024;
  static const _GIB = _MIB * 1024;
  static const _TIB = _GIB * 1024;
  static const _PIB = _TIB * 1024;

  // Core data
  final double _bytes;
  final int _bits;

  // Cached conversions
  late final double _kiloBytes = _bytes / _KB;
  late final double _megaBytes = _bytes / _MB;
  late final double _gigaBytes = _bytes / _GB;
  late final String _cachedString = _calculateString();

  // Optimized getters
  /// Value in kilobytes (SI).
  double get kiloBytes => _kiloBytes;

  /// Value in megabytes (SI).
  double get megaBytes => _megaBytes;

  /// Value in gigabytes (SI).
  double get gigaBytes => _gigaBytes;

  /// Value in terabytes (SI).
  double get teraBytes => _bytes / _TB;

  /// Value in petabytes (SI).
  double get petaBytes => _bytes / _PB;

  /// Value in kibibytes (IEC).
  double get kibiBytes => _bytes / _KIB;

  /// Value in mebibytes (IEC).
  double get mebiBytes => _bytes / _MIB;

  /// Value in gibibytes (IEC).
  double get gibiBytes => _bytes / _GIB;

  /// Value in tebibytes (IEC).
  double get tebiBytes => _bytes / _TIB;

  /// Value in pebibytes (IEC).
  double get pebiBytes => _bytes / _PIB;

  /// Exact byte representation of this value.
  double get bytes => _bytes;

  /// Returns [bytes] rounded to [precision] fraction digits (no unit).
  num asBytes({int precision = 2}) => _withPrecision(_bytes, precision);

  /// Exact bit representation of this value.
  int get bits => _bits;

  // Math operations
  /// Adds [other] to this value.
  ByteConverter operator +(ByteConverter other) {
    return ByteConverter._(
      _bytes + other._bytes,
      _bits + other._bits,
    );
  }

  /// Subtracts [other] from this value.
  ByteConverter operator -(ByteConverter other) {
    return ByteConverter._(
      _bytes - other._bytes,
      _bits - other._bits,
    );
  }

  /// Multiplies by [factor].
  ByteConverter operator *(num factor) => ByteConverter(_bytes * factor);

  /// Divides by [divisor].
  ByteConverter operator /(num divisor) => ByteConverter(_bytes / divisor);

  // Comparison operators
  /// True if this value is greater than [other].
  bool operator >(ByteConverter other) => compareTo(other) > 0;

  /// True if this value is less than [other].
  bool operator <(ByteConverter other) => compareTo(other) < 0;

  /// True if this value is less than or equal to [other].
  bool operator <=(ByteConverter other) => compareTo(other) <= 0;

  /// True if this value is greater than or equal to [other].
  bool operator >=(ByteConverter other) => compareTo(other) >= 0;

  // Rounding methods
  @override
  int compareTo(ByteConverter other) => _bitsExact && other._bitsExact
      ? _bits.compareTo(other._bits)
      : _bytes.compareTo(other._bytes);

  // Cached string output (auto-scaled SI, up to quettabytes).
  String _calculateString() =>
      humanize(_bytes, const HumanizeOptions(precision: 2)).text;

  num _withPrecision(double value, int precision) {
    if (precision < 0) return value;
    // Handle whole numbers without decimal places
    if (value % 1 == 0) return value.toInt();
    final factor = math.pow(10, precision);
    return (value * factor).round() / factor;
  }

  /// Parses a string like "1.5 GB", "2GiB", "100 KB", "10 Mbit" into a ByteConverter.
  static ByteConverter parse(
    String input, {
    ByteStandard standard = ByteStandard.si,
    bool strictBits = false,
  }) {
    final r = parseSize<SizeUnit>(
      input: input,
      standard: standard,
      strictBits: strictBits,
    );
    return ByteConverter(r.valueInBytes);
  }

  /// Safe parsing variant that never throws and returns diagnostics on failure.
  static ParseResult<ByteConverter> tryParse(
    String input, {
    ByteStandard standard = ByteStandard.si,
    bool strictBits = false,
  }) {
    try {
      final r = parseSize<SizeUnit>(
        input: input,
        standard: standard,
        strictBits: strictBits,
      );
      if (r.valueInBytes.isNaN || r.valueInBytes.isInfinite) {
        throw FormatException('Invalid numeric value in input: $input');
      }
      if (r.valueInBytes < 0) {
        return ParseResult.failure(
          originalInput: input,
          error: const ParseError(message: 'Bytes cannot be negative'),
          normalizedInput: r.normalizedInput,
        );
      }
      final value = ByteConverter(r.valueInBytes);
      return ParseResult.success(
        originalInput: input,
        value: value,
        normalizedInput: r.normalizedInput,
        detectedUnit: r.unitSymbol,
        isBitInput: r.isBitInput,
        parsedNumber: r.rawValue,
      );
    } on FormatException catch (e) {
      return ParseResult.failure(
        originalInput: input,
        error: ParseError(
          message: e.message,
          position: e.offset,
          exception: e,
        ),
        normalizedInput: input.trim().isEmpty ? null : input.trim(),
      );
    }
  }

  // Override Object methods
  @override
  String toString() => _cachedString;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      identical(this, other) || other is ByteConverter && compareTo(other) == 0;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => _bitsExact ? _bits.hashCode : _bytes.hashCode;

  // JSON serialization
  /// Serializes this value to a JSON map containing the byte count.
  Map<String, dynamic> toJson() => {'bytes': _bytes};
}
