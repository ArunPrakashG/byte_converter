import 'package:byte_converter/byte_converter_full.dart';
import 'package:test/test.dart';

void main() {
  group('Tree-shakable locales', () {
    tearDown(() {
      // Ensure defaults re-enabled and custom maps cleared between tests
      enableDefaultLocalizedUnitNames();
      clearLocalizedUnitNames('xx');
      clearLocalizedSynonyms('xx');
      clearLocalizedSingularNames('xx');
    });

    test('disable defaults removes built-in names', () {
      // English default exists for KB
      expect(localizedUnitName('KB', locale: 'en'), isNotNull);
      disableDefaultLocalizedUnitNames();
      expect(localizedUnitName('KB', locale: 'en'), isNull);
      enableDefaultLocalizedUnitNames();
      expect(localizedUnitName('KB', locale: 'en'), isNotNull);
    });

    test('custom registration works without defaults', () {
      disableDefaultLocalizedUnitNames();
      registerLocalizedUnitNames('xx', {'KB': 'kilox'});
      expect(localizedUnitName('KB', locale: 'xx'), 'kilox');
      // reverse resolution uses custom names
      expect(resolveLocalizedUnitSymbol('kilox', locale: 'xx'), 'KB');
    });

    test('synonyms map back to symbols', () {
      disableDefaultLocalizedUnitNames();
      registerLocalizedUnitNames('xx', {'KB': 'kilox', 'B': 'bytex'});
      registerLocalizedSynonyms('xx', {
        'xk': 'KB',
        'byte': 'B',
      });
      expect(resolveLocalizedUnitSymbol('xk', locale: 'xx'), 'KB');
      expect(resolveLocalizedUnitSymbol('BYTE', locale: 'xx'), 'B');
    });

    test('parseLocalized respects reverse mapping', () {
      disableDefaultLocalizedUnitNames();
      registerLocalizedUnitNames('xx', {'KB': 'kilox'});
      // Use a locale-specific word
      final r = parseLocalized('1,5 kilox', locale: 'xx');
      // number normalization: comma as decimal -> 1.5
      expect(r.isSuccess, isTrue);
      expect(r.value!.toHumanReadableAuto(forceUnit: 'KB'), '1.5 KB');
    });

    test('locale fallback fr-FR -> fr', () {
      enableDefaultLocalizedUnitNames();
      // French default contains 'kilooctets' for KB
      final r = parseLocalized('1,5 kilooctets', locale: 'fr-FR');
      expect(r.isSuccess, isTrue);
      expect(r.value!.toHumanReadableAuto(forceUnit: 'KB'), '1.5 KB');
    });
  });
}
