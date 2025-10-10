import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('TransferPlan', () {
    test('progress metrics from elapsed duration', () {
      final total = ByteConverter(1000);
      final rate = DataRate.bytesPerSecond(100);
      final plan = total.estimateTransfer(
        rate,
        elapsed: const Duration(seconds: 5),
      );
      expect(plan.transferredBytes.asBytes(), closeTo(500, 1e-9));
      expect(plan.percentComplete, closeTo(50, 1e-6));
      expect(plan.remainingBytes.asBytes(), closeTo(500, 1e-9));
      expect(plan.remainingDuration, equals(const Duration(seconds: 5)));
      expect(plan.etaString(), isNotEmpty);
    });

    test('explicit transferred bytes', () {
      final rate = DataRate.kiloBytesPerSecond(2);
      final plan = TransferPlan(
        totalBytes: ByteConverter(8000),
        rate: rate,
        transferredBytes: ByteConverter(2000),
      );
      expect(plan.elapsed, equals(const Duration(seconds: 1)));
      expect(plan.progressFraction, closeTo(0.25, 1e-9));
    });

    test('transferableBytes helpers', () {
      final rate = DataRate.megaBytesPerSecond(1);
      final bytes = rate.transferableBytes(const Duration(seconds: 2));
      expect(bytes.asBytes(), closeTo(2 * 1000 * 1000, 1e-3));

      final bigRate = BigDataRate.gigaBitsPerSecond(BigInt.from(10));
      final bigBytes =
          bigRate.transferableBytes(const Duration(milliseconds: 1200));
      expect(bigBytes.bytes > BigInt.zero, isTrue);
    });
  });
}
