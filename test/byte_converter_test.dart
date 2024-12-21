import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('ByteConverter Constructors', () {
    test('creates from bytes', () {
      final converter = ByteConverter(1024);
      expect(converter.asBytes(), equals(1024));
      expect(converter.bits, equals(8192));
    });

    test('creates from bits', () {
      final converter = ByteConverter.withBits(8192);
      expect(converter.asBytes(), equals(1024));
      expect(converter.bits, equals(8192));
    });

    test('throws on negative bytes', () {
      expect(() => ByteConverter(-1), throwsArgumentError);
    });

    test('throws on negative bits', () {
      expect(() => ByteConverter.withBits(-8), throwsArgumentError);
    });
  });

  group('Unit Conversions', () {
    test('decimal conversions', () {
      final converter = ByteConverter(1000000); // 1 MB
      expect(converter.kiloBytes, equals(1000));
      expect(converter.megaBytes, equals(1));
      expect(converter.gigaBytes, equals(0.001));
    });

    test('binary conversions', () {
      final converter = ByteConverter(1024); // 1 KiB
      expect(converter.kibiBytes, equals(1));
      expect(converter.mebiBytes, equals(0.0009765625));
    });
  });

  group('Math Operations', () {
    final a = ByteConverter(1000);
    final b = ByteConverter(500);

    test('addition', () {
      expect((a + b).asBytes(), equals(1500));
    });

    test('subtraction', () {
      expect((a - b).asBytes(), equals(500));
    });

    test('multiplication', () {
      expect((a * 2).asBytes(), equals(2000));
    });

    test('division', () {
      expect((a / 2).asBytes(), equals(500));
    });
  });

  group('Comparison', () {
    final smaller = ByteConverter(1000);
    final larger = ByteConverter(2000);

    test('comparison operators', () {
      expect(smaller < larger, isTrue);
      expect(larger > smaller, isTrue);
      expect(smaller <= larger, isTrue);
      expect(larger >= smaller, isTrue);
      expect(smaller == ByteConverter(1000), isTrue);
    });

    test('compareTo', () {
      expect(smaller.compareTo(larger), lessThan(0));
      expect(larger.compareTo(smaller), greaterThan(0));
      expect(smaller.compareTo(ByteConverter(1000)), equals(0));
    });
  });

  group('String Formatting', () {
    test('toHumanReadable', () {
      final converter = ByteConverter(1536);
      expect(converter.toHumanReadable(SizeUnit.KB), equals('1.54 KB'));
      expect(converter.toHumanReadable(SizeUnit.B), equals('1536 B'));
    });

    test('integer values', () {
      final converter = ByteConverter(1000);
      expect(converter.toHumanReadable(SizeUnit.B), equals('1000 B'));
      expect(converter.toHumanReadable(SizeUnit.KB), equals('1 KB'));
    });

    test('decimal values', () {
      final converter = ByteConverter(1234.5);
      expect(converter.toHumanReadable(SizeUnit.B), equals('1234.5 B'));
      expect(
        converter.toHumanReadable(SizeUnit.KB, precision: 3),
        equals('1.235 KB'),
      );
    });
  });

  group('JSON Serialization', () {
    test('toJson/fromJson', () {
      final original = ByteConverter(1024);
      final json = original.toJson();
      final restored = ByteConverter.fromJson(json);
      expect(restored, equals(original));
    });
  });

  group('Edge Cases', () {
    test('zero bytes', () {
      final converter = ByteConverter(0);
      expect(converter.toString(), equals('0 B'));
    });

    test('very large numbers', () {
      final converter = ByteConverter(1000000000000000); // 1 PB
      expect(converter.petaBytes, equals(1));
    });

    test('very small numbers', () {
      final converter = ByteConverter(0.1);
      expect(converter.toString(), equals('0.1 B'));
    });
  });
}
