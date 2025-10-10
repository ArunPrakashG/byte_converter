# ByteConverter

[![Pub Version](https://img.shields.io/pub/v/byte_converter)](https://pub.dev/packages/byte_converter)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Fast, dependable byte and data-rate conversions for Dart with fluent APIs and optional BigInt precision.

## ✨ Highlights

- 🚀 Instant parsing and formatting for bytes, bits, and rates across SI, IEC, and JEDEC standards
- 🧮 Expression-friendly math with operators, durations, and auto unit detection
- 🧠 BigInt precision via `BigByteConverter` plus matching `DataRate` and `BigDataRate` APIs
- 🕒 Transfer planning helpers that surface ETAs, progress, and burst windows in a single call
- 📦 Storage profiles with configurable alignment, slack inspection, and round-to-profile helpers
- 📊 Aggregate metrics through `ByteStats`/`BigByteStats` for sums, averages, percentiles, and histograms
- 🌍 Localization-ready humanize output with custom format options, optional `intl` integration, and built-in unit names for English (including en_IN), German, French, Hindi, Spanish, Portuguese, Japanese, Chinese, and Russian
- 🧾 FormatterSnapshot generators that keep README/wiki matrices and snapshot tests in sync

## 📦 Installation

```yaml
dependencies:
  byte_converter: ^2.3.1
```

## 💡 Quick Example

```dart
import 'package:byte_converter/byte_converter.dart';

void main() {
  final size = ByteConverter.parse('2.5 GB');
  final rate = DataRate.parse('150 Mbps');
  final plan = size.estimateTransfer(rate);

  print(size.toHumanReadableAuto()); // 2.5 GB
  print(plan.etaString());           // friendly ETA string
}
```

## 🛠️ Common Tasks

```dart
// Expression-aware parsing and humanizing
final payload = ByteConverter.parse('(1 GiB + 512 MiB) - 256 MB');
print(payload.toHumanReadableAuto());

// Transfer windows and alignment checks
final burst = DataRate.parse('500 Mbps').transferableBytes(const Duration(seconds: 10));
final aligned = burst.roundToProfile(
  StorageProfile.singleBlock('object', blockSizeBytes: 4 * 1024 * 1024),
);

// Aggregations across mixed inputs
final total = ByteStats.sum([
  payload,
  burst,
  ByteConverter.parse('750 MB'),
]);
print(total.toHumanReadableAuto());
```

## 📚 Documentation

The complete guide lives in the wiki:

- [Home](https://github.com/ArunPrakashG/byte_converter/wiki)
- [Getting Started](https://github.com/ArunPrakashG/byte_converter/wiki/Getting-Started)
- [Usage Guide](https://github.com/ArunPrakashG/byte_converter/wiki/Usage)
- [API Reference](https://github.com/ArunPrakashG/byte_converter/wiki/API-Reference)
- [Recipes](https://github.com/ArunPrakashG/byte_converter/wiki/Recipes)
- [FAQ](https://github.com/ArunPrakashG/byte_converter/wiki/FAQ)

## 🔌 Optional Add-ons

- `byte_converter_intl.dart` opt-in delivers locale-aware number formatting and localized unit names
- Built-in localized vocabulary now spans English (including en_IN), German, French, Hindi (hi/hi_IN), Spanish (es), Portuguese (pt), Japanese (ja), Chinese (zh), and Russian (ru)
- FormatterSnapshot helpers keep README tables, wiki docs, and snapshot tests aligned
- Wiki recipes cover CLI usage, monitoring dashboards, and BigInt-heavy workloads

## 🤝 Contributing

Issues and pull requests are welcome. Check the [issue tracker](https://github.com/ArunPrakashG/byte_converter/issues) to report bugs or request features.

## 📄 License

Released under the [MIT License](LICENSE).

```

```
