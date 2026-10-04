# Changelog

## 3.0.0 - 2026-10-04

Fixes for several real formatting/parsing bugs, a much smaller dependency and API surface, and CI. Read **Breaking changes** before upgrading.

### Breaking changes
- **No more `intl` dependency.** `package:byte_converter/byte_converter_intl.dart` (`enableByteConverterIntl` / `disableByteConverterIntl`) is removed; the package now has zero runtime dependencies (this also ends the version clash with `flutter_localizations`, which pins `intl`). The hook it used is public in the core import: `registerHumanizeNumberFormatter(...)` / `clearHumanizeNumberFormatter()` with `HumanizeOptions`. A 10-line `intl` recipe is in the docs (Formatting → Locale-aware formatting) and is covered by `test/intl_recipe_test.dart`. `byte_converter_lite.dart` still gives built-in separators for en, de, fr, es, pt, ja, zh, ru.
  - Compound formatting (`display.compound`) no longer calls `intl` either: with a locale it uses the registered formatter (e.g. lite), otherwise English `1,234` grouping.
- **Removed deprecated `ByteConverter` members** (all were marked "removed in v3.0.0"):

  | Removed | Use instead |
  |---|---|
  | `sectors`, `blocks`, `pages`, `words`, `isWhole*`, `roundTo{Sector,Block,Page,Word}`, `roundToProfile`, `alignmentSlack`, `isAligned` | `size.storage.…` |
  | `bitsPerSecond`, `kiloBitsPerSecond`, `megaBitsPerSecond`, `gigaBitsPerSecond`, `transferTimeAt`, `downloadTimeAt` | `size.rate.…` |
  | `toHumanReadable(unit)` | `size.display.inUnit(unit)` |
  | `toHumanReadableAuto(...)` | `size.display.auto(...)` |
  | `toHumanReadableAutoWith(options)` | `size.display.format(options)` |
  | `toHumanReadableCompound(...)` | `size.display.compound(...)` |
  | `formatWith(pattern, ...)` | `size.display.pattern(pattern, ...)` |
  | `toFullWords(...)` | `size.display.auto(fullForm: true)` / `size.display.fullWords()` |
  | `largestWholeNumber(...)` | `size.output.largestWholeNumber()` / `size.outputWith(standard).largestWholeNumber()` (new) |

  `DataRate`, `BigByteConverter` and `BigDataRate` keep their own `toHumanReadableAuto` etc.
- **Smaller core import.** `bit_operations`, `BandwidthAccumulator`, byte constants, rounding helpers, negative-value/delta formatting and `ByteValidation` moved from `byte_converter.dart` to `byte_converter_full.dart`.
- **Removed non-byte utilities:** `RelativeTime`, `NaturalTimeDelta`, `SINumber`, `ByteOrdinal` and their `Duration`/`DateTime`/`num`/`int` extensions. They formatted times and plain numbers, not byte quantities.
- `ByteConverter(double.nan)` / `infinity` now throw `ArgumentError`.
- English `fullForm` output uses singular names for exactly one unit (`1 byte`, `1 kilobyte`; was `1 bytes`).
- `1,234` (a single comma followed by exactly three digits) now parses as 1234, and repeated separators (`1,234,567`, `1.234.567`) are grouping. `1,5` and `1.234` keep their previous decimal reading.

### Fixed
- **Rounding at unit boundaries:** values that round up to the unit ratio are promoted to the next unit. `ByteConverter(999999)` formats as `1 MB` (was `1000 KB`) for SI, IEC, JEDEC and bit output.
- **IEC beyond TiB:** `1 PiB` printed `1024 TiB`; `BigByteConverter` IEC values up to `YiB` format correctly.
- `ByteConverter.toString()` scales up to quettabytes instead of capping at `PB`.
- `ByteConverter.fromJson` accepts integers and numeric strings (it threw a `TypeError` on `{"bytes": 1024}`).
- Equality, ordering and `hashCode` stay correct beyond ~1.15 EB (the bit count saturated, so `1e19 == 2e19`).
- Parsing: `1 KiB` / `1 kibibyte` work under the default standard (also `1 KiB/s`); short bit forms `Mbit`, `kbits`, `Gibit` are accepted.
- Doc comments referenced constructors that don't exist (`fromMB`, `fromGB`, `fromKB`) and showed methods as properties; README outputs corrected.

