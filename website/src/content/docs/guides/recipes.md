---
title: Recipes 👩‍🍳
---

Real-world snippets using byte_converter.

## Estimate download time from size + Mbps

```dart
import 'package:byte_converter/byte_converter.dart';

Duration estimateDownload(String sizeText, double mbps) {
  final size = ByteConverter.parse(sizeText); // e.g., "1.5 GB"
  final rate = DataRate.megaBitsPerSecond(mbps);
  // Using rate namespace (recommended)
  return size.rate.transferTime(rate);
}

void main() {
  final t = estimateDownload('1.5 GB', 100);
  print(t); // e.g., 2min 0s (Duration format)
}
```

## Humanize logs with locale and forced units

```dart
final c = ByteConverter.parse('1536 KB');

// Using namespace API (recommended)
final text = c.display.auto(
  minimumFractionDigits: 1,
  maximumFractionDigits: 1,
  forceUnit: 'MB',
);
// => "1.5 MB"
```

## Parse user input robustly

```dart
final a = ByteConverter.parse('1\u00A0234,56 KB'); // NBSP + comma decimal
final b = ByteConverter.parse('12_345.67 MB');     // underscore grouping
final c = ByteConverter.parse('10 megabits');      // full-form bits
```

## Choose Big vs normal automatically

```dart
final r = parseByteSizeAuto('12.34 ZiB', standard: ByteStandard.iec);
print(r.isBig ? 'Big' : 'Normal');
```

## Convert sizes to a specific unit for reports

```dart
String toMB(num bytes) => ByteConverter(bytes.toDouble())
    .display.inUnit(SizeUnit.MB, precision: 0); // no decimals
```

## Data rate: force unit and signed notation

```dart
final r = DataRate.megaBitsPerSecond(1920);
final text = r.toHumanReadableAuto(
  forceUnit: 'Mb',
  spacer: '',
  minimumFractionDigits: 1,
  maximumFractionDigits: 1,
  signed: true,
);
// => "+1920.0Mb/s"
```

````

---

## Architecture overview (diagram)

```mermaid
flowchart TD
  A[Input strings] -->|parseSize / parseSizeBig / parseRate| B((Parsing))
  B --> C{ByteStandard}
  C -->|si| D[SI]
  C -->|iec| E[IEC]
  C -->|jedec| F[JEDEC]
  B --> G[ByteConverter]
  B --> H[BigByteConverter]
  G --> I[toHumanReadableAuto]
  H --> I
  I --> J[Text output]
  G --> K[DataRate.transferTimeForBytes]
  L[DataRate] --> I
````

## CLI usage (simple tool)

Create a small Dart script `bin/bytes.dart` in your app:

```dart
import 'package:byte_converter/byte_converter.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: bytes <size> [--iec|--jedec]');
    return;
  }
  final input = args.first;
  final std = args.contains('--iec')
      ? ByteStandard.iec
      : (args.contains('--jedec') ? ByteStandard.jedec : ByteStandard.si);
  try {
    final bc = ByteConverter.parse(input, standard: std);
    print('Auto: ' + bc.toHumanReadableAuto(standard: std));
    print('MB:   ' + bc.toHumanReadable(SizeUnit.MB));
  } catch (e) {
    print('Error: ' + e.toString());
  }
}
```

Run it:

```bash
dart run bin/bytes.dart "1.5 GiB" --iec
```

## Integration with Flutter UI

```dart
// Example Widget showing formatted size
class SizeTile extends StatelessWidget {
  final String sizeText;
  const SizeTile({super.key, required this.sizeText});
  @override
  Widget build(BuildContext context) {
    final parsed = ByteConverter.parse(sizeText);
    final formatted = parsed.toHumanReadableAuto(
      standard: ByteStandard.si,
      minimumFractionDigits: 1,
      maximumFractionDigits: 1,
    );
    return ListTile(
      leading: const Icon(Icons.sd_storage),
      title: Text(formatted),
      subtitle: Text('Raw: ${parsed.asBytes()} bytes'),
    );
  }
}
```

## Batch convert inputs from a CSV file

Example CSV (`sizes.csv`):

```
filename,size
movie.mp4,1.5 GB
iso.iso,4.7 GB
archive.7z,1536 MiB
```

Dart script `tool/csv_sizes.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:byte_converter/byte_converter.dart';

Future<void> main() async {
  final file = File('sizes.csv');
  final lines = const LineSplitter().convert(await file.readAsString());
  // Skip header
  for (final line in lines.skip(1)) {
    final parts = line.split(',');
    if (parts.length < 2) continue;
    final name = parts[0];
    final raw = parts[1];
    try {
      // Try IEC first for MiB/GiB; fall back to SI
      ByteConverter parsed;
      try {
        parsed = ByteConverter.parse(raw, standard: ByteStandard.iec);
      } catch (_) {
        parsed = ByteConverter.parse(raw, standard: ByteStandard.si);
      }
      final human = parsed.toHumanReadableAuto(
        minimumFractionDigits: 1,
        maximumFractionDigits: 1,
      );
      print('$name -> ${parsed.asBytes()} B ($human)');
    } catch (e) {
      stderr.writeln('Failed to parse "$raw" for $name: $e');
    }
  }
}
```

Run:

```bash
dart run tool/csv_sizes.dart
```

## Format sizes with i18n

```dart
final file = ByteConverter.parse('1536 KB');

