import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('OSParsingModes adapters', () {
    test('Linux human sizes', () {
      final r1 = OSParsingModes.parseLinuxHuman('1.0K');
      expect(r1.isSuccess, isTrue);
      expect(r1.value!.asBytes(), closeTo(1024, 1e-6));

      final r2 = OSParsingModes.parseLinuxHuman('15M');
      expect(r2.isSuccess, isTrue);
      expect(r2.value!.asBytes(), closeTo(15 * 1024 * 1024, 1e-3));

      final r3 = OSParsingModes.parseLinuxHuman('2.5 G');
      expect(r3.isSuccess, isTrue);
      expect(r3.value!.asBytes(), closeTo(2.5 * 1024 * 1024 * 1024, 1e3));
    });

    test('Windows short sizes', () {
      final r1 = OSParsingModes.parseWindowsShort('1.5KB');
      expect(r1.isSuccess, isTrue);
      expect(r1.value!.asBytes(), closeTo(1500, 1e-6));

      final r2 = OSParsingModes.parseWindowsShort('20MB');
      expect(r2.isSuccess, isTrue);
      expect(r2.value!.asBytes(), closeTo(20 * 1000 * 1000, 1e-3));

      final r3 = OSParsingModes.parseWindowsShort('2GB');
      expect(r3.isSuccess, isTrue);
      expect(r3.value!.asBytes(), closeTo(2 * 1000 * 1000 * 1000, 1e-3));
    });

    test('Invalid inputs surface readable errors', () {
      final a = OSParsingModes.parseLinuxHuman('foo');
      expect(a.isSuccess, isFalse);
      expect(a.error!.message, contains('linux'));
      final b = OSParsingModes.parseWindowsShort('bar');
      expect(b.isSuccess, isFalse);
      expect(b.error!.message, contains('Windows'));
    });
  });
}
