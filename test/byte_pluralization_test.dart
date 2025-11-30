import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('BytePluralization', () {
    group('format()', () {
      test('singular for 1', () {
        expect(BytePluralization.format(1, 'byte'), equals('1 byte'));
        expect(BytePluralization.format(1, 'kilobyte'), equals('1 kilobyte'));
        expect(BytePluralization.format(1, 'megabyte'), equals('1 megabyte'));
      });

      test('plural for 0', () {
        expect(BytePluralization.format(0, 'byte'), equals('0 bytes'));
        expect(BytePluralization.format(0, 'kilobyte'), equals('0 kilobytes'));
      });

      test('plural for > 1', () {
        expect(BytePluralization.format(2, 'byte'), equals('2 bytes'));
        expect(
            BytePluralization.format(100, 'kilobyte'), equals('100 kilobytes'));
        expect(BytePluralization.format(1024, 'megabyte'),
            equals('1024 megabytes'));
      });

      test('plural for decimal values', () {
        expect(
            BytePluralization.format(1.5, 'megabyte'), equals('1.5 megabytes'));
        expect(
            BytePluralization.format(0.5, 'gigabyte'), equals('0.5 gigabytes'));
      });

      test('singular for 1.0 (exact)', () {
        expect(BytePluralization.format(1.0, 'byte'), equals('1 byte'));
      });

      test('custom plural form', () {
        expect(BytePluralization.format(2, 'byte', plural: 'octets'),
            equals('2 octets'));
        expect(BytePluralization.format(1, 'byte', plural: 'octets'),
            equals('1 byte'));
      });

      test('with comma separator', () {
        expect(
          BytePluralization.format(
            1536,
            'byte',
            options: const PluralizationOptions(useCommaSeparator: true),
          ),
          equals('1,536 bytes'),
        );
        expect(
          BytePluralization.format(
            1000000,
            'byte',
            options: const PluralizationOptions(useCommaSeparator: true),
          ),
          equals('1,000,000 bytes'),
        );
      });

      test('without value', () {
        expect(
          BytePluralization.format(
            2,
            'byte',
            options: const PluralizationOptions(includeValue: false),
          ),
          equals('bytes'),
        );
        expect(
          BytePluralization.format(
            1,
            'byte',
            options: const PluralizationOptions(includeValue: false),
          ),
          equals('byte'),
        );
      });
    });

    group('unitFor()', () {
      test('returns correct unit without value', () {
        expect(BytePluralization.unitFor(1, 'byte'), equals('byte'));
        expect(BytePluralization.unitFor(2, 'byte'), equals('bytes'));
        expect(BytePluralization.unitFor(0, 'kilobyte'), equals('kilobytes'));
      });
    });

    group('pluralize()', () {
      test('standard byte units', () {
        expect(BytePluralization.pluralize('byte'), equals('bytes'));
        expect(BytePluralization.pluralize('kilobyte'), equals('kilobytes'));
        expect(BytePluralization.pluralize('megabyte'), equals('megabytes'));
        expect(BytePluralization.pluralize('gigabyte'), equals('gigabytes'));
        expect(BytePluralization.pluralize('terabyte'), equals('terabytes'));
      });

      test('binary byte units', () {
        expect(BytePluralization.pluralize('kibibyte'), equals('kibibytes'));
        expect(BytePluralization.pluralize('mebibyte'), equals('mebibytes'));
        expect(BytePluralization.pluralize('gibibyte'), equals('gibibytes'));
        expect(BytePluralization.pluralize('tebibyte'), equals('tebibytes'));
      });

      test('bit units', () {
        expect(BytePluralization.pluralize('bit'), equals('bits'));
        expect(BytePluralization.pluralize('kilobit'), equals('kilobits'));
        expect(BytePluralization.pluralize('megabit'), equals('megabits'));
        expect(BytePluralization.pluralize('gigabit'), equals('gigabits'));
      });

      test('unknown words use standard rules', () {
        expect(BytePluralization.pluralize('file'), equals('files'));
        expect(BytePluralization.pluralize('match'), equals('matches'));
        expect(BytePluralization.pluralize('entry'), equals('entries'));
      });

      test('preserves case', () {
        expect(BytePluralization.pluralize('Byte'), equals('Bytes'));
        expect(BytePluralization.pluralize('BYTE'), equals('BYTES'));
        expect(BytePluralization.pluralize('Megabyte'), equals('Megabytes'));
      });
    });

    group('shouldUseSingular()', () {
      test('English rules', () {
        const options = PluralizationOptions(rule: PluralizationRule.english);
        expect(
            BytePluralization.shouldUseSingular(1, options: options), isTrue);
        expect(
            BytePluralization.shouldUseSingular(0, options: options), isFalse);
        expect(
            BytePluralization.shouldUseSingular(2, options: options), isFalse);
        expect(BytePluralization.shouldUseSingular(1.5, options: options),
            isFalse);
      });

      test('French rules (0 and 1 are singular)', () {
        const options = PluralizationOptions(rule: PluralizationRule.french);
        expect(
            BytePluralization.shouldUseSingular(1, options: options), isTrue);
        expect(
            BytePluralization.shouldUseSingular(0, options: options), isTrue);
        expect(
            BytePluralization.shouldUseSingular(2, options: options), isFalse);
      });

      test('East Asian rules (no plural)', () {
        const options = PluralizationOptions(rule: PluralizationRule.eastAsian);
        expect(
            BytePluralization.shouldUseSingular(1, options: options), isTrue);
        expect(
            BytePluralization.shouldUseSingular(0, options: options), isTrue);
        expect(
            BytePluralization.shouldUseSingular(100, options: options), isTrue);
      });

      test('Slavic rules', () {
        const options = PluralizationOptions(rule: PluralizationRule.slavic);
        expect(
            BytePluralization.shouldUseSingular(1, options: options), isTrue);
        expect(
            BytePluralization.shouldUseSingular(21, options: options), isTrue);
        expect(
            BytePluralization.shouldUseSingular(31, options: options), isTrue);
        expect(
            BytePluralization.shouldUseSingular(11, options: options), isFalse);
        expect(
            BytePluralization.shouldUseSingular(12, options: options), isFalse);
        expect(
            BytePluralization.shouldUseSingular(2, options: options), isFalse);
        expect(
            BytePluralization.shouldUseSingular(5, options: options), isFalse);
      });
    });

    group('ruleForLocale()', () {
      test('English locales', () {
        expect(BytePluralization.ruleForLocale('en'),
            equals(PluralizationRule.english));
        expect(BytePluralization.ruleForLocale('en_US'),
            equals(PluralizationRule.english));
        expect(BytePluralization.ruleForLocale('en-GB'),
            equals(PluralizationRule.english));
      });

      test('French locales', () {
        expect(BytePluralization.ruleForLocale('fr'),
            equals(PluralizationRule.french));
        expect(BytePluralization.ruleForLocale('fr_FR'),
            equals(PluralizationRule.french));
      });

      test('East Asian locales', () {
        expect(BytePluralization.ruleForLocale('ja'),
            equals(PluralizationRule.eastAsian));
        expect(BytePluralization.ruleForLocale('zh'),
            equals(PluralizationRule.eastAsian));
        expect(BytePluralization.ruleForLocale('ko'),
            equals(PluralizationRule.eastAsian));
      });

      test('Slavic locales', () {
        expect(BytePluralization.ruleForLocale('ru'),
            equals(PluralizationRule.slavic));
        expect(BytePluralization.ruleForLocale('pl'),
            equals(PluralizationRule.slavic));
        expect(BytePluralization.ruleForLocale('uk'),
            equals(PluralizationRule.slavic));
      });

      test('Arabic locales', () {
        expect(BytePluralization.ruleForLocale('ar'),
            equals(PluralizationRule.arabic));
        expect(BytePluralization.ruleForLocale('he'),
            equals(PluralizationRule.arabic));
      });
    });

    group('optionsForLocale()', () {
      test('creates correct options', () {
        final frOptions = BytePluralization.optionsForLocale('fr');
        expect(frOptions.rule, equals(PluralizationRule.french));
        expect(frOptions.locale, equals('fr'));

        final jaOptions = BytePluralization.optionsForLocale('ja');
        expect(jaOptions.rule, equals(PluralizationRule.eastAsian));
        expect(jaOptions.locale, equals('ja'));
      });
    });
  });

  group('IntPluralizationExtension', () {
    test('withUnit()', () {
      expect(1.withUnit('byte'), equals('1 byte'));
      expect(2.withUnit('byte'), equals('2 bytes'));
      expect(0.withUnit('kilobyte'), equals('0 kilobytes'));
    });

    test('withUnit() with commas', () {
      expect(1536.withUnit('byte', useCommas: true), equals('1,536 bytes'));
    });
  });

  group('DoublePluralizationExtension', () {
    test('withUnit()', () {
      expect(1.0.withUnit('megabyte'), equals('1 megabyte'));
      expect(1.5.withUnit('megabyte'), equals('1.5 megabytes'));
      expect(2.75.withUnit('gigabyte'), equals('2.75 gigabytes'));
    });

    test('withUnit() precision', () {
      expect(
          1.12345.withUnit('megabyte', precision: 2), equals('1.12 megabytes'));
      expect(1.1.withUnit('megabyte', precision: 4), equals('1.1 megabytes'));
    });
  });
}
