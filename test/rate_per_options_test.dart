import 'package:byte_converter/byte_converter.dart';
import 'package:byte_converter/byte_converter_full.dart'
    show fastHumanizeSiRateBytesPerSecond, fastHumanizeSiRateBitsPerSecond;
import 'package:test/test.dart';

void main() {
  group('DataRate per options', () {
    test('toHumanReadableAutoWith uses ByteFormatOptions.per=/ms', () {
      final r = DataRate.bytesPerSecond(1000); // 1000 B/s
      final text = r.toHumanReadableAutoWith(const ByteFormatOptions(
        useBytes: true,
        per: 'ms',
      ));
      // 1000 B/s -> 1 B/ms
      expect(text, '1 B/ms');
    });

    test('toHumanReadableAutoWith uses ByteFormatOptions.per=/min', () {
      final r = DataRate.bytesPerSecond(1500000); // 1.5 MB/s
      final text = r.toHumanReadableAutoWith(const ByteFormatOptions(
        useBytes: true,
        per: 'min',
      ));
      // 1.5 MB/s -> 90 MB/min
      expect(text, '90 MB/min');
    });

    test('toHumanReadableAutoWith uses ByteFormatOptions.per=/h (bits)', () {
      final r = DataRate.megaBitsPerSecond(1); // 1 Mb/s
      final text = r.toHumanReadableAutoWith(const ByteFormatOptions(
        // default useBytes=false => bits
        per: 'h',
      ));
      // 1 Mb/s -> 3600 Mb/h
      expect(text, '3.6 Gb/h');
    });

    test('toHumanReadableCompound supports per ms (integer parts)', () {
      final r = DataRate.bytesPerSecond(2500); // 2.5 KB/s
      final text = r.toHumanReadableCompound(per: 'ms');
      // 2.5 KB/s -> 2.5 B/ms, compound formatting uses integer parts => 2 B/ms
      expect(text, '2 B/ms');
    });

    test('toHumanReadableCompound supports per min', () {
      final r = DataRate.bytesPerSecond(125000000); // 125 MB/s
      final text = r.toHumanReadableCompound(
        per: 'min',
        options: const CompoundFormatOptions(standard: ByteStandard.si),
      );
      // 125 MB/s -> 7500 MB/min => 7.5 GB/min compound; SI symbols expected
      expect(text, endsWith('/min'));
      expect(text, contains('GB'));
      expect(text, anyOf(startsWith('7 GB'), startsWith('7.5 GB')));
    });
  });

  group('Fast rate formatters', () {
    test('fastHumanizeSiRateBytesPerSecond /ms', () {
      final s = fastHumanizeSiRateBytesPerSecond(1000, per: 'ms');
      expect(s, '1 B/ms');
    });

    test('fastHumanizeSiRateBytesPerSecond /s', () {
      final s = fastHumanizeSiRateBytesPerSecond(125000000, per: 's');
      expect(s, '125 MB/s');
    });

    test('fastHumanizeSiRateBitsPerSecond /s', () {
      final s = fastHumanizeSiRateBitsPerSecond(8000000000, per: 's');
      expect(s, '8 Gb/s');
    });

    test('fastHumanizeSiRateBitsPerSecond /min', () {
      final s = fastHumanizeSiRateBitsPerSecond(1000000, per: 'min');
      expect(s, '60 Mb/min');
    });
  });
}
