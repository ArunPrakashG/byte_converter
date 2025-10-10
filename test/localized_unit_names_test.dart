import 'package:byte_converter/src/localized_unit_names.dart';
import 'package:test/test.dart';

void main() {
  group('localizedUnitName', () {
    tearDown(() {
      clearLocalizedUnitNames('es');
    });

    test('falls back to base locale when region is provided', () {
      final name = localizedUnitName('KB', locale: 'fr-CA');
      expect(name, equals('kilooctets'));
    });

    test('uses English defaults for en_IN', () {
      final name = localizedUnitName('KB', locale: 'en_IN');
      expect(name, equals('kilobytes'));
    });

    test('provides Hindi localized names for India region', () {
      final name = localizedUnitName('MB', locale: 'hi_IN');
      expect(name, equals('मेगाबाइट्स'));
    });

    test('provides Spanish localized names for Mexico region', () {
      final name = localizedUnitName('GB', locale: 'es-MX');
      expect(name, equals('gigabytes'));
    });

    test('provides Portuguese localized names for Brazil region', () {
      final name = localizedUnitName('KB', locale: 'pt-BR');
      expect(name, equals('quilobytes'));
    });

    test('provides Japanese localized names', () {
      final name = localizedUnitName('GiB', locale: 'ja_JP');
      expect(name, equals('ギビバイト'));
    });

    test('provides Chinese localized names', () {
      final name = localizedUnitName('YiB', locale: 'zh_CN');
      expect(name, equals('尧二进制字节'));
    });

    test('provides Russian localized names', () {
      final name = localizedUnitName('MB', locale: 'ru');
      expect(name, equals('мегабайты'));
    });

    test('custom overrides can be cleared to restore defaults', () {
      registerLocalizedUnitNames('es', {
        'KB': 'kilobytes-es',
      });

      final overridden = localizedUnitName('KB', locale: 'es_ES');
      expect(overridden, equals('kilobytes-es'));

      clearLocalizedUnitNames('es');
      final cleared = localizedUnitName('KB', locale: 'es_ES');
      expect(cleared, equals('kilobytes'));
    });
  });

  group('localizedUnitNameMapForDefaultLocale', () {
    test('is unmodifiable', () {
      final defaults = localizedUnitNameMapForDefaultLocale();
      expect(() => defaults['KB'] = 'change', throwsUnsupportedError);
    });
  });
}
