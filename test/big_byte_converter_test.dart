import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('BigByteConverter Constructors', () {
    test('creates from BigInt bytes', () {
      final converter = BigByteConverter(BigInt.from(1024));
      expect(converter.asBytes, equals(BigInt.from(1024)));
      expect(converter.bits, equals(BigInt.from(8192)));
    });

    test('creates from bits', () {
      final converter = BigByteConverter.withBits(BigInt.from(8192));
      expect(converter.asBytes, equals(BigInt.from(1024)));
      expect(converter.bits, equals(BigInt.from(8192)));
    });

    test('throws on negative bytes', () {
      expect(() => BigByteConverter(BigInt.from(-1)), throwsArgumentError);
    });

    test('throws on negative bits', () {
      expect(() => BigByteConverter.withBits(BigInt.from(-8)),
          throwsArgumentError);
    });

    test('creates from ByteConverter', () {
      final original = ByteConverter(1024);
      final bigConverter = BigByteConverter.fromByteConverter(original);
      expect(bigConverter.asBytes, equals(BigInt.from(1024)));
    });
  });

  group('BigInt Unit Conversions', () {
    test('decimal conversions', () {
      final converter = BigByteConverter(BigInt.from(1000000)); // 1 MB
      expect(converter.kiloBytes, equals(1000.0));
      expect(converter.megaBytes, equals(1.0));
      expect(converter.gigaBytes, equals(0.001));
    });

    test('binary conversions', () {
      final converter = BigByteConverter(BigInt.from(1024)); // 1 KiB
      expect(converter.kibiBytes, equals(1.0));
      expect(converter.mebiBytes, equals(0.0009765625));
    });

    test('exact conversions', () {
      final converter = BigByteConverter(BigInt.from(1000000000)); // 1 GB
      expect(converter.kiloBytesExact, equals(BigInt.from(1000000)));
      expect(converter.megaBytesExact, equals(BigInt.from(1000)));
      expect(converter.gigaBytesExact, equals(BigInt.one));
    });

    test('large unit conversions', () {
      final exaByteValue = BigInt.parse('1000000000000000000'); // 1 EB
      final converter = BigByteConverter(exaByteValue);
      expect(converter.exaBytes, equals(1.0));
      expect(converter.exaBytesExact, equals(BigInt.one));
    });

    test('very large numbers - zettabytes', () {
      final zettaByteValue = BigInt.parse('1000000000000000000000'); // 1 ZB
      final converter = BigByteConverter(zettaByteValue);
      expect(converter.zettaBytes, equals(1.0));
      expect(converter.zettaBytesExact, equals(BigInt.one));
    });

    test('extremely large numbers - yottabytes', () {
      final yottaByteValue = BigInt.parse('1000000000000000000000000'); // 1 YB
      final converter = BigByteConverter(yottaByteValue);
      expect(converter.yottaBytes, equals(1.0));
      expect(converter.yottaBytesExact, equals(BigInt.one));
    });
  });

  group('BigInt Math Operations', () {
    final a = BigByteConverter(BigInt.from(1000));
    final b = BigByteConverter(BigInt.from(500));

    test('addition', () {
      expect((a + b).asBytes, equals(BigInt.from(1500)));
    });

    test('subtraction', () {
      expect((a - b).asBytes, equals(BigInt.from(500)));
    });

    test('multiplication', () {
      expect((a * BigInt.from(2)).asBytes, equals(BigInt.from(2000)));
    });

    test('integer division', () {
      expect((a ~/ BigInt.from(2)).asBytes, equals(BigInt.from(500)));
    });
  });

  group('BigInt Comparison', () {
    final smaller = BigByteConverter(BigInt.from(1000));
    final larger = BigByteConverter(BigInt.from(2000));

    test('comparison operators', () {
      expect(smaller < larger, isTrue);
      expect(larger > smaller, isTrue);
      expect(smaller <= larger, isTrue);
      expect(larger >= smaller, isTrue);
      expect(smaller == BigByteConverter(BigInt.from(1000)), isTrue);
    });

    test('compareTo', () {
      expect(smaller.compareTo(larger), lessThan(0));
      expect(larger.compareTo(smaller), greaterThan(0));
      expect(smaller.compareTo(BigByteConverter(BigInt.from(1000))), equals(0));
    });
  });

  group('BigInt String Formatting', () {
    test('toHumanReadable', () {
      final converter = BigByteConverter(BigInt.from(1536));
      expect(converter.toHumanReadable(BigSizeUnit.KB), equals('1.54 KB'));
      expect(converter.toHumanReadable(BigSizeUnit.B), equals('1536 B'));
    });

    test('toString automatic unit selection', () {
      final kb = BigByteConverter(BigInt.from(1500));
      expect(kb.toString(), equals('1.5 KB'));

      final mb = BigByteConverter(BigInt.from(1500000));
      expect(mb.toString(), equals('1.5 MB'));

      final gb = BigByteConverter(BigInt.from(1500000000));
      expect(gb.toString(), equals('1.5 GB'));
    });

    test('very large number formatting', () {
      final eb = BigByteConverter(BigInt.parse('1500000000000000000'));
      expect(eb.toString(), equals('1.5 EB'));

      final zb = BigByteConverter(BigInt.parse('1500000000000000000000'));
      expect(zb.toString(), equals('1.5 ZB'));

      final yb = BigByteConverter(BigInt.parse('1500000000000000000000000'));
      expect(yb.toString(), equals('1.5 YB'));
    });
  });

  group('BigInt JSON Serialization', () {
    test('toJson/fromJson', () {
      final original = BigByteConverter(BigInt.from(1024));
      final json = original.toJson();
      final restored = BigByteConverter.fromJson(json);
      expect(restored, equals(original));
    });

    test('very large number serialization', () {
      final original =
          BigByteConverter(BigInt.parse('123456789012345678901234567890'));
      final json = original.toJson();
      final restored = BigByteConverter.fromJson(json);
      expect(restored, equals(original));
    });
  });

  group('BigInt Extensions', () {
    test('BigInt extensions work', () {
      final fromExtension = BigInt.from(1024).bytes;
      final fromConstructor = BigByteConverter(BigInt.from(1024));
      expect(fromExtension, equals(fromConstructor));
    });

    test('large unit extensions', () {
      final exaBytes = BigInt.one.exaBytes;
      expect(exaBytes.exaBytesExact, equals(BigInt.one));

      final zettaBytes = BigInt.one.zettaBytes;
      expect(zettaBytes.zettaBytesExact, equals(BigInt.one));

      final yottaBytes = BigInt.one.yottaBytes;
      expect(yottaBytes.yottaBytesExact, equals(BigInt.one));
    });
  });

  group('BigInt Conversion', () {
    test('converts to ByteConverter', () {
      final bigConverter = BigByteConverter(BigInt.from(1024));
      final normalConverter = bigConverter.toByteConverter();
      expect(normalConverter.asBytes(), equals(1024));
    });

    test('precision is maintained for small numbers', () {
      final bigConverter = BigByteConverter(BigInt.from(1024));
      final normalConverter = bigConverter.toByteConverter();
      expect(normalConverter.asBytes(), equals(1024));
    });
  });

  group('BigInt Edge Cases', () {
    test('zero bytes', () {
      final converter = BigByteConverter(BigInt.zero);
      expect(converter.toString(), equals('0 B'));
    });

    test('very large numbers maintain precision', () {
      final largeNumber = BigInt.parse('123456789012345678901234567890');
      final converter = BigByteConverter(largeNumber);
      expect(converter.asBytes, equals(largeNumber));
    });

    test('storage unit calculations', () {
      final converter = BigByteConverter(BigInt.from(4096));
      expect(converter.isWholeBlock, isTrue);
      expect(converter.isWholePage, isTrue);
      expect(converter.blocks, equals(BigInt.one));
      expect(converter.pages, equals(BigInt.one));
    });

    test('rounding methods', () {
      final converter = BigByteConverter(BigInt.from(4000));
      final rounded = converter.roundToBlock();
      expect(rounded.asBytes, equals(BigInt.from(4096)));
    });
  });

  group('Mixed Operations', () {
    test('can work with both BigInt and regular converters', () {
      final bigConverter = BigByteConverter(BigInt.from(1024));
      final normalConverter = ByteConverter(1024);

      // Convert to compare
      final bigAsNormal = bigConverter.toByteConverter();
      expect(bigAsNormal.asBytes(), equals(normalConverter.asBytes()));

      final normalAsBig = BigByteConverter.fromByteConverter(normalConverter);
      expect(normalAsBig.asBytes, equals(bigConverter.asBytes));
    });
  });
}
