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

  print('\n--- BigInt Examples for Very Large Data ---');

  // BigInt usage for very large numbers
  final dataCenter = BigByteConverter.fromExaBytes(BigInt.from(5));
  print('Data center storage: $dataCenter');

  // Precise calculations with BigInt
  final preciseCalculation =
      BigInt.parse('123456789012345678901234567890').bytes;
  print('Ultra-precise value: ${preciseCalculation.asBytes} bytes');

  // Large unit support (exabytes, zettabytes, yottabytes)
  final cosmicData = BigByteConverter.fromYottaBytes(BigInt.from(1));
  print('Cosmic scale data: $cosmicData');

  // BigInt math operations
  final bigFile1 = BigByteConverter.fromTeraBytes(BigInt.from(500));
  final bigFile2 = BigByteConverter.fromTeraBytes(BigInt.from(300));
  final bigTotal = bigFile1 + bigFile2;
  print('Large files total: $bigTotal');

  // Conversion between BigInt and regular converters
  final normalConverter = ByteConverter(1048576); // 1 MB
  final bigConverter = BigByteConverter.fromByteConverter(normalConverter);
  print('Converted to BigInt: ${bigConverter.asBytes} bytes');

  // Convert back (may lose precision for very large numbers)
  final backToNormal = bigConverter.toByteConverter();
  print('Converted back: ${backToNormal.asBytes()} bytes');

  // Exact arithmetic with BigInt
  final exactGB = BigInt.from(1000000000).bytes; // Exactly 1 GB
  print('Exact GB: ${exactGB.gigaBytesExact} GB (exact)');
  print('Approx GB: ${exactGB.gigaBytes} GB (double precision)');

  // BigInt extensions
  final fromExtension = BigInt.from(1024).kibiBytes;
  print('From BigInt extension: $fromExtension');

  // Very large number serialization
  final hugeNumber =
      BigByteConverter(BigInt.parse('999999999999999999999999999'));
  final hugeJson = hugeNumber.toJson();
  final restoredHuge = BigByteConverter.fromJson(hugeJson);
  print('Huge number preserved: ${restoredHuge.asBytes}');

  // Parsing strings
  final parsed = ByteConverter.parse('1.5 GB');
  print('Parsed: $parsed');

  // Data rate parsing and formatting
  final rate = DataRate.parse('100 Mbps');
  print('Rate: ${rate.toHumanReadableAuto()}');
  print('Rate (bytes): ${rate.toHumanReadableAuto(useBytes: true)}');
}