### Added
- `size.output.largestWholeNumber({useBytes})` (the replacement the old deprecation note promised, which did not exist).
- `SiKSymbolCase`, `UnitPolicy`, `FormattingRoundingMode`, `HumanizeOptions`, `HumanizeNumberFormatter` and the register/clear functions are exported from `byte_converter.dart`.
- GitHub Actions: CI (format, analyze, VM + Chrome tests, publish dry-run, Flutter resolution check) and tag-triggered publishing (`v3.0.0`).
- `.pubignore` keeps the wiki, website and tooling out of the published archive.

### Internal
- The four humanize fast paths share one table-driven scaler; a test asserts fast and general paths agree.
- `library` directives are unnamed; `lints` bumped to `^6.0.0`; test files renamed by area.

---

## 2.6.0 - 2025-12-06

### 🚀 Major Features

#### New Utilities & Namespaces
- **Byte Division** (`ByteDivisionNamespace`): Split and distribute bytes
  - `split(chunkSize)` - Divide bytes into chunks
  - `distribute(numParts)` - Evenly distribute across parts
  - `modulo(boundary)` - Calculate remainder
  - `paddingTo(boundary)` - Calculate padding needed
  
- **Bit Operations** (`BitOperationsNamespace`): Low-level bit manipulation
  - CPU Cache line alignment (L1/L2/L3)
  - Byte alignment helpers
  - Binary operations and utilities
  
- **Network Overhead** utilities for calculating protocol overhead
- **Byte Pluralization** with locale-aware rules
- **Natural Time Delta** for human-readable time differences
- **Ordinal Numbers** for ranking and positioning
- **SI Number Formatting** for scientific notation
- **Storage Alignment** for filesystem operations

#### Advanced Features
- **BandwidthAccumulator**: Track and analyze bandwidth usage over time
- **ByteAccessibility**: Screen reader and accessibility support
- **ByteComparison**: Rich comparison utilities
- **ByteValidation**: Input validation helpers
- **NegativeValue**: Handle negative byte values
- **RelativeTime**: Format relative timestamps

#### Parsing Enhancements
- **Forced humanization parsing**: Parse ambiguous formats
- **Expression parsing**: Evaluate arithmetic expressions like "10MB + 5GB"
- **Duration parsing**: Convert time durations to data sizes
- Improved error messages and edge case handling

### 🧪 Testing
- 200+ new test cases for namespaces and utilities
- Comprehensive coverage for BandwidthAccumulator
- Tests for all display options and output formats
- Edge case validation across all features
- Performance benchmarks for new features

### 🎨 Developer Experience
- Better IDE autocomplete with namespace organization
- Improved error messages with actionable hints
- Consistent API patterns across all features
- Zero breaking changes - fully backward compatible

### 📦 Package Structure
- `byte_converter.dart` - Core functionality (recommended)
- `byte_converter_full.dart` - All features including statistics
- `byte_converter_intl.dart` - With intl localization
- `byte_converter_lite.dart` - Minimal without dependencies

### Migration Notes
- All existing code continues to work without changes
- New namespace APIs provide better organization
- Consider migrating from deprecated methods to namespaces for future-proofing
- See v2.5.0 changelog for namespace migration guide

---

## 2.5.0

### Added - Namespace-Based API

- **New `storage` namespace**: Access storage alignment utilities via `size.storage.sectors`, `size.storage.blocks`, `size.storage.roundToBlock()`, etc.
- **New `rate` namespace**: Access network rate utilities via `size.rate.bitsPerSecond`, `size.rate.transferTime(dataRate)`, etc.
- **Enhanced `display` namespace**: New methods `auto()`, `compound()`, `inUnit()`, and `pattern()` for formatting
- **New export file**: `byte_converter_full.dart` for users who need all advanced features

### Added - Pluralization Utilities

- **New `BytePluralization` class**: Smart pluralization for byte-related terms
  - `BytePluralization.format(1, 'byte')` → `"1 byte"`
  - `BytePluralization.format(2, 'byte')` → `"2 bytes"`
  - `BytePluralization.format(0, 'byte')` → `"0 bytes"`
- **Locale-aware pluralization**: Support for English, French, Slavic, East Asian, and Arabic rules
  - `BytePluralization.optionsForLocale('fr')` for French rules (0 and 1 are singular)
  - `BytePluralization.ruleForLocale('ja')` → `PluralizationRule.eastAsian` (no plural forms)
