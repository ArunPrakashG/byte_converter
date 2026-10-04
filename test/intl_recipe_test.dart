// Verifies the documented recipe for plugging package:intl into humanized
// output via [registerHumanizeNumberFormatter]. byte_converter itself has no
// dependency on intl; apps that want it add their own.
import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

import 'support/intl_formatter.dart';

void main() {
  tearDown(clearHumanizeNumberFormatter);

  test('registering an intl-backed formatter localizes numbers', () {
    final size = ByteConverter(1500);
    String fmt() => size.display.auto(
          locale: 'de_DE',
          minimumFractionDigits: 1,
          maximumFractionDigits: 1,
        );

    expect(fmt(), '1.5 KB');
    registerHumanizeNumberFormatter(intlHumanizeFormatter);
    expect(fmt(), '1,5 KB');
    clearHumanizeNumberFormatter();
    expect(fmt(), '1.5 KB');
  });

  test('formatter is not consulted without a locale', () {
    var calls = 0;
    registerHumanizeNumberFormatter((v, o) {
      calls++;
      return '';
    });
    ByteConverter(1500).display.auto();
    expect(calls, 0);
  });
}
