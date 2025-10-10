import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('ByteStats', () {
    test('sum and average across value types', () {
      final items = [
        ByteConverter(1024),
        2048,
        512.0,
      ];
      expect(ByteStats.sum(items), closeTo(3584, 1e-9));
      expect(ByteStats.average(items), closeTo(3584 / 3, 1e-9));
    });

    test('percentile interpolation', () {
      final values = [
        ByteConverter(100),
        ByteConverter(200),
        ByteConverter(300),
        ByteConverter(400),
      ];
      expect(ByteStats.percentile(values, 50), closeTo(250, 1e-9));
      expect(ByteStats.percentile(values, 90), closeTo(370, 1e-9));
    });

    test('histogram buckets', () {
      final histogram = ByteStats.histogram(
        [100, 200, 400, 800],
        buckets: const [200, 500],
      );
      expect(histogram.totalCount, 4);
      expect(histogram.buckets.length, 3);
      expect(histogram.buckets.first.count, 2);
    });
  });

  group('BigByteStats', () {
    test('sum and percentile', () {
      final items = [
        BigByteConverter(BigInt.from(1024)),
        BigInt.from(2048),
        512,
      ];
      expect(BigByteStats.sum(items), BigInt.from(3584));
      expect(BigByteStats.percentile(items, 50), closeTo(2048, 1e-6));
    });

    test('histogram', () {
      final histogram = BigByteStats.histogram(
        [BigInt.from(100), BigInt.from(200), BigInt.from(600)],
        buckets: [BigInt.from(200), BigInt.from(400)],
      );
      expect(histogram.totalCount, 3);
      expect(histogram.buckets.length, 3);
      expect(histogram.buckets.first.count, 2);
    });
  });
}
