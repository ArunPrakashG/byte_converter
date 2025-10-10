# Enhancement Roadmap

This document tracks the high-level plan for upcoming improvements to `byte_converter`. Each section summarizes the feature objective, motivation, scope, design notes, and first implementation steps.

## 1. Non-throwing parse APIs with diagnostics

- **Goal:** Provide `tryParse`-style methods that surface detailed success/failure info instead of throwing exceptions.
- **Motivation:** Improve resilience for UI forms, CLIs, and services that need graceful validation feedback.
- **Scope:**
  - Add `ByteConverter.tryParse`, `BigByteConverter.tryParse`, and `DataRate.tryParse` returning a result object with flags for `isSuccess`, `value`, `normalizedInput`, `detectedUnit`, and error metadata.
  - Factor shared parsing logic in `_parsing.dart` to expose reusable diagnostics.
  - Update tests to cover success and failure paths.
- **First steps:** Design `ParseResult<T>` sealed class, refactor parsing helpers to populate it, create unit tests mirroring existing throwing scenarios.

## 2. Locale-aware formatting via `intl`

- **Goal:** Offer opt-in locale-aware formatting using the `intl` package when available.
- **Motivation:** Developers serving localized UIs need proper thousands separators, decimal symbols, and pluralization for unit names.
- **Scope:**
  - Integrate `NumberFormat.decimalPattern` into the humanize pipeline when `ByteFormatOptions.locale` (or method parameter) is supplied.
  - Support toggling thousands grouping via `useGrouping`, with safe fallback to legacy formatting if locale data is missing.
  - Investigate localized unit name maps (pending).
  - Document usage patterns so consumers understand the optional dependency footprint.
- **Status:** Locale-aware number formatting, grouping toggle, default localized unit maps (en/de/fr), and an opt-in `byte_converter_intl.dart` entry (with tests) are implemented.
- **Next steps:** Expand locale coverage, explore richer pluralization for unit names, and investigate tree-shake-friendly packaging for the intl adapter.

## 3. Transfer planning helpers

- **Goal:** Simplify duration/throughput calculations between `ByteConverter` and `DataRate`.
- **Motivation:** Common workflows (download estimates, remaining time) deserve reusable abstractions.
- **Scope:**
  - Introduce `TransferPlan` class representing total bytes, rate, elapsed time, and progress metrics.
  - Provide helpers like `ByteConverter.estimateTransfer(DataRate rate)` and `DataRate.transferableBytes(Duration window)`.
  - Include convenience methods for percent complete, remaining duration, and ETA formatting.
- **First steps:** Define `TransferPlan` API, reuse existing `downloadTimeAt` implementations, add unit tests with deterministic scenarios.

## 4. Custom storage profile rounding

- **Goal:** Generalize alignment helpers (sector/block/page) to user-defined storage profiles.
- **Motivation:** Different storage systems (e.g., SSDs, database pages) require flexible alignment sizes.
- **Scope:**
  - Create a `StorageProfile` object capturing block sizes and rounding strategy (floor/ceil/round).
  - Add methods (`roundToProfile`, `alignmentSlack`, `isAligned`) for both `ByteConverter` and `BigByteConverter`.
  - Update documentation with examples for common hardware profiles.
- **First steps:** Draft profile interface, implement rounding logic using existing helpers as reference, cover edge cases in tests.

## 5. Aggregate and analytics utilities

- **Goal:** Provide collection helpers for aggregating byte sizes.
- **Motivation:** Consumers frequently need totals, averages, clamps, and histogram buckets without bespoke loops.
- **Scope:**
  - Add static utilities (`ByteStats.sum`, `ByteStats.average`, `ByteStats.percentile`, `ByteStats.histogram`).
  - Support both `ByteConverter` and numeric inputs.
  - Ensure BigInt-aware variants (`BigByteStats`) where precision matters.
- **First steps:** Define utility API, implement using iterables, add tests covering empty collections, mixed units, and precision handling.

## 6. High-precision data rates (`BigDataRate`)

- **Goal:** Mirror `BigByteConverter` for throughput calculations using `BigInt`.
- **Motivation:** Enables exact planning for ultra-high bandwidth systems and scientific workloads.
- **Scope:**
  - Implement `BigDataRate` storing bits-per-second as `BigInt` with named constructors and conversions.
  - Provide interoperability with existing `DataRate` (to/from conversions).
  - Extend formatting/parsing so `BigDataRate` can reuse humanize logic.
- **First steps:** Define core class, reuse `_parsing.dart` big helpers, ensure rounding options align with `BigByteConverter`, write comprehensive tests.

## 7. Composite expression parsing

- **Goal:** Allow expressions like `"1 GB + 512 MB"` or `"2 GiB/5s"` to be parsed into concrete sizes/rates.
- **Motivation:** Streamline scripting, config files, and power-user scenarios requiring inline arithmetic.
- **Scope:**
  - Extend `_parsing.dart` with a small expression grammar supporting +, -, \*, /, parentheses, and duration tokens.
  - Return structured results (size or rate) with error diagnostics.
  - Guard against recursion depth and invalid syntax.
- **First steps:** Design expression AST, integrate with existing normalization, add tests for happy/edge/error paths.

## 8. Snapshot matrix utilities

- **Goal:** Promote the snapshot testing patterns into reusable tooling.
- **Motivation:** Maintain consistent formatting across versions and make it easy to document behavior.
- **Scope:**
  - Expose a `FormatterSnapshot` helper that generates matrices for sizes and rates with configurable samples/options.
  - Allow exporting to Markdown/CSV for docs.
  - Use in tests to compare against stored snapshots for regression detection.
- **First steps:** Abstract matrices from `snapshot_matrix_test.dart`, design a portable output API, add documentation and sample usage in the wiki.