- **Extension methods**: Quick pluralization on `int` and `double`
  - `1536.withUnit('byte', useCommas: true)` → `"1,536 bytes"`
  - `1.5.withUnit('megabyte')` → `"1.5 megabytes"`

### Deprecated - Migration to Namespaces

The following methods on `ByteConverter` are now deprecated in favor of namespace-based alternatives:

| Deprecated | Use Instead |
|------------|-------------|
| `sectors`, `blocks`, `pages`, `words` | `storage.sectors`, `storage.blocks`, etc. |
| `isWholeSector`, `isWholeBlock`, etc. | `storage.isWholeSector`, etc. |
| `roundToSector()`, `roundToBlock()`, etc. | `storage.roundToSector()`, etc. |
| `roundToProfile()`, `alignmentSlack()`, `isAligned()` | `storage.roundToProfile()`, etc. |
| `bitsPerSecond`, `kiloBitsPerSecond`, etc. | `rate.bitsPerSecond`, etc. |
| `transferTimeAt()`, `downloadTimeAt()` | `rate.transferTime()`, `rate.transferTimeAt()` |
| `toHumanReadable(unit)` | `display.inUnit(unit)` |
| `toHumanReadableAuto()` | `display.auto()` |
| `toHumanReadableAutoWith(options)` | `display.format(options)` |
| `toHumanReadableCompound()` | `display.compound()` |
| `formatWith(pattern)` | `display.pattern(pattern)` |
| `toFullWords()` | `display.fullWords()` |
| `largestWholeNumber()` | `output.largestWholeNumber()` |

### Migration Example

```dart
// Before (deprecated)
final size = ByteConverter.fromGigaBytes(1.5);
print(size.toHumanReadableAuto(standard: ByteStandard.iec));
print(size.sectors);
print(size.roundToBlock());

// After (recommended)
final size = ByteConverter.fromGigaBytes(1.5);
print(size.display.auto(standard: ByteStandard.iec));
print(size.storage.sectors);
print(size.storage.roundToBlock());
```

### Notes

- All deprecated methods will continue to work in v2.x releases
- Deprecated methods will be removed in v3.0.0
- The namespace-based API provides better organization and discoverability
- No breaking changes - existing code continues to work with deprecation warnings

---

## 2.4.2

### Added / Improved

- Package-wide public API documentation completed and enforced via `public_member_api_docs`.
- Clarified docs across `BigByteConverter`, `ByteConverter`, compound formatting, parse results, storage profiles, and unified parsing types.
- Resolved all analyzer warnings; repository is analyzer-clean.

### Notes

- No functional changes. This is a documentation-only release to improve API discoverability and consistency.

## 2.4.1

### Added / Improved

- Compound mixed-unit formatting (e.g., `toHumanReadableCompound`) now honors `CompoundFormatOptions.useGrouping` and `locale` to render integers with locale-aware thousands separators (via `intl`). This especially improves IEC outputs where counts can exceed 999 (for example, `1,023 MiB`).
- Expanded Dartdoc for compound formatting options and behavior.
- README polish: added a friendly intro/personality, richer examples, and centered the title/badges for a more inviting presentation.

### Notes

- No breaking API changes. This is a visual formatting enhancement only. SI compound counts typically remain below 1000 per part; IEC benefits most from grouping.

## 2.4.0

### Added / Improved

- Fixed-width alignment for the numeric portion via `ByteFormatOptions.fixedWidth` (also supported in `DataRate.toHumanReadableAuto`).
- `includeSignInWidth` option to count the sign when padding with `fixedWidth` for tighter column alignment.
- Pattern formatting token `S` to explicitly render the sign ('+', '-', or space when `signed=true`).
- CLI: `bytec` gains `--fixed-width n` in `format` and `rate` commands; help updated. `rate` also exposes `--per` for choosing time base.
- Docs: expanded formatting guide and data-rate examples to cover NBSP, truncation, SI k-case, fixed width, and pattern `S`.

### Notes

- Default SI kilo symbol remains `KB` for backward compatibility; opt into `kB` using `siKSymbolCase: lowerK` or `--si-lower-k` in CLI.

## 2.3.1

### Fixed

- Size and data-rate parsing now fall back across SI, IEC, and JEDEC symbols so expression evaluation accepts mixed-unit inputs regardless of the selected standard.

