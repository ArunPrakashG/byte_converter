---
title: Formatting 🎛️
---
Formatting is powered by the **display namespace** (recommended) or the legacy `toHumanReadable(...)` / `toHumanReadableAuto(...)` methods.

## Namespace API (Recommended)

```dart
final img = ByteConverter.fromMegaBytes(1536); // 1.5 GB

// Auto-scale formatting
img.display.auto();                           // "1.5 GB"
img.display.auto(standard: ByteStandard.iec); // "1.43 GiB"

// Specialized formats
img.display.fuzzy();       // "about 1.5 GB"
img.display.scientific();  // "1.5 × 10⁹ B"
img.display.gnu();           // "1.5G"
img.display.compound();    // "1 GB 536 MB"

// Specific unit
img.display.inUnit(SizeUnit.megaBytes);  // "1536 MB"
```

## ByteFormatOptions

```dart
class ByteFormatOptions {
  const ByteFormatOptions({
    ByteStandard standard = ByteStandard.si,
    bool useBytes = false,
    int precision = 2,
    bool showSpace = true,
    bool nonBreakingSpace = false,
    bool fullForm = false,
    Map<String, String>? fullForms,
    String? separator,
    String? spacer,
    int? minimumFractionDigits,
    int? maximumFractionDigits,
    bool truncate = false,
    bool signed = false,
    String? forceUnit,
    String? locale,              // locale-aware number formatting
    bool useGrouping = true,     // thousands grouping when locale is set
    SiKSymbolCase siKSymbolCase = SiKSymbolCase.upperK, // "KB" vs "kB" for SI
    int? fixedWidth,             // pad numeric portion to at least this width
    bool includeSignInWidth = false, // include sign in fixedWidth calculation
  });
}
```

### Key behaviors

- standard: SI | IEC | JEDEC
- useBytes: false means format using bits ("Mb", "Gi b", etc.)
- precision: decimal rounding if min/max fraction digits are not specified
- minimumFractionDigits / maximumFractionDigits: precise control of fraction digits
- showSpace/spacer: control spacing between number and unit (e.g., "1.5GB" vs "1.5 GB")
- fullForm/fullForms: use full words like "megabytes" and optionally override them
- signed: include "+" or space prefix for alignment
- forceUnit: pin to a specific unit (e.g., "MiB", "MB", "Gb"); disables auto-scaling
- nonBreakingSpace: if true, insert NBSP (\u00A0) between number and unit
- truncate: when using min/max fraction digits, cut off extra digits instead of rounding
- siKSymbolCase: for SI kilo, choose "KB" (default) or "kB"
- fixedWidth: left-pad only the numeric portion to align in tables; unit is unaffected
- includeSignInWidth: when fixedWidth is set and signed=true, count the sign in the width
- locale: locale code for intl-based decimal/grouping formatting (e.g., "de_DE", "fr_FR")
- useGrouping: toggle thousands separators when locale is set (default: true)

### Examples

```dart
final img = ByteConverter.fromMegaBytes(1536);

// Auto-scale SI
img.toHumanReadableAuto();

// IEC with full form
img.toHumanReadableAuto(
  standard: ByteStandard.iec,
  fullForm: true,
); // e.g., "1.5 gibibytes"

// Locale-ish: comma decimal separator and min/max digits
img.toHumanReadableAuto(
  separator: ',',
  minimumFractionDigits: 1,
  maximumFractionDigits: 1,
);

// Force unit to MB regardless of value
img.toHumanReadableAuto(forceUnit: 'MB');
```

### Spaces, NBSP, and truncation

```dart
// Non-breaking space (NBSP) between number and unit
ByteConverter(2048).toHumanReadableAuto(nonBreakingSpace: true); // e.g., "2.05\u00A0KB"

// Truncate vs rounding when using min/max fraction digits
ByteConverter(1550).toHumanReadableAuto(minimumFractionDigits: 1, maximumFractionDigits: 1); // 1.6 KB
ByteConverter(1550).toHumanReadableAuto(minimumFractionDigits: 1, maximumFractionDigits: 1, truncate: true); // 1.5 KB
```

### SI k-case styling

```dart
// Default renders "KB"; opt into "kB" via:
ByteConverter(1500).toHumanReadableAuto(siKSymbolCase: SiKSymbolCase.lowerK); // 1.5 kB
```

### Fixed width alignment

```dart
// Pad the numeric portion with spaces for alignment in tables/CLIs
ByteConverter(1500).toHumanReadableAuto(forceUnit: 'KB', fixedWidth: 6); // "   1.5 KB"

// Signed alignment: include the sign in the width calculation
ByteConverter(1500).toHumanReadableAuto(
  forceUnit: 'KB',
  fixedWidth: 6,
  signed: true,
  includeSignInWidth: true,
); // "  +1.5 KB" (sign + number padded to width 6)
```

### Pattern formatting

- Tokens:
  - `u`: unit symbol (e.g., KB, MiB, Mb)
  - `U`: full unit words (localized when available)
  - `S`: sign character ('+', '-', or space when signed=true; empty when signed=false)
- Numeric placeholder: any token matching `0[#0.,]*` is replaced with the numeric text.

