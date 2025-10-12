import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('Compound formatting', () {
    test('IEC bytes default two parts', () {
      final size = ByteConverter.parse('1234567890');
      final text = size.toHumanReadableCompound();
      // 1 GiB 153 MiB (approx) with IEC default
      expect(text, contains('GiB'));
      expect(text, contains('MiB'));
    });

    test('Force smallest unit and maxParts', () {
      final size = ByteConverter.parse('1 GiB + 153 MiB + 385 KiB',
          standard: ByteStandard.iec);
      final text = size.toHumanReadableCompound(
        options: CompoundFormatOptions(
            standard: ByteStandard.iec, maxParts: 3, smallestUnit: 'B'),
      );
      expect(text.split(' ').length >= 3, isTrue);
    });

    test('SI bits compound', () {
      final size = ByteConverter.parse('1 MB');
      final text = size.toHumanReadableCompound(
        options:
            CompoundFormatOptions(standard: ByteStandard.si, useBits: true),
      );
      expect(text.toLowerCase(), contains('mb'));
    });

    test('DataRate compound appends /s', () {
      final rate = DataRate.parse('125 MB/s');
      final text = rate.toHumanReadableCompound(
        options: const CompoundFormatOptions(standard: ByteStandard.si),
      );
      expect(text, endsWith('/s'));
    });
  });
}
