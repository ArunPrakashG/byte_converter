import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('BitOperations alignment helpers', () {
    test('isAlignedTo detects alignment correctly', () {
      expect(ByteConverter(4096).bitOps.isAlignedTo(4096), isTrue);
      expect(ByteConverter(4096).bitOps.isAlignedTo(512), isTrue);
      expect(ByteConverter(4096).bitOps.isAlignedTo(1000), isFalse);
      expect(ByteConverter(0).bitOps.isAlignedTo(4096), isTrue);
    });

    test('alignTo aligns up to boundary', () {
      expect(ByteConverter(0).bitOps.alignTo(4096).bytes, 0);
      expect(ByteConverter(1).bitOps.alignTo(4096).bytes, 4096);
      expect(ByteConverter(4095).bitOps.alignTo(4096).bytes, 4096);
      expect(ByteConverter(4097).bitOps.alignTo(4096).bytes, 8192);
    });

    test('alignDownTo aligns down to boundary', () {
      expect(ByteConverter(0).bitOps.alignDownTo(4096).bytes, 0);
      expect(ByteConverter(4095).bitOps.alignDownTo(4096).bytes, 0);
      expect(ByteConverter(4096).bitOps.alignDownTo(4096).bytes, 4096);
      expect(ByteConverter(8193).bitOps.alignDownTo(4096).bytes, 8192);
    });
  });

  group('BigBitOperations alignment helpers', () {
    test('isAlignedTo detects alignment correctly', () {
      final size = BigByteConverter(BigInt.from(4096));
      expect(size.bitOps.isAlignedTo(4096), isTrue);
      expect(size.bitOps.isAlignedTo(512), isTrue);
      expect(size.bitOps.isAlignedTo(1000), isFalse);
      final zero = BigByteConverter(BigInt.zero);
      expect(zero.bitOps.isAlignedTo(4096), isTrue);
    });

    test('alignTo aligns up to boundary', () {
      expect(BigByteConverter(BigInt.zero).bitOps.alignTo(4096).bytes,
          BigInt.zero);
      expect(BigByteConverter(BigInt.one).bitOps.alignTo(4096).bytes,
          BigInt.from(4096));
      expect(BigByteConverter(BigInt.from(4095)).bitOps.alignTo(4096).bytes,
          BigInt.from(4096));
      expect(BigByteConverter(BigInt.from(4097)).bitOps.alignTo(4096).bytes,
          BigInt.from(8192));
    });

    test('alignDownTo aligns down to boundary', () {
      expect(BigByteConverter(BigInt.zero).bitOps.alignDownTo(4096).bytes,
          BigInt.zero);
      expect(BigByteConverter(BigInt.from(4095)).bitOps.alignDownTo(4096).bytes,
          BigInt.zero);
      expect(BigByteConverter(BigInt.from(4096)).bitOps.alignDownTo(4096).bytes,
          BigInt.from(4096));
      expect(BigByteConverter(BigInt.from(8193)).bitOps.alignDownTo(4096).bytes,
          BigInt.from(8192));
    });
  });

  group('BitOperations cache-line alignment', () {
    test('L1 cache-line alignment (64 bytes)', () {
      expect(ByteConverter(64).bitOps.isL1CacheAligned, isTrue);
      expect(ByteConverter(63).bitOps.isL1CacheAligned, isFalse);
      expect(ByteConverter(100).bitOps.alignToL1CacheLine().bytes, 128);
      expect(ByteConverter(128).bitOps.alignDownToL1CacheLine().bytes, 128);
      expect(ByteConverter(100).bitOps.alignDownToL1CacheLine().bytes, 64);
    });

    test('L2 cache-line alignment (128 bytes)', () {
      expect(ByteConverter(128).bitOps.isL2CacheAligned, isTrue);
      expect(ByteConverter(127).bitOps.isL2CacheAligned, isFalse);
      expect(ByteConverter(200).bitOps.alignToL2CacheLine().bytes, 256);
      expect(ByteConverter(256).bitOps.alignDownToL2CacheLine().bytes, 256);
      expect(ByteConverter(200).bitOps.alignDownToL2CacheLine().bytes, 128);
    });

    test('L3 cache-line alignment (256 bytes)', () {
      expect(ByteConverter(256).bitOps.isL3CacheAligned, isTrue);
      expect(ByteConverter(255).bitOps.isL3CacheAligned, isFalse);
      expect(ByteConverter(300).bitOps.alignToL3CacheLine().bytes, 512);
      expect(ByteConverter(512).bitOps.alignDownToL3CacheLine().bytes, 512);
      expect(ByteConverter(300).bitOps.alignDownToL3CacheLine().bytes, 256);
    });

    test('cache alignment on multiple of cache lines', () {
      final size = ByteConverter(1024); // Exactly 1024 bytes
      expect(size.bitOps.isL1CacheAligned, isTrue); // 1024 % 64 == 0
      expect(size.bitOps.isL2CacheAligned, isTrue); // 1024 % 128 == 0
      expect(size.bitOps.isL3CacheAligned, isTrue); // 1024 % 256 == 0
    });

    test('cache alignment on non-multiple', () {
      final size = ByteConverter(1000); // 1000 bytes
      expect(size.bitOps.isL1CacheAligned, isFalse); // 1000 % 64 != 0
      expect(size.bitOps.isL2CacheAligned, isFalse); // 1000 % 128 != 0
      expect(size.bitOps.isL3CacheAligned, isFalse); // 1000 % 256 != 0
    });
  });

  group('BigBitOperations cache-line alignment', () {
    test('L1 cache-line alignment on BigInt', () {
      expect(BigByteConverter(BigInt.from(64)).bitOps.isL1CacheAligned, isTrue);
      expect(
          BigByteConverter(BigInt.from(63)).bitOps.isL1CacheAligned, isFalse);
      expect(
          BigByteConverter(BigInt.from(100)).bitOps.alignToL1CacheLine().bytes,
          BigInt.from(128));
    });

    test('L2 cache-line alignment on BigInt', () {
      expect(
          BigByteConverter(BigInt.from(128)).bitOps.isL2CacheAligned, isTrue);
      expect(
          BigByteConverter(BigInt.from(127)).bitOps.isL2CacheAligned, isFalse);
      expect(
          BigByteConverter(BigInt.from(200)).bitOps.alignToL2CacheLine().bytes,
          BigInt.from(256));
    });

    test('L3 cache-line alignment on BigInt', () {
      expect(
          BigByteConverter(BigInt.from(256)).bitOps.isL3CacheAligned, isTrue);
      expect(
          BigByteConverter(BigInt.from(255)).bitOps.isL3CacheAligned, isFalse);
      expect(
          BigByteConverter(BigInt.from(300)).bitOps.alignToL3CacheLine().bytes,
          BigInt.from(512));
    });

    test('alignDownTo cache boundaries on BigInt', () {
      final size = BigByteConverter(BigInt.from(100));
      expect(size.bitOps.alignDownToL1CacheLine().bytes, BigInt.from(64));
      expect(size.bitOps.alignDownToL2CacheLine().bytes, BigInt.zero);
      expect(size.bitOps.alignDownToL3CacheLine().bytes, BigInt.zero);
    });
  });
}
