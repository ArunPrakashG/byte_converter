import 'dart:math' as math;

import 'package:byte_converter/byte_converter.dart';
import 'package:byte_converter/byte_converter_intl.dart' as byte_converter_intl;
import 'package:byte_converter/src/humanize_options.dart' show SiKSymbolCase;
import 'package:test/test.dart';

void main() {
  setUpAll(byte_converter_intl.enableByteConverterIntl);

  tearDownAll(byte_converter_intl.disableByteConverterIntl);

  group('Advanced formatting and parsing (new features)', () {
    test('Pattern formatting with u/U and lower-k style', () {
      final c = ByteConverter(1500); // ~1.5 kB
      final t1 = c.formatWith('0.0 u', options: const ByteFormatOptions());
      expect(t1, anyOf('1.5 KB', '1.5 kB'));
      final t2 =
          c.formatWith('0 U', options: const ByteFormatOptions(fullForm: true));
      // fullForm via pattern uses localized words; fallback en
      expect(t2.contains('byte'), isTrue);
      final t3 = c.formatWith('0 u',
          options: ByteFormatOptions(siKSymbolCase: SiKSymbolCase.lowerK));
      expect(t3.endsWith(' kB'), isTrue);
    });

    test('Full words convenience', () {
      final c = ByteConverter(1024);
      final text = c.toFullWords();
      expect(text.toLowerCase().contains('byte'), isTrue);
    });

    test('Largest whole number helper', () {
      final c = ByteConverter(1536);
      final lw = c.largestWholeNumber();
      expect(lw.value, equals(1));
      expect(lw.symbol, anyOf('KB', 'kB'));
    });
    test('Truncate vs rounding with min/max digits', () {
      final c = ByteConverter(1550); // 1.55 KB (SI)
      final rounded = c.toHumanReadableAuto(
        minimumFractionDigits: 1,
        maximumFractionDigits: 1,
      );
      // 1.55 -> rounded to 1.6
      expect(rounded, equals('1.6 KB'));

      final truncated = c.toHumanReadableAuto(
        minimumFractionDigits: 1,
        maximumFractionDigits: 1,
        truncate: true,
      );
      // 1.55 -> truncated to 1.5
      expect(truncated, equals('1.5 KB'));
    });

    test('Non-breaking space spacer', () {
      final c = ByteConverter(2048); // ~2.05 KB
      final text = c.toHumanReadableAuto(nonBreakingSpace: true);
      // Ensure NBSP present between number and unit
      expect(text.contains('\u00A0'), isTrue);
      // And absence of regular space at that boundary
      expect(text.contains(' KB'), isFalse);
    });

    test('Strict bits parsing rejects fractional bits', () {
      final r1 = ByteConverter.tryParse('1.5 Mb', strictBits: true);
      expect(r1.isSuccess, isFalse);
      final r2 = ByteConverter.tryParse('2 Mb', strictBits: true);
      expect(r2.isSuccess, isTrue);
    });
    test('ByteConverter: useBits + forceUnit (SI bits)', () {
      final c = ByteConverter(1000000); // 1,000,000 bytes -> 8,000,000 bits
      final text = c.toHumanReadableAuto(
        useBits: true,
        minimumFractionDigits: 1,
        maximumFractionDigits: 1,
        separator: ',',
        spacer: '',
        signed: true,
        forceUnit: 'Mb',
      );
      expect(text, equals('+8,0Mb'));
    });

    test('fullForm with custom fullForms for bits', () {
      final c = ByteConverter(2000); // 16,000 bits
      final text = c.toHumanReadableAutoWith(
        const ByteFormatOptions(
          fullForm: true,
          fullForms: {'kilobits': 'kilobités'},
          forceUnit: 'kb',
          spacer: ' ',
        ),
      );
      expect(text, equals('16 kilobités'));
    });

    test('Locale: decimal comma with forced unit', () {
      final c = ByteConverter(1920); // 1.92 KB
      final text = c.toHumanReadableAuto(
        separator: ',',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
        forceUnit: 'KB',
        spacer: ' ',
      );
      expect(text, equals('1,92 KB'));
    });

    test('ByteConverter: full-form IEC bits parsing', () {
      // 8 kibibits = 8 * 1024 bits = 1024 bytes
      final c = ByteConverter.parse('8 kibibits', standard: ByteStandard.iec);
      expect(c.asBytes(), equals(1024));
    });

    test('BigByteConverter: parse SI bits (full-form)', () {
      // 10 megabits = 1,250,000 bytes
      final c = BigByteConverter.parse('10 megabits');
      expect(c.asBytes, equals(BigInt.from(1250000)));
    });

    test('Precision vs min/max fraction digits', () {
      final c = ByteConverter(1500); // 1.5 KB (SI)
      final onlyPrecision = c.toHumanReadableAuto(precision: 3);
      expect(onlyPrecision, equals('1.5 KB')); // trimmed trailing zeros

      final fixedTwo = c.toHumanReadableAuto(
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      );
      expect(fixedTwo, equals('1.50 KB'));
    });

    test('Spacer overrides showSpace', () {
      final c = ByteConverter(1024); // ~1.02 KB (SI)
      final text = c.toHumanReadableAuto(spacer: '_');
      expect(text, equals('1.02_KB'));
    });

    test('Signed zero formatting for sizes and rates', () {
      final s = ByteConverter(0).toHumanReadableAuto(signed: true);
      expect(s, equals(' 0 B'));

      final r =
          const DataRate.bitsPerSecond(0).toHumanReadableAuto(signed: true);
      expect(r, equals(' 0 b/s'));
    });

    test('ByteConverter: JEDEC forced unit', () {
      final c = ByteConverter(1024 * 1024); // 1 MiB
      final text = c.toHumanReadableAuto(
        standard: ByteStandard.jedec,
        forceUnit: 'KB',
      );
      expect(text, equals('1024 KB'));
    });

    test('ByteConverter: useBits with forced byte unit maps to bit unit', () {
      final c = ByteConverter(1000); // 8000 bits
      final text = c.toHumanReadableAuto(
        useBits: true,
        forceUnit: 'KB', // maps to 'kb' for bits
        spacer: '',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      );
      expect(text, equals('8Kb'));
    });

    test('DataRate: force MB with bytes', () {
      final r = DataRate.megaBytesPerSecond(1.5);
      final text = r.toHumanReadableAuto(
        useBytes: true,
        forceUnit: 'MB',
        spacer: '',
        minimumFractionDigits: 1,
        maximumFractionDigits: 1,
      );
      expect(text, equals('1.5MB/s'));
    });

    test('DataRate: IEC forced bytes maps to bits when useBits', () {
      final r = DataRate.kibiBitsPerSecond(2); // 2 * 1024 = 2048 bps
      final text = r.toHumanReadableAuto(
        standard: ByteStandard.iec,
        spacer: '',
        forceUnit: 'KiB', // should render as Kib
      );
      expect(text, equals('2Kib/s'));
    });

    test('DataRate: extended IEC units (ZiB/s, YiB/s)', () {
      final zi = DataRate.parse('1 ZiB/s', standard: ByteStandard.iec);
      final yi = DataRate.parse('1 YiB/s', standard: ByteStandard.iec);
      final expectedZi = (math.pow(1024.0, 7) as double) * 8;
      final expectedYi = (math.pow(1024.0, 8) as double) * 8;
      expect(zi.bitsPerSecond, closeTo(expectedZi, 1e-3));
      expect(yi.bitsPerSecond, closeTo(expectedYi, 1e-3));
    });

    test('Locale-aware formatting applies decimal and grouping separators', () {
      final c = ByteConverter(123456789); // ~123.456789 MB
      final text = c.toHumanReadableAuto(
        locale: 'de_DE',
        forceUnit: 'MB',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      );
      expect(text, equals('123,46 MB'));
    });

    test('Locale-aware formatting honors grouping toggle', () {
      final c = ByteConverter(9876543210);
      final grouped = c.toHumanReadableAuto(
        locale: 'en_US',
        forceUnit: 'B',
      );
      final ungrouped = c.toHumanReadableAuto(
        locale: 'en_US',
        forceUnit: 'B',
        useGrouping: false,
      );
      expect(grouped, equals('9,876,543,210 B'));
      expect(ungrouped, equals('9876543210 B'));
    });

    test('Unknown locale falls back to default separators', () {
      final c = ByteConverter(1500);
      final text = c.toHumanReadableAuto(
        locale: 'xx_YY',
        minimumFractionDigits: 1,
        maximumFractionDigits: 1,
      );
      expect(text, equals('1.5 KB'));
    });

    test('Locale full-form names use built-in translations', () {
      final c = ByteConverter(2000);
      final text = c.toHumanReadableAuto(
        locale: 'fr_FR',
        fullForm: true,
        forceUnit: 'KB',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      );
      expect(text, equals('2 kilooctets'));
    });

    test('Custom localized unit names override defaults', () {
      registerLocalizedUnitNames('es', {
        'KB': 'kilobytes-es',
        'kb': 'kilobits-es',
      });

      final size = ByteConverter(1024);
      final text = size.toHumanReadableAuto(
        locale: 'es_ES',
        fullForm: true,
        forceUnit: 'KB',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      );
      expect(text, equals('1 kilobytes-es'));

      final bits = ByteConverter(1024).toHumanReadableAuto(
        locale: 'es_ES',
        fullForm: true,
        useBits: true,
        forceUnit: 'kb',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      );
      expect(bits, equals('8 kilobits-es'));

      clearLocalizedUnitNames('es');
    });

    test('Big SI: Ronna/Quetta formatting (auto + forceUnit)', () {
      final rBytes = BigInt.from(10).pow(27);
      final qBytes = BigInt.from(10).pow(30);
      final r = BigByteConverter(rBytes);
      final q = BigByteConverter(qBytes);

      // Auto should choose RB/QB in SI
      final rAuto = r.toHumanReadableAuto(standard: ByteStandard.si);
      final qAuto = q.toHumanReadableAuto(standard: ByteStandard.si);
      expect(rAuto.endsWith(' RB'), isTrue);
      expect(qAuto.endsWith(' QB'), isTrue);

      // Force specific unit
      final rForced = r.toHumanReadableAuto(
        standard: ByteStandard.si,
        forceUnit: 'RB',
        spacer: ' ',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      );
      final qForced = q.toHumanReadableAuto(
        standard: ByteStandard.si,
        forceUnit: 'QB',
        spacer: ' ',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      );
      expect(rForced, equals('1 RB'));
      expect(qForced, equals('1 QB'));
    });

    test('Big parse: RB/QB recognized (SI)', () {
      final r = BigByteConverter.parse('1 RB');
      final q = BigByteConverter.parse('1 QB');
      expect(r.asBytes, equals(BigInt.from(10).pow(27)));
      expect(q.asBytes, equals(BigInt.from(10).pow(30)));
    });

    test('DataRate: RB/QB per second formatting and parsing', () {
      final r = DataRate.parse('1 RB/s');
      final q = DataRate.parse('1 QBps');
      final rText = r.toHumanReadableAuto(
        useBytes: true,
        forceUnit: 'RB',
        spacer: ' ',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      );
      final qText = q.toHumanReadableAuto(
        useBytes: true,
        forceUnit: 'QB',
        spacer: ' ',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      );
      expect(rText, equals('1 RB/s'));
      expect(qText, equals('1 QB/s'));

      // Bits forced unit mapping
      final rBits = r.toHumanReadableAuto(
        useBytes: false,
        forceUnit: 'Rb',
        spacer: ' ',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      );
      expect(rBits, equals('8 Rb/s'));
    });

    test('Full-form names for RB/QB (en)', () {
      final r = BigByteConverter(BigInt.from(10).pow(27));
      final q = BigByteConverter(BigInt.from(10).pow(30));
      final rText = r.toHumanReadableAuto(
        fullForm: true,
        forceUnit: 'RB',
        spacer: ' ',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      );
      final qText = q.toHumanReadableAuto(
        fullForm: true,
        forceUnit: 'QB',
        spacer: ' ',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      );
      expect(rText, equals('1 ronnabytes'));
      expect(qText, equals('1 quettabytes'));
    });
  });
}
