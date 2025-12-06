---
title: Changelog 📝
---
This wiki summarizes changes. For authoritative release notes, see the repository changelog:

- GitHub: https://github.com/ArunPrakashG/byte_converter/blob/master/CHANGELOG.md

## 2.3.1 (Latest)

### Fixed

- Parsing gracefully falls back across SI, IEC, and JEDEC symbols so expressions with mixed units resolve under any selected standard.

## 2.3.0

### Added / Improved

- **Locale-aware humanize formatting** via new `ByteFormatOptions.locale` and `useGrouping` controls, powered by `intl`
- **Optional `byte_converter_intl.dart` entry** enables locale formatting without forcing `intl` on the default import
- **Built-in localized unit-name maps** (en, de, fr) plus `registerLocalizedUnitNames`/`clearLocalizedUnitNames` helpers for custom translations
- **Non-throwing `tryParse` methods** for `ByteConverter`, `BigByteConverter`, and `DataRate` that return detailed diagnostics
- Shared humanize pipeline now caches `NumberFormat` instances and gracefully falls back to legacy formatting if locale data is missing
- Added comprehensive regression tests covering localized output and grouping toggles for sizes and rates

### Notes

- Requires the `intl` package (already listed in `pubspec.yaml`). Consumers can ignore `byte_converter_intl.dart` to avoid the extra dependency in their build output.

## 2.2.0

- BigInt support enhancements
- Unified parsing improvements
- Advanced formatting options (min/max fraction digits, spacer, signed, forceUnit)
- Locale-friendly number parsing: NBSP, underscores, and mixed decimal/group separators

## 2.1.x

- DataRate improvements and parsing updates
- BigInt support with extended units (EB, ZB, YB)

## 2.0.0

- Dart 3 support
- Public API refinements
- Immutable design with cached calculations

(For the full, accurate history, always refer to the repo CHANGELOG.)
