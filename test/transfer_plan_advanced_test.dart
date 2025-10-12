import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('TransferPlan advanced scheduling', () {
    test('weighted average across windows with throttle', () {
      // 10s @ 1 MB/s, 10s @ 3 MB/s => avg = 2 MB/s. Throttle 0.5 => 1 MB/s.
      final total = ByteConverter(10 * 1000 * 1000); // 10 MB (SI)
      final plan = TransferPlan(
          totalBytes: total, rate: DataRate.bytesPerSecond(123456));

      plan
        ..addRateWindow(RateWindow(
            rate: DataRate.megaBytesPerSecond(1),
            duration: const Duration(seconds: 10)))
        ..addRateWindow(RateWindow(
            rate: DataRate.megaBytesPerSecond(3),
            duration: const Duration(seconds: 10)))
        ..setThrottle(0.5);

      // Effective is 1 MB/s => 10 MB needs ~10s total.
      final eta = plan.estimatedTotalDuration;
      expect(eta, isNotNull);
      expect(eta!.inSeconds, closeTo(10, 1));

      // With 2 MB already transferred, 8 MB remain => ~8s remaining.
      final progressed =
          plan.copyWith(transferred: ByteConverter(2 * 1000 * 1000));
      final remain = progressed.remainingDuration;
      expect(remain, isNotNull);
      expect(remain!.inSeconds, closeTo(8, 1));
    });

    test('pause/resume affects ETA', () {
      final total = ByteConverter(5 * 1000 * 1000); // 5 MB
      final plan =
          TransferPlan(totalBytes: total, rate: DataRate.megaBytesPerSecond(1));
      // baseline ~5s
      expect(plan.estimatedTotalDuration!.inSeconds, closeTo(5, 1));

      plan.pause();
      expect(plan.estimatedTotalDuration, isNull);
      expect(plan.remainingDuration, isNull);

      plan.resume();
      expect(plan.estimatedTotalDuration, isNotNull);
    });

    test('invalid RateWindow duration throws', () {
      final plan = TransferPlan(
          totalBytes: ByteConverter(1), rate: DataRate.bytesPerSecond(1));
      expect(
        () => plan.addRateWindow(
          RateWindow(rate: DataRate.bytesPerSecond(1), duration: Duration.zero),
        ),
        throwsArgumentError,
      );
    });

    test('extreme throttle values 0 and 1', () {
      final total = ByteConverter(1000 * 1000); // 1 MB
      final plan =
          TransferPlan(totalBytes: total, rate: DataRate.megaBytesPerSecond(1));
      // throttle 0 -> paused-like (no effective throughput)
      plan.setThrottle(0);
      expect(plan.estimatedTotalDuration, isNull);
      expect(plan.remainingDuration, isNull);
      // throttle 1 -> full speed
      plan.setThrottle(1);
      expect(plan.estimatedTotalDuration, isNotNull);
    });

    test('mixed windows with different durations', () {
      final total = ByteConverter(6 * 1000 * 1000); // 6 MB
      final plan =
          TransferPlan(totalBytes: total, rate: DataRate.megaBytesPerSecond(1));
      plan
        ..addRateWindow(RateWindow(
            rate: DataRate.megaBytesPerSecond(1),
            duration: const Duration(seconds: 5)))
        ..addRateWindow(RateWindow(
            rate: DataRate.megaBytesPerSecond(3),
            duration: const Duration(seconds: 5)));
      // Weighted average: (1*5 + 3*5)/10 = 2 MB/s
      expect(plan.estimatedTotalDuration!.inSeconds,
          closeTo(3, 1)); // 6MB / 2MB/s = ~3s
    });
  });
}