// French-like decimal comma
final fr = file.toHumanReadableAuto(
  separator: ',',
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
  spacer: ' ',
);
// => "1,54 KB"

// Spanish-like with sign and forced unit
final es = file.toHumanReadableAuto(
  separator: ',',
  minimumFractionDigits: 1,
  maximumFractionDigits: 1,
  signed: true,
  forceUnit: 'MB',
);
// => "+0,0 MB"
```

## Troubleshooting: parsing errors

If you get a `FormatException` like unknown units, match the `standard` to your input or use full-form units.

![Parsing Error](/images/parsing-error.svg)

---

## Display storage usage with progress bar

```dart
import 'package:byte_converter/byte_converter.dart';

void showStorageUsage(double usedBytes, double totalBytes) {
  final used = ByteConverter(usedBytes);
  final total = ByteConverter(totalBytes);

  print('Storage: ${used.toHumanReadableAuto()} / ${total.toHumanReadableAuto()}');
  print(used.compare.percentageBar(total, width: 20));
  print('${used.compare.percentOf(total).toStringAsFixed(1)}% used');
}

// Output:
// Storage: 75 GB / 100 GB
// ███████████████░░░░░
// 75.0% used
```

## Accessible file size announcements

```dart
void announceFileSize(ByteConverter size) {
  // For screen readers
  print(size.accessibility.screenReader());
  // "one point five megabytes"

  // For ARIA labels
  print('<span aria-label="${size.accessibility.ariaLabel}">');
  // <span aria-label="File size: 1.5 megabytes">
}
```

## Track download progress with relative time

```dart
import 'package:byte_converter/byte_converter.dart';

void showProgress(Duration elapsed, Duration total) {
  final remaining = total - elapsed;

  print('Elapsed: ${elapsed.relative}');
  print('Remaining: ${remaining.fromNow}');
  print(RelativeTime.progress(elapsed, total));
  // "2m / 5m (40%)"
}
```

## Validate upload against service limits

```dart
import 'package:byte_converter/byte_converter.dart';

bool canUploadToGithub(ByteConverter fileSize) {
  final result = ByteValidation.validate(
    fileSize,
    maxSize: ByteConstants.githubFileSizeLimit,
  );

  if (!result.isValid) {
    print('Error: ${result.message}');
    return false;
  }
  return true;
}

// Usage
final file = ByteConverter.fromMegaBytes(150);
if (!canUploadToGithub(file)) {
  print('File too large for GitHub (max 100 MB)');
}
```

## Format large numbers with SI prefixes

```dart
import 'package:byte_converter/byte_converter.dart';

void displayMetrics(int requests, int latencyNs) {
  print('Requests: ${SINumber.humanize(requests)}');      // "1.5M"
  print('Latency: ${SINumber.humanize(latencyNs, unit: 's')}'); // "150µs"
}
```

## Show file rankings with ordinals

```dart
import 'package:byte_converter/byte_converter.dart';

void showRanking(List<(String, ByteConverter)> files) {
  files.sort((a, b) => b.$2.bytes.compareTo(a.$2.bytes));

  for (var i = 0; i < files.length; i++) {
    final (name, size) = files[i];
    print('${(i + 1).ordinal}: $name (${size.toHumanReadableAuto()})');
  }
}

// Output:
// 1st: video.mp4 (1.5 GB)
// 2nd: archive.zip (500 MB)
// 3rd: document.pdf (2.5 MB)
```

## Track bandwidth over time

```dart
import 'package:byte_converter/byte_converter.dart';

final accumulator = BandwidthAccumulator();

void onDataReceived(int bytes) {
  accumulator.add(ByteConverter(bytes.toDouble()));

  print('Total: ${accumulator.total.toHumanReadableAuto()}');
  print('Average: ${accumulator.average.toHumanReadableAuto()}');
  print('Peak: ${accumulator.peak.toHumanReadableAuto()}');
}
```

## Display size changes with deltas

```dart
import 'package:byte_converter/byte_converter.dart';

void showSizeChange(double beforeBytes, double afterBytes) {
  final delta = SizeDelta(beforeBytes, afterBytes);

  print(NegativeByteFormatter.formatComparison(beforeBytes, afterBytes));
  // "1 GB → 750 MB (-250 MB, -25.0%)"

  print(NegativeByteFormatter.formatWithArrow(delta.difference));
  // "↓ 250 MB"
}
```
