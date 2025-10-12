import 'package:byte_converter/byte_converter_lite.dart';
import 'package:test/test.dart';

void main() {
  group('Lite number formatter adapter', () {
    tearDown(() {
      // Make sure we clean up any registered formatter across tests
      disableByteConverterLite();
    });

    test('falls back to default when locale is empty', () {
      // Not enabling; humanize should use plain dot decimal without grouping
      final c = ByteConverter(12345.678);
      final s = c.toHumanReadableAuto(
        standard: ByteStandard.si,
        // No locale, ensure default ASCII output
      );
      expect(s, contains('12.35 '));
    });

    test('en dot decimal and grouping with B', () {
      enableByteConverterLite();
      final c = ByteConverter(12345678);
      final s = c.toHumanReadableAuto(
        standard: ByteStandard.si,
        locale: 'en',
        precision: 2,
        useGrouping: true,
      );
      // ~12.35 MB -> decimal uses dot; integer part is < 1000 so no grouping
      expect(s, contains('.'));
      // Now force bytes to see grouping on large integer
      final s2 = c.toHumanReadableAuto(
        standard: ByteStandard.si,
        locale: 'en',
        forceUnit: 'B',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
        useGrouping: true,
      );
      expect(s2, contains(','));
    });

    test('de comma decimal and dot grouping with B', () {
      enableByteConverterLite();
      final c = ByteConverter(12345678);
      final s = c.toHumanReadableAuto(
        standard: ByteStandard.si,
        locale: 'de-DE',
        precision: 2,
        useGrouping: true,
      );
      // ~12,35 MB uses comma decimal
      expect(s, contains(','));
      // Force bytes to check dot grouping
      final s2 = c.toHumanReadableAuto(
        standard: ByteStandard.si,
        locale: 'de-DE',
        forceUnit: 'B',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
        useGrouping: true,
      );
      expect(s2, contains('.'));
    });

    test('fr comma decimal and space grouping with B', () {
      enableByteConverterLite();
      final c = ByteConverter(987654321);
      final s = c.toHumanReadableAuto(
        standard: ByteStandard.si,
        locale: 'fr',
        precision: 2,
        useGrouping: true,
      );
      // ~987,65 MB (comma as decimal)
      expect(s.contains(','), isTrue);
      // Force bytes to check space grouping in the integer portion
      final s2 = c.toHumanReadableAuto(
        standard: ByteStandard.si,
        locale: 'fr',
        forceUnit: 'B',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
        useGrouping: true,
      );
      // Number part should include spaces as thousand separators; total splits > 2 (includes unit)
      expect(s2.split(' ').length > 2, isTrue);
    });

    test('respects min/max fraction digits', () {
      enableByteConverterLite();
      final c = ByteConverter(1500); // ~1.5 KB
      final s = c.toHumanReadableAuto(
        standard: ByteStandard.si,
        locale: 'en',
        minimumFractionDigits: 3,
        maximumFractionDigits: 3,
      );
      expect(s, contains('1.500'));
    });

    test('useGrouping=false disables thousands separators', () {
      enableByteConverterLite();
      final c = ByteConverter(12345678);
      final s = c.toHumanReadableAuto(
        standard: ByteStandard.si,
        locale: 'en',
        precision: 2,
        useGrouping: false,
      );
      // No commas
      expect(s.contains(','), isFalse);
    });
  });
}
