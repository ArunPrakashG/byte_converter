import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('BigDataRate', () {
    test('parsing and formatting', () {
      final rate = BigDataRate.parse('10 Mbps');
      expect(rate.bitsPerSecond, BigInt.from(10 * 1000 * 1000));
      final rendered = rate.toHumanReadableAuto();
      expect(rendered, contains('/s'));
    });

    test('tryParse diagnostics', () {
      final success = BigDataRate.tryParse('5 MB/s');
      expect(success.isSuccess, isTrue);
      final failure = BigDataRate.tryParse('-1 Mbps');
      expect(failure.isSuccess, isFalse);
      expect(failure.error?.message, contains('Rate cannot be negative'));
    });

    test('transferable bytes conversion', () {
      final rate = BigDataRate.megaBitsPerSecond(BigInt.from(100));
      final bytes = rate.transferableBytes(const Duration(milliseconds: 250));
      expect(bytes.bytes > BigInt.zero, isTrue);
    });

    test('interop with DataRate', () {
      final bigRate = BigDataRate.kibiBitsPerSecond(BigInt.from(2048));
      final regular = bigRate.toDataRate();
      expect(regular.bitsPerSecond, closeTo(2048 * 1024.0, 1e-6));
    });
  });
}
