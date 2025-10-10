import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  const tolerance = 1e-6;

  group('Number normalization and trimming', () {
    test('parses locale-formatted number with comma decimal', () {
      final value = ByteConverter.parse('1.234.567,89 KB');
      expect(value.bytes, closeTo(1234567.89 * 1000, 1e-3));
    });

    test('parses locale-formatted number with dot decimal', () {
      final value = ByteConverter.parse('1,234,567.89 KB');
      expect(value.bytes, closeTo(1234567.89 * 1000, 1e-3));
    });

    test('parses numbers containing underscores and nbps', () {
      final value = ByteConverter.parse('\u00A01_024.5 MB');
      expect(value.bytes, closeTo(1024.5 * 1000 * 1000, tolerance));
    });

    test('normalized input collapses whitespace', () {
      final result = ByteConverter.tryParse('  \u00A0 1\t MB  ');
      expect(result.isSuccess, isTrue);
      expect(result.value?.bytes, closeTo(1000 * 1000, tolerance));
      expect(result.normalizedInput, '1 MB');
    });
  });

  group('Size literal parsing', () {
    test('word synonyms resolve to byte symbols', () {
      final value = ByteConverter.parse('1 kilobyte');
      expect(value.bytes, closeTo(1000, tolerance));
    });

    test('bit inputs convert to bytes correctly', () {
      final value = ByteConverter.parse('8 bit');
      expect(value.bytes, closeTo(1, tolerance));
    });

    test('explicit IEC bit units normalize detected unit', () {
      final result = ByteConverter.tryParse('1 kibibit');
      expect(result.isSuccess, isTrue);
      expect(result.detectedUnit, 'Kib');
      expect(result.value?.bytes, closeTo(128, tolerance));
      expect(result.normalizedInput, '1 Kib');
    });

    test('no unit defaults to bytes and preserves normalized input', () {
      final result = ByteConverter.tryParse('42');
      expect(result.isSuccess, isTrue);
      expect(result.value?.bytes, closeTo(42, tolerance));
      expect(result.detectedUnit, 'B');
      expect(result.normalizedInput, '42');
    });

    test('unknown units surface parse failure', () {
      final result = ByteConverter.tryParse('1 qux');
      expect(result.isSuccess, isFalse);
      expect(result.error?.message, contains('Unknown'));
    });

    test('negative sizes are rejected via tryParse', () {
      final result = ByteConverter.tryParse('-1 MB');
      expect(result.isSuccess, isFalse);
      expect(result.error?.message, contains('Bytes cannot be negative'));
    });

    test('JEDEC symbols parse when requested', () {
      final value = ByteConverter.parse('2 GB', standard: ByteStandard.jedec);
      expect(value.bytes, closeTo(2 * 1024 * 1024 * 1024, tolerance));
    });
  });

  group('Big size parsing', () {
    test('IEC units fallback under SI standard', () {
      final big = BigByteConverter.parse('1 ZiB', standard: ByteStandard.si);
      expect(big.asBytes, BigInt.parse('1180591620717411303424'));
    });

    test('bit literals map to integer bytes', () {
      final result = BigByteConverter.tryParse('1024 kibit');
      expect(result.isSuccess, isTrue);
      expect(result.value?.asBytes, BigInt.from(1024 * 128));
    });

    test('negative big sizes rejected', () {
      final result = BigByteConverter.tryParse('-1 GiB');
      expect(result.isSuccess, isFalse);
      expect(result.error?.message, contains('Bytes cannot be negative'));
    });
  });

  group('Rate literal parsing', () {
    test('parses SI bit rates', () {
      final rate = DataRate.parse('100 Mbps');
      expect(rate.bitsPerSecond, closeTo(100 * 1000 * 1000, tolerance));
      final normalized = DataRate.tryParse('100 mbps');
      expect(normalized.isSuccess, isTrue);
      expect(normalized.normalizedInput, '100 Mb/s');
    });

    test('parses SI byte rates', () {
      final rate = DataRate.parse('125 MB/s');
      expect(rate.bytesPerSecond, closeTo(125 * 1000 * 1000, tolerance));
    });

    test('parses IEC rates and falls back across standards', () {
      final rate = DataRate.parse('1 MiB/s', standard: ByteStandard.si);
      expect(rate.bytesPerSecond, closeTo(1024 * 1024, tolerance));
    });

    test('parses kibps bit rate', () {
      final rate = DataRate.parse('1 kibps');
      expect(rate.bitsPerSecond, closeTo(1024, tolerance));
    });

    test('negative rates are rejected', () {
      final result = DataRate.tryParse('-5 MB/s');
      expect(result.isSuccess, isFalse);
      expect(result.error?.message, contains('Rate cannot be negative'));
    });

    test('unknown rates surface failure', () {
      final result = DataRate.tryParse('10 glorp/s');
      expect(result.isSuccess, isFalse);
      expect(result.error?.message, contains('Unknown rate unit'));
    });
  });

  group('Expression parsing', () {
    test('handles unary minus and grouping', () {
      final value = ByteConverter.parse('-(1 MB) + 2 MB');
      expect(value.bytes, closeTo(1 * 1000 * 1000, tolerance));
    });

    test('supports mixed SI and IEC units with arithmetic', () {
      final value = ByteConverter.parse('2 * (1 MB + 2 MiB) - 512 KB');
      expect(value.bytes, closeTo(5682304, 1));
    });

    test('division by zero inside expression fails gracefully', () {
      final result = ByteConverter.tryParse('1 GB / 0');
      expect(result.isSuccess, isFalse);
      expect(result.error?.message, contains('Division by zero'));
    });

    test('rate expression combines size, duration, and literal rates', () {
      final rate = DataRate.parse('1 GB / 5s + 100 MB/s');
      expect(rate.bitsPerSecond, closeTo(2.4e9, 1e-3));
    });

    test('rate expression handles duration multiplication', () {
      final rate = DataRate.parse('1 GB / (2 * 5s)');
      expect(rate.bitsPerSecond, closeTo(0.8e9, 1e-3));
    });

    test('rate expression with scalar multiplication', () {
      final rate = DataRate.parse('100 MB/s * 2');
      expect(rate.bitsPerSecond, closeTo(1.6e9, 1e-3));
    });

    test('rate division by zero via duration fails', () {
      final result = DataRate.tryParse('1 GB / (5s - 5s)');
      expect(result.isSuccess, isFalse);
      expect(result.error?.message, contains('Division by zero'));
    });
  });

  group('Duration literal coverage', () {
    test('supports microsecond symbol', () {
      final rate = DataRate.parse('1 KB / 250 µs');
      expect(rate.bytesPerSecond, closeTo(4096000, tolerance));
    });

    test('supports minute shorthand', () {
      final rate = DataRate.parse('1 GB / 2 min');
      expect(rate.bitsPerSecond, closeTo((1e9 / 120) * 8, 1e-3));
    });

    test('unknown duration units throw', () {
      final result = DataRate.tryParse('1 GB / 1 fortnight');
      expect(result.isSuccess, isFalse);
      expect(result.error?.message, contains('Unknown duration unit'));
    });
  });

  group('Tokenizer and syntax errors', () {
    test('missing operand throws during parsing', () {
      expect(() => ByteConverter.parse('1 MB + '), throwsFormatException);
    });

    test('unbalanced parenthesis throws', () {
      expect(() => ByteConverter.parse('(1 MB + 2 MB'), throwsFormatException);
    });
  });
}
