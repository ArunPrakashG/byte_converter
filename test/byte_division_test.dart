import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('ByteDivision - ChunkDivision', () {
    test('split with even division', () {
      final size = ByteConverter(10485760); // 10 MB exactly
      final chunks = size.divide.split(4096);
      expect(chunks.numChunks, 2560);
      expect(chunks.remainder, 0);
      expect(chunks.chunkSize, 4096);
      expect(chunks.isExact, isTrue);
      expect(chunks.totalBytes, 10485760);
    });

    test('split with remainder', () {
      final size = ByteConverter(10000);
      final chunks = size.divide.split(4096);
      expect(chunks.numChunks, 2);
      expect(chunks.remainder, 1808); // 10000 - (2 * 4096)
      expect(chunks.isExact, isFalse);
      expect(chunks.totalBytes, 10000);
    });

    test('lastChunkUtilization for exact division', () {
      final size = ByteConverter(4096); // Exactly 4096 bytes
      final chunks = size.divide.split(1024);
      // 4096 / 1024 = 4 chunks exactly
      expect(chunks.lastChunkUtilization, equals(1.0));
    });

    test('lastChunkUtilization for partial division', () {
      final size = ByteConverter(5000);
      final chunks = size.divide.split(1024);
      // 5000 / 1024 = 4 full chunks + 904 bytes remainder
      expect(chunks.lastChunkUtilization, closeTo(904.0 / 1024.0, 1e-9));
    });

    test('wastedBytes for partial chunk', () {
      final size = ByteConverter(5000);
      final chunks = size.divide.split(1024);
      final wasted = 1024 - 904; // 120 bytes
      expect(chunks.wastedBytes, equals(wasted));
    });

    test('split with small size relative to chunk', () {
      final size = ByteConverter(100);
      final chunks = size.divide.split(1024);
      expect(chunks.numChunks, 0);
      expect(chunks.remainder, 100);
      expect(chunks.wastedBytes, 924);
    });

    test('split throws on invalid chunk size', () {
      final size = ByteConverter(1000);
      expect(() => size.divide.split(0), throwsArgumentError);
      expect(() => size.divide.split(-1), throwsArgumentError);
    });

    test('toString representation', () {
      final size = ByteConverter(10000);
      final chunks = size.divide.split(4096);
      expect(chunks.toString(), contains('2 chunks'));
      expect(chunks.toString(), contains('4096'));
      expect(chunks.toString(), contains('1808'));
    });
  });

  group('ByteDivision - ByteDistribution', () {
    test('distribute evenly', () {
      // Use exact bytes: 100 * 1024 = 102,400
      final size = ByteConverter(102400);
      final dist = size.divide.distribute(4);
      expect(dist.partSize, 25600);
      expect(dist.numParts, 4);
      expect(dist.remainder, 0);
      expect(dist.isExact, isTrue);
      expect(dist.largestPartSize, 25600);
      expect(dist.smallestPartSize, 25600);
      expect(dist.maxDeviation, 0);
    });

    test('distribute with remainder', () {
      final size = ByteConverter(10000);
      final dist = size.divide.distribute(3);
      expect(dist.partSize, 3333); // 10000 ~/ 3
      expect(dist.remainder, 1); // 10000 % 3
      expect(dist.numParts, 3);
      expect(dist.isExact, isFalse);
      expect(dist.largestPartSize, 3334); // First part gets extra byte
      expect(dist.smallestPartSize, 3333);
      expect(dist.maxDeviation, 1);
    });

    test('distribute with large remainder', () {
      final size = ByteConverter(1000);
      final dist = size.divide.distribute(7);
      expect(dist.partSize, 142);
      expect(dist.remainder, 6); // First 6 parts get 143 bytes, last gets 142
      expect(dist.totalBytes, 1000);
      expect(dist.largestPartSize, 143);
      expect(dist.maxDeviation, 1);
    });

    test('distribute single part', () {
      final size = ByteConverter(5000);
      final dist = size.divide.distribute(1);
      expect(dist.partSize, 5000);
      expect(dist.remainder, 0);
      expect(dist.largestPartSize, 5000);
      expect(dist.smallestPartSize, 5000);
    });

    test('distribute throws on invalid parts', () {
      final size = ByteConverter(1000);
      expect(() => size.divide.distribute(0), throwsArgumentError);
      expect(() => size.divide.distribute(-1), throwsArgumentError);
    });

    test('toString representation', () {
      final size = ByteConverter(10000);
      final dist = size.divide.distribute(3);
      expect(dist.toString(), contains('3 parts'));
      expect(dist.toString(), contains('3333'));
      expect(dist.toString(), contains('remainder'));
    });
  });

  group('ByteDivision - Modulo and Padding', () {
    test('modulo basic operations', () {
      final size = ByteConverter(1000);
      expect(size.divide.modulo(512), equals(488)); // 1000 % 512
      expect(size.divide.modulo(256), equals(232)); // 1000 % 256
      expect(size.divide.modulo(1000), equals(0)); // 1000 % 1000
    });

    test('modulo on aligned value', () {
      // 4096 bytes is divisible by 4096
      final size = ByteConverter(4096);
      expect(size.divide.modulo(4096), equals(0));
    });

    test('paddingTo basic operations', () {
      final size = ByteConverter(1000);
      expect(size.divide.paddingTo(512), equals(24)); // Next boundary at 1024
      expect(size.divide.paddingTo(256), equals(24)); // Next boundary at 1024
    });

    test('paddingTo aligned value returns 0', () {
      final size = ByteConverter(1024);
      expect(size.divide.paddingTo(512), equals(0));
      expect(size.divide.paddingTo(256), equals(0));
    });

    test('paddingTo small boundary', () {
      final size = ByteConverter(100);
      final padding = size.divide.paddingTo(64);
      // 100 + 28 = 128 (next 64-byte boundary)
      expect(padding, equals(28));
    });

    test('modulo throws on invalid boundary', () {
      final size = ByteConverter(1000);
      expect(() => size.divide.modulo(0), throwsArgumentError);
      expect(() => size.divide.modulo(-1), throwsArgumentError);
    });

    test('paddingTo throws on invalid boundary', () {
      final size = ByteConverter(1000);
      expect(() => size.divide.paddingTo(0), throwsArgumentError);
      expect(() => size.divide.paddingTo(-1), throwsArgumentError);
    });
  });

  group('ByteDivision - Edge Cases', () {
    test('split zero-sized buffer', () {
      final size = ByteConverter(0);
      final chunks = size.divide.split(1024);
      expect(chunks.numChunks, 0);
      expect(chunks.remainder, 0);
      expect(chunks.isExact, isTrue);
    });

    test('distribute zero bytes', () {
      final size = ByteConverter(0);
      final dist = size.divide.distribute(10);
      expect(dist.partSize, 0);
      expect(dist.remainder, 0);
      expect(dist.isExact, isTrue);
    });

    test('split by 1 byte', () {
      final size = ByteConverter(5000);
      final chunks = size.divide.split(1);
      expect(chunks.numChunks, 5000);
      expect(chunks.remainder, 0);
    });

    test('split larger than total', () {
      final size = ByteConverter(100);
      final chunks = size.divide.split(1024);
      expect(chunks.numChunks, 0);
      expect(chunks.remainder, 100);
      expect(chunks.wastedBytes, 924);
    });
  });
}
