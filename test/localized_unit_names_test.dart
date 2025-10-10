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

    test('custom overrides can be cleared to restore defaults', () {
      registerLocalizedUnitNames('es', {
        'KB': 'kilobytes-es',
      });

      final overridden = localizedUnitName('KB', locale: 'es_ES');
      expect(overridden, equals('kilobytes-es'));

      clearLocalizedUnitNames('es');
      final cleared = localizedUnitName('KB', locale: 'es_ES');
      expect(cleared, isNull);
    });
  });

  group('localizedUnitNameMapForDefaultLocale', () {
    test('is unmodifiable', () {
      final defaults = localizedUnitNameMapForDefaultLocale();
      expect(() => defaults['KB'] = 'change', throwsUnsupportedError);
    });
  });
}
