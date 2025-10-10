import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('Cross-standard parsing fallback', () {
    const tolerance = 1e-6;

    test('ByteConverter parses IEC unit when SI requested', () {
      final value = ByteConverter.parse('1 GiB', standard: ByteStandard.si);
      expect(
        value.bytes,
        closeTo(1024 * 1024 * 1024, tolerance),
      );
    });

    test('ByteConverter parses SI unit when IEC requested', () {
      final value = ByteConverter.parse('5 MB', standard: ByteStandard.iec);
      expect(value.bytes, closeTo(5 * 1000 * 1000, tolerance));
    });

    test('BigByteConverter respects fallback across standards', () {
      final big = BigByteConverter.parse('3 TiB', standard: ByteStandard.si);
      final expectedBytes = BigInt.from(1099511627776) * BigInt.from(3);
      expect(big.asBytes, expectedBytes);
    });

    test('Expression parsing mixes IEC and SI inputs', () {
      final value = ByteConverter.parse(
        '(1 GiB + 500 MB)',
        standard: ByteStandard.si,
      );
      final expectedBytes = 1024 * 1024 * 1024 + 500 * 1000 * 1000;
      expect(value.bytes, closeTo(expectedBytes.toDouble(), tolerance));
    });

    test('DataRate parsing falls back across standards', () {
      final rate = DataRate.parse('12 MiB/s', standard: ByteStandard.si);
      final expectedBytesPerSecond = 12 * 1024 * 1024;
      expect(rate.bytesPerSecond, closeTo(expectedBytesPerSecond, tolerance));
    });
  });
}
