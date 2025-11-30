import 'package:byte_converter/byte_converter.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Basic usage with namespace API (recommended)
  // ─────────────────────────────────────────────────────────────────────────

  final fileSize = ByteConverter.fromMegaBytes(1536); // 1.5 GB

  // Display namespace - multiple formatting options
  print('Auto: ${fileSize.display.auto()}'); // "1.5 GB"
  print('Fuzzy: ${fileSize.display.fuzzy()}'); // "about 1.5 GB"
  print('GNU: ${fileSize.display.gnu()}'); // "1.5G"
  print('Scientific: ${fileSize.display.scientific()}'); // "1.5 × 10⁹ B"
  print('Compound: ${fileSize.display.compound()}'); // "1 GB 536 MB"

  // Storage namespace - disk alignment
  print('Sectors: ${fileSize.storage.sectors}'); // 512-byte sectors
  print('Blocks: ${fileSize.storage.blocks}'); // 4KB blocks

  // Rate namespace - network calculations
  final rate = DataRate.megaBitsPerSecond(100);
  print('Transfer time: ${fileSize.rate.transferTime(rate)}'); // Duration

  // Compare namespace - size comparisons
  final total = ByteConverter.fromGigaBytes(10);
  print('Percent of total: ${fileSize.compare.percentOf(total)}%'); // 15.0%
  print('Progress: ${fileSize.compare.percentageBar(total)}'); // "██░░░░░░░░"

  // Accessibility namespace - screen reader support
  print('Screen reader: ${fileSize.accessibility.screenReader()}');

  // Output namespace - serialization
  print('As Map: ${fileSize.output.asMap}');

  // ─────────────────────────────────────────────────────────────────────────
  // Parsing - flexible string input
  // ─────────────────────────────────────────────────────────────────────────

  final parsed = ByteConverter.parse('2 GiB + 512 MiB'); // Expression support!
  print(
      '\nParsed expression: ${parsed.display.auto(standard: ByteStandard.iec)}');

  // Safe parsing with diagnostics
  final result = ByteConverter.tryParse('invalid');
  if (!result.isSuccess) {
    print('Parse error: ${result.error}');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Data rates
  // ─────────────────────────────────────────────────────────────────────────

  print('\n--- Data Rates ---');
  final download = DataRate.parse('100 Mbps');
  print('Rate: ${download.toHumanReadableAuto()}');
  print('As bytes: ${download.toHumanReadableAuto(useBytes: true)}');

  // Transfer planning
  final plan = fileSize.estimateTransfer(download);
  print('ETA: ${plan.etaString()}');

  // ─────────────────────────────────────────────────────────────────────────
  // Math operations
  // ─────────────────────────────────────────────────────────────────────────

  print('\n--- Math Operations ---');
  final file1 = ByteConverter.fromMegaBytes(100);
  final file2 = ByteConverter.fromMegaBytes(50);
  print('Sum: ${(file1 + file2).display.auto()}');
  print('Diff: ${(file1 - file2).display.auto()}');

  // ─────────────────────────────────────────────────────────────────────────
  // BigInt for massive values (YB, ZB scale)
  // ─────────────────────────────────────────────────────────────────────────

  print('\n--- BigInt Examples ---');
  final dataCenter = BigByteConverter.fromExaBytes(BigInt.from(5));
  print('Data center: ${dataCenter.toHumanReadableAuto()}');

  final cosmic = BigByteConverter.fromYottaBytes(BigInt.from(1));
  print('Cosmic scale: ${cosmic.toHumanReadableAuto()}');

  // BigInt math
  final bigTotal = BigByteConverter.fromTeraBytes(BigInt.from(500)) +
      BigByteConverter.fromTeraBytes(BigInt.from(300));
  print('Large total: ${bigTotal.toHumanReadableAuto()}');

  // ─────────────────────────────────────────────────────────────────────────
  // Extensions on int/double
  // ─────────────────────────────────────────────────────────────────────────

  print('\n--- Extensions ---');
  print('1.5.gigaBytes: ${1.5.gigaBytes.display.auto()}');
  print(
      '1024.mebiBytes: ${1024.mebiBytes.display.auto(standard: ByteStandard.iec)}');
}
