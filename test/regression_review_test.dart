import 'dart:convert';

import 'package:byte_converter/byte_converter_full.dart';
import 'package:test/test.dart';

void main() {
  group('unit promotion after rounding', () {
    test('SI auto never prints the unit ratio', () {
      expect(ByteConverter(999999).display.auto(), '1 MB');
      expect(ByteConverter(999999).toString(), '1 MB');
      expect(ByteConverter(999999999).display.auto(), '1 GB');
      expect(ByteConverter(999999999999999).display.auto(), '1 PB');
      expect(ByteConverter(999000).display.auto(), '999 KB');
    });

    test('IEC auto scales beyond TiB and promotes', () {
      expect(
        ByteConverter.fromPebiBytes(1).display.auto(standard: ByteStandard.iec),
        '1 PiB',
      );
      expect(
        ByteConverter(1048575).display.auto(standard: ByteStandard.iec),
        '1 MiB',
      );
      expect(
        BigByteConverter(BigInt.two.pow(80))
            .display
            .auto(standard: ByteStandard.iec),
        '1 YiB',
      );
    });

    test('bits promote too', () {
      expect(ByteConverter(124999).display.auto(useBits: true), '999.99 Kb');
      expect(ByteConverter(125000).display.auto(useBits: true), '1 Mb');
    });

    test('fast and general paths agree', () {
      for (final bytes in [
        0.0,
        1,
        999,
        1000,
        1023,
        1024,
        999999,
        1e6,
        1048575,
        1048576,
        999999999,
        1e9,
        1e12 - 1,
        1e12,
        1e15 - 1,
        1e15,
        1e18,
        1e21,
      ]) {
        for (final std in ByteStandard.values) {
          final fast =
              ByteConverter(bytes.toDouble()).display.auto(standard: std);
          // A non-default option disables the fast paths but changes nothing.
          final general = ByteConverter(bytes.toDouble())
              .display
              .auto(standard: std, showSpace: true, spacer: ' ');
          expect(fast, general, reason: '$bytes $std');
        }
      }
    });
  });

  group('ByteConverter robustness', () {
    test('fromJson accepts int, double and numeric strings', () {
      expect(
          ByteConverter.fromJson(
                  jsonDecode('{"bytes": 1024}') as Map<String, dynamic>)
              .bytes,
          1024);
      expect(ByteConverter.fromJson({'bytes': 1.5}).bytes, 1.5);
      expect(ByteConverter.fromJson({'bytes': '2048'}).bytes, 2048);
      expect(
          () => ByteConverter.fromJson({'bytes': null}), throwsFormatException);
    });

    test('very large values compare correctly', () {
      expect(ByteConverter(1e19) == ByteConverter(2e19), isFalse);
      expect(ByteConverter(1e19) < ByteConverter(2e19), isTrue);
      expect(ByteConverter(2e19) > ByteConverter(1e19), isTrue);
      expect(ByteConverter(1e19).hashCode, ByteConverter(1e19).hashCode);
    });

    test('NaN and infinity throw ArgumentError', () {
      expect(() => ByteConverter(double.nan), throwsArgumentError);
      expect(() => ByteConverter(double.infinity), throwsArgumentError);
    });

    test('toString scales beyond PB', () {
      expect(ByteConverter(1e18).toString(), '1 EB');
    });
  });

  group('parsing', () {
    test('IEC kibibytes parse under the default standard', () {
      expect(ByteConverter.parse('1 KiB').bytes, 1024);
      expect(ByteConverter.parse('1 kibibyte').bytes, 1024);
    });

    test('English thousands grouping', () {
      expect(ByteConverter.parse('1,234 bytes').bytes, 1234);
      expect(ByteConverter.parse('1,234,567 B').bytes, 1234567);
      expect(ByteConverter.parse('1.234.567 B').bytes, 1234567);
      expect(ByteConverter.parse('1,5 GB').bytes, 1.5e9);
      expect(ByteConverter.parse('1.234 GB').bytes, 1.234e9);
    });

    test('short bit forms', () {
      expect(ByteConverter.parse('10 Mbit').bytes, 1250000);
      expect(ByteConverter.parse('8 kbits').bytes, 1000);
    });
  });

  group('full-form names', () {
    test('singular in English', () {
      expect(ByteConverter(1).display.auto(fullForm: true), '1 byte');
      expect(ByteConverter(1000).display.auto(fullForm: true), '1 kilobyte');
      expect(ByteConverter(2000).display.auto(fullForm: true), '2 kilobytes');
    });
  });

  test('SiKSymbolCase is exported from the core import', () {
    expect(SiKSymbolCase.lowerK, isNotNull);
  });
}