## 2.3.0

### Added / Improved

- Transfer planning helpers (`TransferPlan`, `DataRate.transferableBytes`, `BigDataRate.transferableBytes`) with ETAs, remaining payload metrics, and friendly strings.
- Storage alignment profiles that round converters to device-specific blocks and surface slack diagnostics.
- `ByteStats`/`BigByteStats` aggregations for sums, averages, percentiles, and histogram buckets across mixed inputs.
- Composite expression parsing for sizes and rates, including arithmetic operators, parentheses, and duration tokens.
- `FormatterSnapshot` utilities for generating Markdown/CSV matrices reused in documentation and snapshot tests.
- `BigDataRate` for BigInt-precise throughput conversions that interoperate with `DataRate`.
- Built-in localized unit names now include Hindi (hi/hi_IN), Spanish (es), Portuguese (pt), Japanese (ja), Chinese (zh), Russian (ru), and English (en_IN) alongside the existing English, German, and French defaults.
- Locale-aware humanize formatting via new `ByteFormatOptions.locale` and `useGrouping` controls, powered by `intl`.
- Shared humanize pipeline now caches `NumberFormat` instances and gracefully falls back to legacy formatting if locale data is missing.
- Added regression tests covering localized output and grouping toggles for sizes and rates.
- New `byte_converter_intl.dart` opt-in entry enables locale formatting without forcing `intl` on the default import.
- Built-in localized unit-name maps (en, de, fr) plus `registerLocalizedUnitNames`/`clearLocalizedUnitNames` helpers for custom translations.

### Notes

- Requires the `intl` package (already listed in `pubspec.yaml`). Consumers can ignore `byte_converter_intl.dart` to avoid the extra dependency in their build output.

## 2.2.0

### Added / Improved

- Locale-aware parsing for sizes and rates: accepts non‑breaking spaces, underscores, and mixed decimal/group separators (comma/dot) with robust normalization.
- Stricter DataRate parsing with additional IEC/SI synonyms (e.g., KiB/s, kibps) and clear errors for unknown units.
- Internal parsing regexes hardened; number formatting remains trimmed (no trailing zeros).

### Notes

- No breaking API changes. Existing parse and humanization behavior preserved.

## 2.1.0

### Added - BigInt Support

- **BigByteConverter**: New class for arbitrary precision byte calculations using BigInt
- **Extended unit support**: Added Exabytes (EB), Zettabytes (ZB), and Yottabytes (YB) for both decimal and binary units
- **BigInt extensions**: Extensions for BigInt type to create BigByteConverter instances
- **Exact arithmetic methods**: `*Exact` getters that return BigInt values without precision loss
- **Cross-type conversion**: Convert between ByteConverter and BigByteConverter
- **Large-scale JSON serialization**: Support for serializing/deserializing extremely large numbers

### Use Cases for BigInt Support

- Data center storage calculations requiring exact precision
- Scientific computing with massive datasets
- Cryptographic applications where precision is critical
- Blockchain and distributed systems with large data requirements
- Future-proofing for exascale computing scenarios

### API Examples

```dart
// Ultra-precise calculations
final dataCenter = BigByteConverter.fromExaBytes(BigInt.from(5));
final cosmic = BigByteConverter.fromYottaBytes(BigInt.one);

// BigInt extensions
final huge = BigInt.parse('999999999999999999999').bytes;

// Exact arithmetic (no precision loss)
final exact = BigInt.from(1000000000).bytes;
print(exact.gigaBytesExact); // BigInt result
print(exact.gigaBytes);      // double approximation
```

## 2.0.0

### Breaking Changes

- Made ByteConverter class immutable
- Changed static factory methods to named constructors
- Removed deprecated methods
- Updated precision handling for integer values

### Added

- Binary unit support (KiB, MiB, GiB, TiB, PiB)
- Extension methods for fluent API
- JSON serialization support
- Math operations (+, -, \*, /)
- Comparison operators
- Cached calculations for better performance
- `Comparable` interface implementation

### Optimized

- String formatting and caching
- Unit conversion calculations
- Memory usage with lazy initialization
- Binary search for best unit selection
- Precision handling for whole numbers

### Fixed

- Incorrect KB unit display in string output
- Precision handling for integer values
- Memory leaks from repeated calculations
- Unit conversion accuracy
