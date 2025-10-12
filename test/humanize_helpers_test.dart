import 'package:byte_converter/src/_parsing.dart' as internal;
import 'package:byte_converter/src/byte_enums.dart';
import 'package:byte_converter/src/humanize_options.dart';
import 'package:test/test.dart';

void main() {
  group('_unitSymbolFor', () {
    test('SI K upper vs lower', () {
      final optUpper =
          HumanizeOptions(precision: 2, siKSymbolCase: SiKSymbolCase.upperK);
      final optLower =
          HumanizeOptions(precision: 2, siKSymbolCase: SiKSymbolCase.lowerK);

      expect(
        internal.testUnitSymbolFor('KB', false, ByteStandard.si, optUpper),
        equals('KB'),
      );
      expect(
        internal.testUnitSymbolFor('KB', false, ByteStandard.si, optLower),
        equals('kB'),
      );

      // Non-K symbols unaffected
      expect(
        internal.testUnitSymbolFor('MB', false, ByteStandard.si, optLower),
        equals('MB'),
      );
    });

    test('bit symbols normalization', () {
      final opt = HumanizeOptions(precision: 1);
      expect(internal.testUnitSymbolFor('B', true, ByteStandard.si, opt), 'b');
      expect(
          internal.testUnitSymbolFor('MB', true, ByteStandard.si, opt), 'Mb');
      expect(
          internal.testUnitSymbolFor('Mb', true, ByteStandard.si, opt), 'Mb');
    });
  });

  group('_signedPrefixFor', () {
    final optSigned = HumanizeOptions(precision: 1, signed: true);
    final optUnsigned = HumanizeOptions(precision: 1, signed: false);

    test('signed on', () {
      expect(internal.testSignedPrefixFor(1.0, optSigned), '+');
      expect(internal.testSignedPrefixFor(-1.0, optSigned), '-');
      expect(internal.testSignedPrefixFor(0.0, optSigned), ' ');
    });

    test('signed off', () {
      expect(internal.testSignedPrefixFor(1.0, optUnsigned), '');
      expect(internal.testSignedPrefixFor(0.0, optUnsigned), '');
    });
  });
}
