import 'package:byte_converter/byte_converter.dart';
import 'package:byte_converter/src/_parsing.dart';
import 'package:test/test.dart';

void main() {
  group('Parsing parts smoke tests', () {
    test('parseSize basic SI', () {
      final r = parseSize<SizeUnit>(input: '1.5 GB', standard: ByteStandard.si);
      expect(r.valueInBytes, closeTo(1.5e9, 0.5));
      expect(r.unitSymbol, 'GB');
      expect(r.isBitInput, isFalse);
    });

    test('parseSize handles bits and IEC', () {
      final r = parseSize<SizeUnit>(input: '8 kib', standard: ByteStandard.iec);
      expect(r.isBitInput, isTrue);
      // 8 kib = 8 * 1024 bits = 1024 bytes
      expect(r.valueInBytes, equals(1024.0));
    });

    test('parseSizeBig SI extended units', () {
      final r = parseSizeBig(input: '1 YB', standard: ByteStandard.si);
      expect(r.unit, BigSizeUnit.YB);
      expect(r.unitSymbol, 'YB');
      // Just ensure it parses a very large SI unit and returns a finite value
      expect(r.valueInBytes.isFinite, isTrue);
    });

    test('rate parser still resolves size literals via parts', () {
      final rr = parseRate(input: '100 MB/s', standard: ByteStandard.si);
      // 100 MB/s = 100e6 bytes/s = 800e6 bits/s
      expect(rr.bitsPerSecond, equals(800000000.0));
      expect(rr.unitSymbol, isNotEmpty);
    });
  });
}
