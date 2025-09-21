import 'dart:math' as math;

import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('Advanced formatting and parsing (new features)', () {
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
  });
}
