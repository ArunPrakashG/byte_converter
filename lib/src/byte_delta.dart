import 'big_byte_converter.dart';
import 'byte_converter_base.dart';

/// Represents a signed change in bytes with arbitrary precision.
class ByteDelta {
  /// Creates a [ByteDelta] with non-negative [magnitude] and optional sign.
  ByteDelta(this.magnitude, {this.isNegative = false})
      : assert(!magnitude.isNegative, 'Magnitude must be non-negative');

  /// Absolute magnitude of the delta in bytes.
  final BigInt magnitude;

  /// Whether the delta is negative.
  final bool isNegative;

  /// Signed value as [BigInt].
  BigInt get signed => isNegative ? -magnitude : magnitude;

  /// Absolute delta (non-negative).
  ByteDelta abs() => ByteDelta(magnitude, isNegative: false);

  /// Sum of two deltas.
  ByteDelta operator +(ByteDelta other) {
    final a = signed;
    final b = other.signed;
    final s = a + b;
    return ByteDelta(s.abs(), isNegative: s.isNegative);
  }

  /// Difference between two deltas.
  ByteDelta operator -(ByteDelta other) =>
      this + ByteDelta(other.magnitude, isNegative: !other.isNegative);

  /// Applies this delta to a [ByteConverter], throwing if the result is negative.
  ByteConverter apply(ByteConverter base) {
    final value = base.bytes + signed.toDouble();
    if (value < 0) {
      throw ArgumentError('Resulting bytes cannot be negative');
    }
    return ByteConverter(value);
  }

  /// Applies this delta to a [BigByteConverter], throwing if the result is negative.
  BigByteConverter applyBig(BigByteConverter base) {
    final value = base.asBytes + signed;
    if (value.isNegative) {
      throw ArgumentError('Resulting bytes cannot be negative');
    }
    return BigByteConverter(value);
  }
}
