import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('Composite expressions', () {
    test('byte size arithmetic', () {
      final value = ByteConverter.parse('1 GB + 512 MB');
      expect(value.asBytes(), closeTo(1.5 * 1000 * 1000 * 1000, 1));

      final rounded = ByteConverter.tryParse('2 * 512 MB');
      expect(rounded.isSuccess, isTrue);
      expect(rounded.value?.asBytes(), closeTo(1024 * 1000 * 1000, 1));
    });

    test('big byte expressions support large units', () {
      final value = BigByteConverter.parse('1 YiB + 1 ZiB');
      expect(value.asBytes > BigInt.zero, isTrue);
    });

    test('data rate expressions', () {
      final rate = DataRate.parse('2 GiB/5s');
      expect(
          rate.bitsPerSecond, closeTo((2 * 1024 * 1024 * 1024 * 8) / 5, 1e-3));

      final aggregate = DataRate.tryParse('100 Mbps + 50 Mbps');
      expect(aggregate.isSuccess, isTrue);
      expect(aggregate.value?.bitsPerSecond, closeTo(150 * 1000 * 1000, 1));
    });

    test('invalid dimension mixing fails', () {
      expect(
        () => ByteConverter.parse('1 GB + 5s'),
        throwsFormatException,
      );
      final result = DataRate.tryParse('5s - 1 MB');
      expect(result.isSuccess, isFalse);
    });
  });
}
