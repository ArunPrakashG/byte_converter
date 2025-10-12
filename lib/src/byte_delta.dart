import 'big_byte_converter.dart';
import 'byte_converter_base.dart';

class ByteDelta {
  ByteDelta(this.magnitude, {this.isNegative = false})
      : assert(!magnitude.isNegative, 'Magnitude must be non-negative');

  final BigInt magnitude;
  final bool isNegative;

  BigInt get signed => isNegative ? -magnitude : magnitude;

  ByteDelta abs() => ByteDelta(magnitude, isNegative: false);

  ByteDelta operator +(ByteDelta other) {
    final a = signed;
    final b = other.signed;
    final s = a + b;
    return ByteDelta(s.abs(), isNegative: s.isNegative);
  }

  ByteDelta operator -(ByteDelta other) =>
      this + ByteDelta(other.magnitude, isNegative: !other.isNegative);

  ByteConverter apply(ByteConverter base) {
    final value = base.bytes + signed.toDouble();
    if (value < 0) {
      throw ArgumentError('Resulting bytes cannot be negative');
    }
    return ByteConverter(value);
  }

  BigByteConverter applyBig(BigByteConverter base) {
    final value = base.asBytes + signed;
    if (value.isNegative) {
      throw ArgumentError('Resulting bytes cannot be negative');
    }
    return BigByteConverter(value);
  }
}
