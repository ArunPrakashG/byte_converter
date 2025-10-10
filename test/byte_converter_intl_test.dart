import 'package:byte_converter/byte_converter_intl.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

void main() {
  setUp(disableByteConverterIntl);

  tearDown(disableByteConverterIntl);

  test('enable/disable toggles locale-aware number formatting', () {
    final converter = ByteConverter(1500);

    final fallback = converter.toHumanReadableAuto(
      locale: 'de_DE',
      minimumFractionDigits: 1,
      maximumFractionDigits: 1,
    );
    expect(fallback, equals('1.5 KB'));

    enableByteConverterIntl();
    final localized = converter.toHumanReadableAuto(
      locale: 'de_DE',
      minimumFractionDigits: 1,
      maximumFractionDigits: 1,
    );
    expect(localized, equals('1,5 KB'));

    disableByteConverterIntl();
    final restored = converter.toHumanReadableAuto(
      locale: 'de_DE',
      minimumFractionDigits: 1,
      maximumFractionDigits: 1,
    );
    expect(restored, equals('1.5 KB'));
  });

  test('formatter factory instances are cached per locale and options', () {
    var factoryCalls = 0;
    enableByteConverterIntl(
      numberFormatFactory: (locale) {
        factoryCalls++;
        return NumberFormat.decimalPattern(locale);
      },
    );

    final converter = ByteConverter(1234567);

    final first = converter.toHumanReadableAuto(
      locale: 'en_US',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    );
    final second = converter.toHumanReadableAuto(
      locale: 'en_US',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    );

    expect(first, equals(second));
    expect(factoryCalls, equals(1));
  });
}