```dart
ByteConverter(1500).formatWith('0.0 u'); // "1.5 KB"
ByteConverter(1500).formatWith('0 U', options: const ByteFormatOptions(fullForm: true)); // e.g., "1 kilobytes"
ByteConverter(1500).formatWith('0000 u', options: const ByteFormatOptions(forceUnit: 'KB', fixedWidth: 4)); // zero-padded pattern is ignored; fixedWidth controls padding
// Explicit sign with pattern token 'S'
ByteConverter(1500).formatWith('S0.0 u', options: const ByteFormatOptions(signed: true)); // "+1.5 KB"
```

## Fast formatting (ultra-low overhead)

When you only need the fastest possible string for common cases, use the public fast API. These functions bypass advanced features (locale, grouping, NBSP, fullForm, fixedWidth, signed) and take the shortest path.

Constraints:

- SI bytes: units B, KB, MB, GB, TB, PB
- IEC bytes: units B, KiB, MiB, GiB, TiB, PiB
- SI bits: units b, Kb, Mb, Gb, Tb
- Precision controls decimal places; trailing zeros and decimal point are trimmed

```dart
import 'package:byte_converter/byte_converter.dart';

void main() {
  // SI bytes (fastest path)
  print(fastHumanizeSiBytes(123456789));      // e.g., "123.5 MB"
  print(fastHumanizeSiBytes(1024, precision: 0)); // "1 KB"

  // IEC bytes (fastest path)
  print(fastHumanizeIecBytes(123456789));     // e.g., "117.7 MiB"

  // SI bits (fastest path)
  print(fastHumanizeSiBits(123456789));       // e.g., "987.7 Mb"
}
```

Use these when you want microsecond-level throughput and don’t need features like locale-aware grouping or full-word units. For everything else, prefer `toHumanReadableAuto(...)` which supports the full option set.

### Performance tips

- If your workloads frequently pin a unit (forceUnit), e.g., always `GB` for sizes or `Mb` for rates, you’ll benefit from the micro fast-paths for forced units in the formatter. Keep options simple (no locale/fullForm/fixedWidth) and pass the exact symbol you want (e.g., `KB` for JEDEC, `KiB` for IEC) to hit the lowest-overhead branch.

## Locale-aware formatting (NEW in 2.3.0)

Enable locale-aware number formatting using the optional `byte_converter_intl.dart` entry:

```dart
import 'package:byte_converter/byte_converter.dart';
import 'package:byte_converter/byte_converter_intl.dart';

void main() {
  // Enable locale-aware formatting
  enableByteConverterIntl();

  final size = ByteConverter(123456789);

  // German locale: decimal comma + grouping
  print(size.toHumanReadableAuto(
    locale: 'de_DE',
    forceUnit: 'MB',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  )); // Output: 123,46 MB

  // French locale with full-form units
  final small = ByteConverter(2000);
  print(small.toHumanReadableAuto(
    locale: 'fr_FR',
    fullForm: true,
    forceUnit: 'KB',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  )); // Output: 2 kilooctets

  // Disable grouping
  final big = ByteConverter(9876543210);
  print(big.toHumanReadableAuto(
    locale: 'en_US',
    forceUnit: 'B',
    useGrouping: false,
  )); // Output: 9876543210 B

  // Disable when not needed
  disableByteConverterIntl();
}
```

### Lightweight number formatter (no-intl)

If you don't want to pull in the `intl` package, you can opt into a tiny adapter that supports a small set of locales with correct decimal/grouping separators. It does not handle currency or advanced locale rules, but it's enough for humanized byte strings.

```dart
import 'package:byte_converter/byte_converter_lite.dart';

void main() {
  enableByteConverterLite();

  final size = ByteConverter(12345678);

  // English: dot decimal, comma grouping (force bytes to see grouping clearly)
  print(size.toHumanReadableAuto(
    locale: 'en',
    forceUnit: 'B',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
    useGrouping: true,
  )); // e.g., "12,345,678 B"

  // German: comma decimal, dot grouping
  print(size.toHumanReadableAuto(
    locale: 'de-DE',
    precision: 2,
  )); // e.g., "12,35 MB"

  // French: comma decimal, space grouping
  print(size.toHumanReadableAuto(
    locale: 'fr',
    forceUnit: 'B',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  )); // e.g., "12 345 678 B"

  disableByteConverterLite();
}
```

Supported base locales: `en`, `de`, `fr`, `es`, `pt`, `ja`, `zh`, `ru`. Unknown locales fall back to English.

Notes:

- Honors `minimumFractionDigits` / `maximumFractionDigits` and `useGrouping`.
- When `locale` is not supplied, default ASCII formatting is used.
- This adapter only affects number formatting; unit names still use the localized unit-name maps and `fullForm` behavior.

### Built-in localized unit names

Three locales ship by default:

- **en**: English (kilobytes, megabytes, etc.)
- **de**: German (Kilobyte, Megabyte, etc.)
- **fr**: French (kilooctets, mégaoctets, etc.)

### Custom unit name translations

```dart
import 'package:byte_converter/byte_converter.dart';

// Register custom translations for Spanish
registerLocalizedUnitNames('es', {
  'KB': 'kilobytes-es',
  'MB': 'megabytes-es',
  'kb': 'kilobits-es',
  'mb': 'megabits-es',
});

// Use with fullForm
final size = ByteConverter(1024);
print(size.toHumanReadableAuto(
  locale: 'es_ES',
  fullForm: true,
  forceUnit: 'KB',
)); // Output: 1 kilobytes-es

// Clear custom translations when done
clearLocalizedUnitNames('es');
```
