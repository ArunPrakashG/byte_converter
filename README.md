<div align="center">

# 🔢 ByteConverter

**A fast, comprehensive byte & data-rate conversion library for Dart**

[![Pub Version](https://img.shields.io/pub/v/byte_converter?color=blue&logo=dart)](https://pub.dev/packages/byte_converter)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Dart 3](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)

[📖 Documentation](https://github.com/ArunPrakashG/byte_converter/wiki) · [🐛 Report Bug](https://github.com/ArunPrakashG/byte_converter/issues) · [💡 Request Feature](https://github.com/ArunPrakashG/byte_converter/issues)

</div>

---

## ✨ Features

| | Feature | Description |
|:-:|---------|-------------|
| 📏 | **Multi-Standard** | SI (KB, MB, GB), IEC (KiB, MiB, GiB), and JEDEC support |
| 🔍 | **Smart Parsing** | Parse any format: `"1.5 GB"`, `"2 GiB + 512 MiB"`, `"1,234 bytes"` |
| 🔢 | **BigInt Support** | Arbitrary precision for massive values (YB, ZiB, and beyond) |
| 🚀 | **Data Rates** | Full bits/bytes per second with transfer time estimation |
| 🌍 | **9 Languages** | Built-in localization: EN, DE, FR, ES, PT, HI, JA, ZH, RU |
| 🎯 | **Clean API** | Namespace-based: `display`, `storage`, `rate`, `compare`, `accessibility` |
| ♿ | **Accessible** | Screen reader friendly output & ARIA labels |
| 📊 | **Statistics** | Streaming quantiles, percentiles, and aggregation |

---

## 🚀 Quick Start

### Installation

```yaml
dependencies:
  byte_converter: ^3.0.0
```

### Basic Usage

```dart
import 'package:byte_converter/byte_converter.dart';

void main() {
  // 📦 Create from any unit
  final size = ByteConverter.fromGigaBytes(1.5);
  
  // 🎨 Display formats
  print(size.display.auto());    // "1.5 GB"
  print(size.display.fuzzy());   // "about 1.5 GB"
  print(size.display.gnu());     // "1.5G"
  
  // 🔍 Parse strings (even expressions!)
  final parsed = ByteConverter.parse('2 GiB + 512 MiB');
  print(parsed.gigaBytes);       // 2.68435456
  
  // 🚀 Data rates & transfer estimation
  final rate = DataRate.parse('100 Mbps');
  final plan = size.estimateTransfer(rate);
  print(plan.etaString());       // "2m 0s"
}
```

---

## 📦 Import Options

```dart
// 🎯 Core (most use cases)
import 'package:byte_converter/byte_converter.dart';

// 🔥 Full (statistics, streaming, interop)
import 'package:byte_converter/byte_converter_full.dart';

// 🪶 Locale-aware numbers without extra dependencies
//    (built-in separators for en, de, fr, es, pt, ja, zh, ru)
import 'package:byte_converter/byte_converter_lite.dart';
```

> The package has **no runtime dependencies**. To format numbers with
> `package:intl`, register a formatter once:
>
> ```dart
> registerHumanizeNumberFormatter((value, o) {
>   final locale = o.locale;
>   if (locale == null || locale.isEmpty) return ''; // '' = use the default
>   final f = NumberFormat.decimalPattern(locale)
>     ..minimumFractionDigits = o.minimumFractionDigits ?? 0
>     ..maximumFractionDigits =
>         o.maximumFractionDigits ?? o.minimumFractionDigits ?? o.precision;
>   return f.format(value);
> });
> ```

---

## 🎯 Namespace API

```dart
final size = ByteConverter.fromMegaBytes(1536);

// 🎨 Display - formatting options
size.display.auto()        // "1.54 GB"
size.display.fuzzy()       // "about 1.54 GB"
size.display.scientific()  // "1.54 × 10⁹ B"

// 💾 Storage - disk alignment
size.storage.sectors       // 3000000 (512B sectors)
size.storage.blocks        // 375000 (4KB blocks)

// 📡 Rate - network calculations
size.rate.bitsPerSecond    // 12288000000.0
size.rate.transferTime(rate) // Duration

// 📊 Compare - size comparisons
size.compare.percentOf(total)     // 15.0
size.compare.percentageBar(total) // "███░░░░░░░░░░░░░░░░░" (20 chars)

// ♿ Accessibility
size.accessibility.screenReader() // "one point five four gigabytes"
```

---

## 📚 Documentation

| Resource | Description |
|:---------|:------------|
| 📖 [Wiki](https://github.com/ArunPrakashG/byte_converter/wiki) | Full documentation |
| 🏁 [Getting Started](https://github.com/ArunPrakashG/byte_converter/wiki/Getting-Started) | Installation & setup |
| 📝 [Usage Guide](https://github.com/ArunPrakashG/byte_converter/wiki/Usage) | Core functionality |
| 🧰 [Utilities](https://github.com/ArunPrakashG/byte_converter/wiki/Utilities) | Advanced features |
| 🔄 [Upgrading to 3.0](CHANGELOG.md) | Breaking changes and the old → new API table |

---

<div align="center">

**Made with ❤️ for the Dart community**

[⭐ Star on GitHub](https://github.com/ArunPrakashG/byte_converter) · [📦 View on pub.dev](https://pub.dev/packages/byte_converter)

</div>
