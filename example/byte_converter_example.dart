import 'package:byte_converter/byte_converter.dart';

void main() {
  // Basic usage
  final fileSize = ByteConverter(1500000);
  print('File size: ${fileSize.toHumanReadable(SizeUnit.MB)}'); // 1.5 MB

  // Different units
  final download = ByteConverter.fromGigaBytes(2.5);
  print('Download size: $download'); // Automatically formats to best unit

  // Binary units
  final ram = ByteConverter.fromGibiBytes(16);
  print('RAM: ${ram.toHumanReadable(SizeUnit.GB)} (${ram.gibiBytes} GiB)');

  // Math operations
  final file1 = ByteConverter.fromMegaBytes(100);
  final file2 = ByteConverter.fromMegaBytes(50);
  final total = file1 + file2;
  print('Total size: $total');

  // Comparisons
  if (file1 > file2) {
    print('File 1 is larger');
  }

  // Custom precision
  final precise = ByteConverter.fromKiloBytes(1.23456);
  print('With 2 decimals: ${precise.toHumanReadable(SizeUnit.KB)}');
  print(
    'With 4 decimals: ${precise.toHumanReadable(SizeUnit.KB, precision: 4)}',
  );

  // JSON serialization
  final data = ByteConverter.fromMegaBytes(100);
  final json = data.toJson();
  final restored = ByteConverter.fromJson(json);
  print('Restored from JSON: $restored');

  // Unit conversions
  final mixed = ByteConverter(1024 * 1024); // 1 MiB
  print('As MB: ${mixed.megaBytes} MB');
  print('As MiB: ${mixed.mebiBytes} MiB');
}
