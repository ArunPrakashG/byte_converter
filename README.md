<h1 align="center">🧮 ByteConverter</h1>

<p align="center">
  <a href="https://pub.dev/packages/byte_converter"><img src="https://img.shields.io/pub/v/byte_converter" alt="Pub Version" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT" /></a>

</p>

<p align="center">Fast, dependable byte and data-rate conversions for Dart with fluent APIs and optional BigInt precision.</p>

## ✨ Highlights

- 🚀 Instant parsing and formatting for bytes, bits, and rates across SI, IEC, and JEDEC standards
- 🧮 Expression-friendly math with operators, durations, and auto unit detection
- 🧠 BigInt precision via `BigByteConverter` plus matching `DataRate` and `BigDataRate` APIs
- 🕒 Transfer planning helpers that surface ETAs, progress, and burst windows in a single call
- 📦 Storage profiles with configurable alignment, slack inspection, and round-to-profile helpers
- 📊 Aggregate metrics through `ByteStats`/`BigByteStats` for sums, averages, percentiles, and histograms
- 🌍 Localization-ready humanize output with custom format options, optional `intl` integration, and built-in unit names for English (including en_IN), German, French, Hindi, Spanish, Portuguese, Japanese, Chinese, and Russian
- ✍️ Formatting ergonomics: fixed-width numeric alignment (`fixedWidth`), sign-aware padding (`includeSignInWidth`), non‑breaking space (`nonBreakingSpace`), truncation (`truncate`), SI k‑case styling (KB vs kB), and pattern formatting with tokens `u`/`U`/`S`
- 🧰 CLI goodies: `--pattern`, `--per` for rate time base, `--fixed-width`, `--si-lower-k`, `--nbsp`, `--truncate`, and `--strict-bits`
- 🧾 FormatterSnapshot generators that keep README/wiki matrices and snapshot tests in sync

## 📦 Installation

```yaml
dependencies:
  byte_converter: ^2.4.1
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

### A little more flair ✨

```dart
// Pattern formatting with tokens: 0-number, u-symbol, U-full word, S-sign
final s1 = ByteConverter.parse('1536 KB')
  .formatWith('S0.0 u', options: const ByteFormatOptions(signed: true));
// +1.5 MB

// Align numbers with fixed width (great for columns)
final rows = [1, 12, 123, 1234].map((n) =>
  ByteConverter(n * 1000).toHumanReadableAutoWith(
    const ByteFormatOptions(fixedWidth: 6),
  ));
//  "  1.0 KB", " 12.0 KB", "123.0 KB", "1,234.0 KB" (locale-aware when intl is enabled)

// Prefer kB over KB? Opt into SI lower-k
final s2 = ByteConverter.parse('2048 B').toHumanReadableAutoWith(
  const ByteFormatOptions(siKSymbolCase: SiKSymbolCase.lowerK),
);
// 2.0 kB
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

### CLI (optional) 🧰

```sh
# Format a size with fixed width and SI lower-k
bytec format "1 GiB + 153 MiB" --fixed-width 8 --si-lower-k

# Parse, humanize, and pick a rate time base
bytec rate "125 MB/s" --per ms
```

## 📚 Documentation

The complete guide lives in the wiki:

- [Home](https://github.com/ArunPrakashG/byte_converter/wiki)
- [Getting Started](https://github.com/ArunPrakashG/byte_converter/wiki/Getting-Started)
- [Usage Guide](https://github.com/ArunPrakashG/byte_converter/wiki/Usage)
- [API Reference](https://github.com/ArunPrakashG/byte_converter/wiki/API-Reference)
- [Recipes](https://github.com/ArunPrakashG/byte_converter/wiki/Recipes)
- [FAQ](https://github.com/ArunPrakashG/byte_converter/wiki/FAQ)

## ⚡ Fast formatting API + performance tips

When you only need the fastest possible string for common cases, use the public fast API. These helpers bypass advanced features (locale, grouping, NBSP, fullForm, fixedWidth, signed) and take the shortest path:

```dart
// Ultra-fast helpers
print(fastHumanizeSiBytes(123456789));  // e.g., "123.5 MB"
print(fastHumanizeIecBytes(123456789)); // e.g., "117.7 MiB"
print(fastHumanizeSiBits(123456789));   // e.g., "987.7 Mb"
```

Performance tips:

- If you frequently pin a unit, pass `forceUnit` (e.g., always `GB`, `KB`, or `KiB`) with simple options to hit a micro fast-path in the main formatter.
- Keep options minimal when you care about pure throughput (avoid locale/fullForm/fixedWidth unless needed).
- See the wiki for a deeper guide and examples: [Formatting – Fast formatting](https://github.com/ArunPrakashG/byte_converter/wiki/Formatting#fast-formatting-ultra-low-overhead).
- Benchmarks and methodology live here: [Benchmarks](https://github.com/ArunPrakashG/byte_converter/wiki/Benchmarks).

Repro tips (Windows): use the High Performance/Ultimate power plan, keep laptops on AC power, close background apps, and run multiple times (best‑of) to reduce scheduler noise.

## 🔌 Optional Add-ons

- `byte_converter_intl.dart` opt-in delivers locale-aware number formatting and localized unit names
- Built-in localized vocabulary now spans English (including en_IN), German, French, Hindi (hi/hi_IN), Spanish (es), Portuguese (pt), Japanese (ja), Chinese (zh), and Russian (ru)
- FormatterSnapshot helpers keep README tables, wiki docs, and snapshot tests aligned
- Wiki recipes cover CLI usage, monitoring dashboards, and BigInt-heavy workloads

- `byte_converter_lite.dart` opt-in provides lightweight locale-aware number formatting (no intl dependency) for common locales. See [wiki: Formatting – Lightweight number formatter](https://github.com/ArunPrakashG/byte_converter/wiki/Formatting#lightweight-number-formatter-no-intl).

## 🧠 Advanced capabilities

We also support advanced features—see the wiki for details and examples:

- Transfer planning with schedules, throttle, and pause/resume
- Locale-aware parsing (parseLocalized) and tree-shakable unit name maps
- OS parsing adapters (Linux ls -lh, Windows short sizes)
- Streaming quantiles (P²) for p50/p95/p99

Wiki links:

- Usage: https://github.com/ArunPrakashG/byte_converter/wiki/Usage
- Parsing: https://github.com/ArunPrakashG/byte_converter/wiki/Parsing
- Data Rate: https://github.com/ArunPrakashG/byte_converter/wiki/Data-Rate
- API Reference: https://github.com/ArunPrakashG/byte_converter/wiki/API-Reference

## 📊 Benchmarks

Microbenchmarks and a P² vs t‑digest comparison are available in `tool/bench/bench.dart`.

Run locally:

```sh
dart run tool/bench/bench.dart
```

## 🤝 Contributing

Issues and pull requests are welcome. Check the [issue tracker](https://github.com/ArunPrakashG/byte_converter/issues) to report bugs or request features.

## 📄 License

Released under the [MIT License](LICENSE).
