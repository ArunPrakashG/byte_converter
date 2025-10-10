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

  group('Parsing and Auto Humanize', () {
    test('parse SI units', () {
      final c = ByteConverter.parse('1.5 GB');
      expect(c.gigaBytes, closeTo(1.5, 1e-9));
    });

    test('parse JEDEC units', () {
      final c = ByteConverter.parse('1 MB', standard: ByteStandard.jedec);
      expect(c.asBytes(), equals(1024 * 1024));
    });

    test('auto humanize SI and IEC', () {
      final c = ByteConverter(1024);
      expect(c.toHumanReadableAuto(), equals('1.02 KB'));
      expect(
        c.toHumanReadableAuto(standard: ByteStandard.iec),
        equals('1 KiB'),
      );
    });
  });

  group('ByteConverter.tryParse', () {
    test('returns success with diagnostics for valid input', () {
      final result = ByteConverter.tryParse('1.5 GB');
      expect(result.isSuccess, isTrue);
      expect(result.value, isNotNull);
      expect(result.value!.gigaBytes, closeTo(1.5, 1e-9));
      expect(result.normalizedInput, equals('1.5 GB'));
      expect(result.detectedUnit, equals('GB'));
      expect(result.isBitInput, isFalse);
      expect(result.parsedNumber, closeTo(1.5, 1e-9));
    });

    test('captures bit inputs', () {
      final result = ByteConverter.tryParse('8 Mb');
      expect(result.isSuccess, isTrue);
      expect(result.isBitInput, isTrue);
      expect(result.detectedUnit, equals('Mb'));
      expect(result.normalizedInput, equals('8 Mb'));
    });

    test('returns failure for malformed text', () {
      final result = ByteConverter.tryParse('abc');
      expect(result.isSuccess, isFalse);
      expect(result.value, isNull);
      expect(result.error, isNotNull);
      expect(result.error!.message, contains('Invalid size format'));
    });

    test('returns failure for negative values', () {
      final result = ByteConverter.tryParse('-2 MB');
      expect(result.isSuccess, isFalse);
      expect(result.error, isNotNull);
      expect(result.error!.message, contains('cannot be negative'));
    });
  });

  group('Locale-aware parsing', () {
    test('parses NBSP and comma decimal', () {
      const input = '1\u00A0234,56 KB'; // 1 234,56 KB
      final c = ByteConverter.parse(input);
      expect(c.asBytes(), closeTo(1234560.0, 1e-6));
    });

    test('parses underscores in number', () {
      final c = ByteConverter.parse('12_345.67 MB');
      expect(c.asBytes(), closeTo(12345670000.0, 1e-3));
    });
  });

  group('Full-form parsing and advanced formatting', () {
    test('parses full-form units (SI bytes)', () {
      final c = ByteConverter.parse('1.5 megabytes');
      expect(c.megaBytes, closeTo(1.5, 1e-9));
    });

    test('parses full-form IEC units and bits', () {
      final c1 = ByteConverter.parse('2 kibibytes', standard: ByteStandard.iec);
      expect(c1.kibiBytes, closeTo(2.0, 1e-9));
      final c2 = ByteConverter.parse('10 megabits');
      expect(c2.asBytes(), closeTo(10 * 1e6 / 8, 1e-6));
    });

    test('fullForm output and custom fullForms', () {
      final c = ByteConverter(1500);
      final text = c.toHumanReadableAutoWith(
        const ByteFormatOptions(
          useBytes: true,
          fullForm: true,
        ),
      );
      expect(text, equals('1.5 kilobytes'));

      final text2 = c.toHumanReadableAutoWith(
        const ByteFormatOptions(
          useBytes: true,
          fullForm: true,
          fullForms: {'kilobytes': 'kilo-octets'},
        ),
      );
      expect(text2, equals('1.5 kilo-octets'));
    });

    test('separator, spacer, min/max fraction digits, signed, forced unit', () {
      final c = ByteConverter(1920);
      final text = c.toHumanReadableAuto(
        minimumFractionDigits: 1,
        maximumFractionDigits: 1,
        separator: ',',
        spacer: '',
        signed: true,
        forceUnit: 'KB',
      );
      expect(text, equals('+1,9KB'));
    });
  });

  group('Unified parse auto', () {
    test('returns normal below threshold', () {
      final r = parseByteSizeAuto('1 GB', thresholdBytes: 1000000000000);
      expect(r.isBig, isFalse);
      expect((r as ParsedNormal).value.gigaBytes, closeTo(1.0, 1e-9));
    });

    test('returns big at/above threshold', () {
      final r = parseByteSizeAuto('1 EB', thresholdBytes: 1000000000000);
      expect(r.isBig, isTrue);
      expect((r as ParsedBig).value.exaBytes, closeTo(1.0, 1e-9));
    });
  });

  group('Format options helper', () {
    test('ByteConverter uses options', () {
      final bc = ByteConverter(1024);
      final text = bc.toHumanReadableAutoWith(
        const ByteFormatOptions(standard: ByteStandard.iec, useBytes: true),
      );
      expect(text, equals('1 KiB'));
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
