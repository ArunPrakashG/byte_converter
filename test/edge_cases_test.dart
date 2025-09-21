import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('Negative and edge cases', () {
    test('Invalid size format throws', () {
      expect(() => ByteConverter.parse('abc'), throwsFormatException);
      expect(() => BigByteConverter.parse('1.23 XB'), throwsFormatException);
    });

    test('Unknown units per standard throw', () {
      expect(
        () => ByteConverter.parse('1 KiB'),
        throwsFormatException,
      );
      expect(
        () => ByteConverter.parse('1 KB', standard: ByteStandard.iec),
        throwsFormatException,
      );
      expect(
        () => DataRate.parse('1 KiB/s'),
        throwsFormatException,
      );
      expect(
        () => DataRate.parse('1 MB/s', standard: ByteStandard.iec),
        throwsFormatException,
      );
    });

    test('Ambiguous separators choose last as decimal', () {
      // 1,234.56 -> 1234.56 KB
      final a = ByteConverter.parse('1,234.56 KB');
      expect(a.asBytes(), closeTo(1234560.0, 1e-6));
      // 1.234,56 -> 1234.56 KB
      final b = ByteConverter.parse('1.234,56 KB');
      expect(b.asBytes(), closeTo(1234560.0, 1e-6));
    });

    test('Signs and spacing with localization', () {
      final pos = ByteConverter.parse('+1\u00A0234,5 KB');
      ByteConverter neg() => ByteConverter.parse('-1\u00A0234,5 KB');
      expect(pos.asBytes(), closeTo(1234500.0, 1e-6));
      // Negative sizes produce an ArgumentError via constructor validation
      expect(neg, throwsArgumentError);
    });
  });
}
