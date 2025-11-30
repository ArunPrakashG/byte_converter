import 'package:byte_converter/byte_converter.dart';
import 'package:byte_converter/src/humanize_options.dart' show HumanizeOptions;
import 'package:test/test.dart';

void main() {
  group('BitOperations', () {
    group('bit value accessors', () {
      test('totalBits returns correct count', () {
        final size = ByteConverter.fromKiloBytes(1);
        expect(size.bitOps.totalBits, 8000);
      });

      test('asBigInt returns BigInt representation', () {
        final size = ByteConverter.fromKiloBytes(1);
        expect(size.bitOps.asBigInt, BigInt.from(8000));
      });

      test('kilobits returns correct value', () {
        final size = ByteConverter.fromKiloBytes(1);
        expect(size.bitOps.kilobits, 8.0);
      });

      test('megabits returns correct value', () {
        final size = ByteConverter.fromMegaBytes(1);
        expect(size.bitOps.megabits, 8.0);
      });

      test('gigabits returns correct value', () {
        final size = ByteConverter.fromGigaBytes(1);
        expect(size.bitOps.gigabits, 8.0);
      });

      test('kibibits uses binary prefix', () {
        final size = ByteConverter.fromKibiBytes(1);
        expect(size.bitOps.kibibits, 8.0);
      });
    });

    group('bit properties', () {
      test('isPowerOfTwo returns true for power of two', () {
        expect(ByteConverter(1024).bitOps.isPowerOfTwo, isTrue);
        expect(ByteConverter(512).bitOps.isPowerOfTwo, isTrue);
        expect(ByteConverter(1).bitOps.isPowerOfTwo, isTrue);
      });

      test('isPowerOfTwo returns false for non-power of two', () {
        expect(ByteConverter(1000).bitOps.isPowerOfTwo, isFalse);
        expect(ByteConverter(100).bitOps.isPowerOfTwo, isFalse);
      });

      test('isByteAligned checks divisibility by 8', () {
        expect(ByteConverter(8).bitOps.isByteAligned, isTrue);
        expect(ByteConverter(16).bitOps.isByteAligned, isTrue);
      });

      test('isWordAligned checks divisibility by 4', () {
        expect(ByteConverter(4).bitOps.isWordAligned, isTrue);
        expect(ByteConverter(8).bitOps.isWordAligned, isTrue);
        expect(ByteConverter(3).bitOps.isWordAligned, isFalse);
      });

      test('isDoubleWordAligned checks divisibility by 8', () {
        expect(ByteConverter(8).bitOps.isDoubleWordAligned, isTrue);
        expect(ByteConverter(16).bitOps.isDoubleWordAligned, isTrue);
        expect(ByteConverter(4).bitOps.isDoubleWordAligned, isFalse);
      });

      test('bitLength returns minimum bits needed', () {
        expect(ByteConverter(1).bitOps.bitLength, greaterThan(0));
        expect(ByteConverter(255).bitOps.bitLength,
            11); // 255 bytes * 8 = 2040 bits
      });

      test('popCount counts set bits', () {
        expect(ByteConverter.withBits(7).bitOps.popCount, 3); // 111 = 3 bits
        expect(ByteConverter.withBits(8).bitOps.popCount, 1); // 1000 = 1 bit
      });
    });

    group('bit manipulation', () {
      test('setBit sets the specified bit', () {
        final size = ByteConverter.withBits(0);
        final result = size.bitOps.setBit(3);
        expect(result.bits, 8); // 2^3 = 8
      });

      test('clearBit clears the specified bit', () {
        final size = ByteConverter.withBits(15); // 1111
        final result = size.bitOps.clearBit(0);
        expect(result.bits, 14); // 1110
      });

      test('toggleBit toggles the specified bit', () {
        final size = ByteConverter.withBits(5); // 101
        expect(size.bitOps.toggleBit(1).bits, 7); // 111
        expect(size.bitOps.toggleBit(0).bits, 4); // 100
      });

      test('testBit checks if bit is set', () {
        final size = ByteConverter.withBits(5); // 101
        expect(size.bitOps.testBit(0), isTrue);
        expect(size.bitOps.testBit(1), isFalse);
        expect(size.bitOps.testBit(2), isTrue);
      });

      test('shiftLeft shifts bits left', () {
        final size = ByteConverter.withBits(1);
        expect(size.bitOps.shiftLeft(3).bits, 8);
      });

      test('shiftRight shifts bits right', () {
        final size = ByteConverter.withBits(8);
        expect(size.bitOps.shiftRight(3).bits, 1);
      });

      test('setBit throws for invalid index', () {
        final size = ByteConverter.withBits(0);
        expect(() => size.bitOps.setBit(-1), throwsRangeError);
        expect(() => size.bitOps.setBit(64), throwsRangeError);
      });
    });

    group('alignment helpers', () {
      test('nextPowerOfTwo rounds up', () {
        expect(ByteConverter(100).bitOps.nextPowerOfTwo.bytes, 128);
        expect(ByteConverter(1000).bitOps.nextPowerOfTwo.bytes, 1024);
        expect(ByteConverter(1024).bitOps.nextPowerOfTwo.bytes, 1024);
      });

      test('prevPowerOfTwo rounds down', () {
        expect(ByteConverter(100).bitOps.prevPowerOfTwo.bytes, 64);
        expect(ByteConverter(1000).bitOps.prevPowerOfTwo.bytes, 512);
        expect(ByteConverter(1024).bitOps.prevPowerOfTwo.bytes, 1024);
      });

      test('alignTo aligns up to boundary', () {
        expect(ByteConverter(100).bitOps.alignTo(64).bytes, 128);
        expect(ByteConverter(4000).bitOps.alignTo(4096).bytes, 4096);
      });

      test('alignDownTo aligns down to boundary', () {
        expect(ByteConverter(100).bitOps.alignDownTo(64).bytes, 64);
        expect(ByteConverter(5000).bitOps.alignDownTo(4096).bytes, 4096);
      });
    });

    group('string representations', () {
      test('toBinaryString returns binary', () {
        final size = ByteConverter.withBits(10); // 1010
        expect(size.bitOps.toBinaryString(), '1010');
      });

      test('toBinaryString pads to length', () {
        final size = ByteConverter.withBits(5); // 101
        expect(size.bitOps.toBinaryString(padTo: 8), '00000101');
      });

      test('toHexString returns hex', () {
        final size = ByteConverter(255);
        expect(size.bitOps.toHexString(), 'ff');
        expect(size.bitOps.toHexString(uppercase: true), 'FF');
      });

      test('toOctalString returns octal', () {
        final size = ByteConverter(8);
        expect(size.bitOps.toOctalString(), '10');
      });
    });

    group('bit format display', () {
      test('humanize formats bits', () {
        expect(
            ByteConverter.fromKiloBytes(1).bitOps.humanize(), contains('Kb'));
        expect(
            ByteConverter.fromMegaBytes(1).bitOps.humanize(), contains('Mb'));
      });

      test('humanizeIEC uses binary prefixes', () {
        expect(ByteConverter.fromKibiBytes(1).bitOps.humanizeIEC(),
            contains('Kib'));
      });
    });
  });

  group('BigBitOperations', () {
    test('totalBits returns BigInt', () {
      final size = BigByteConverter.fromGigaBytes(BigInt.from(1));
      expect(size.bitOps.totalBits, isA<BigInt>());
      expect(size.bitOps.totalBits, BigInt.from(8000000000));
    });

    test('isPowerOfTwo works with BigInt', () {
      expect(
        BigByteConverter(BigInt.from(1024)).bitOps.isPowerOfTwo,
        isTrue,
      );
      expect(
        BigByteConverter(BigInt.from(1000)).bitOps.isPowerOfTwo,
        isFalse,
      );
    });

    test('setBit works with BigInt', () {
      final size = BigByteConverter.withBits(BigInt.zero);
      final result = size.bitOps.setBit(100);
      expect(result.bitOps.testBit(100), isTrue);
    });
  });

  group('ByteRounding', () {
    group('round', () {
      test('rounds halves away from zero', () {
        expect(ByteRounding.round(1.5, precision: 0), 2.0);
        expect(ByteRounding.round(2.5, precision: 0), 3.0);
        expect(ByteRounding.round(-1.5, precision: 0), -2.0);
      });

      test('respects precision', () {
        expect(ByteRounding.round(1.555, precision: 2), 1.56);
        expect(ByteRounding.round(1.554, precision: 2), 1.55);
      });
    });

    group('floor', () {
      test('rounds toward negative infinity', () {
        expect(ByteRounding.floor(1.9, precision: 0), 1.0);
        expect(ByteRounding.floor(-1.1, precision: 0), -2.0);
      });
    });

    group('ceil', () {
      test('rounds toward positive infinity', () {
        expect(ByteRounding.ceil(1.1, precision: 0), 2.0);
        expect(ByteRounding.ceil(-1.9, precision: 0), -1.0);
      });
    });

    group('truncate', () {
      test('rounds toward zero', () {
        expect(ByteRounding.truncate(1.9, precision: 0), 1.0);
        expect(ByteRounding.truncate(-1.9, precision: 0), -1.0);
      });
    });

    group('halfUp', () {
      test('rounds halves toward positive infinity', () {
        expect(ByteRounding.halfUp(1.5, precision: 0), 2.0);
        expect(ByteRounding.halfUp(-1.5, precision: 0), -1.0);
      });
    });

    group('halfEven (banker\'s rounding)', () {
      test('rounds halves to nearest even', () {
        expect(ByteRounding.halfEven(0.5, precision: 0), 0.0);
        expect(ByteRounding.halfEven(1.5, precision: 0), 2.0);
        expect(ByteRounding.halfEven(2.5, precision: 0), 2.0);
        expect(ByteRounding.halfEven(3.5, precision: 0), 4.0);
        expect(ByteRounding.halfEven(4.5, precision: 0), 4.0);
      });
    });

    group('halfAwayFromZero', () {
      test('rounds halves away from zero', () {
        expect(ByteRounding.halfAwayFromZero(1.5, precision: 0), 2.0);
        expect(ByteRounding.halfAwayFromZero(-1.5, precision: 0), -2.0);
      });
    });

    group('halfTowardZero', () {
      test('rounds halves toward zero', () {
        expect(ByteRounding.halfTowardZero(1.5, precision: 0), 1.0);
        expect(ByteRounding.halfTowardZero(-1.5, precision: 0), -1.0);
      });
    });

    group('withMode', () {
      test('uses specified ByteRoundingMode', () {
        expect(
          ByteRounding.withMode(1.5, precision: 0, mode: ByteRoundingMode.floor),
          1.0,
        );
        expect(
          ByteRounding.withMode(1.5, precision: 0, mode: ByteRoundingMode.ceil),
          2.0,
        );
        expect(
          ByteRounding.withMode(2.5, precision: 0, mode: ByteRoundingMode.halfEven),
          2.0,
        );
      });
    });

    group('extension methods', () {
      test('roundWithMode works on double', () {
        expect(
            1.5.roundWithMode(precision: 0, mode: ByteRoundingMode.halfEven), 2.0);
      });

      test('roundHalfEven uses banker\'s rounding', () {
        expect(2.5.roundHalfEven(precision: 0), 2.0);
        expect(3.5.roundHalfEven(precision: 0), 4.0);
      });

      test('truncateWithPrecision truncates', () {
        expect(1.999.truncateWithPrecision(precision: 2), 1.99);
      });
    });
  });

  group('HumanizeOptions symbol customization', () {
    test('symbols property is available', () {
      const options = HumanizeOptions(
        symbols: {'KB': 'Ko', 'MB': 'Mo'},
      );
      expect(options.symbols, {'KB': 'Ko', 'MB': 'Mo'});
    });

    test('zeroValue property is available', () {
      const options = HumanizeOptions(zeroValue: 'Empty');
      expect(options.zeroValue, 'Empty');
    });
  });
}
