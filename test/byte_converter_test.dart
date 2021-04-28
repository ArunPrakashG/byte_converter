import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('Overload from Bits', () {
    ByteConverter converter;

    setUp(() {
      converter = ByteConverter.fromBits(1000000000000);
    });

    test('First Test', () {
      print(converter.toHumanReadable(SizeUnit.TB));
      expect(converter.gigaBytes, 125.0);
    });
  });

  group('Generic from Bytes', () {
    ByteConverter converter;

    setUp(() {
      converter = ByteConverter(1568800);
    });

    test('First Test', () {
      print(converter.toHumanReadable(SizeUnit.TB, precision: 15));
      expect(converter.gigaBytes, 0.0015688);
    });
  });
}
