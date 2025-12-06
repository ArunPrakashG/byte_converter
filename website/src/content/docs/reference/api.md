---
title: API Reference 📚
---
This summarizes the primary surface area. For full details, see code and tests.

## Import Options

| Import                     | Contents                                                                                     |
| -------------------------- | -------------------------------------------------------------------------------------------- |
| `byte_converter.dart`      | Core: `ByteConverter`, `DataRate`, `BigByteConverter`, namespaces, extensions                |
| `byte_converter_full.dart` | All: `ByteStats`, `TDigest`, `StreamInstrumentation`, `InteropAdapters`, `FormatterSnapshot` |
| `byte_converter_intl.dart` | Localization with `intl` package                                                             |
| `byte_converter_lite.dart` | Lightweight, no `intl` dependency                                                            |

## Namespaces (Recommended API)

```dart
final size = ByteConverter.fromGigaBytes(1.5);

size.display      // ByteDisplayOptions - auto(), fuzzy(), scientific(), gnu(), compound()
size.storage      // StorageNamespace - sectors, blocks, roundToSector(), roundToProfile()
size.rate         // NetworkRate - bitsPerSecond, transferTime(), downloadTime()
size.compare      // ByteComparison - percentOf(), percentageBar(), ratio(), clamp()
size.accessibility // ByteAccessibility - screenReader(), ariaLabel
size.output       // ByteOutputFormats - asMap, asJson(), asArray
size.bitOps       // BitOperations - totalBits, isPowerOfTwo, isAlignedTo(), alignTo(), alignDownTo(), toHexString()
```

## Enums

- `SizeUnit { PB, TB, GB, MB, KB, B }`
- `BigSizeUnit { YB, ZB, EB, PB, TB, GB, MB, KB, B }`
- `ByteStandard { si, iec, jedec }`
- `ByteRoundingMode { floor, ceil, round, halfUp, halfDown, halfEven, truncate }`

## ByteConverter

- Constructors:
  - `ByteConverter(double bytes)`
  - `ByteConverter.withBits(int bits)`
  - `fromKiloBytes(double)`, `fromMegaBytes(double)`, … up to `fromPetaBytes`
  - Binary: `fromKibiBytes(double)`, `fromMebiBytes(double)`, … up to `fromPebiBytes`
- Getters and ops:
  - `bytes -> double`, `asBytes({precision=2}) -> num`, `bits -> int`
  - SI getters: `kiloBytes`, `megaBytes`, `gigaBytes`, `teraBytes`, `petaBytes`
  - IEC getters: `kibiBytes`, `mebiBytes`, `gibiBytes`, `tebiBytes`, `pebiBytes`
  - `+`, `-`, `*`, `/`, comparisons, `compareTo`
  - Rounding: `roundToSector|Block|Page|Word`
  - Storage profiles : `roundToProfile(StorageProfile, {alignment, rounding})`, `alignmentSlack(...)`, `isAligned(...)`
  - Time: `transferTimeAt(bitsPerSecond)`, `downloadTimeAt(bytesPerSecond)`
- Formatting:
  - `toHumanReadable(SizeUnit unit, {precision})`
  - `toHumanReadableAuto({...})` and `toHumanReadableAutoWith(ByteFormatOptions)`
- Parsing:
  - `static parse(String input, {standard = ByteStandard.si})`
  - `static tryParse(String input, {standard}) -> ParseResult<ByteConverter>` (NEW in 2.3.0)
  - Composite expressions supported: `+`, `-`, `*`, `/`, parentheses, and duration tokens

## BigByteConverter

- Constructors for SI and IEC units up to YB/YiB
- Getters: exact BigInt and double convenience variants
- Ops: `+`, `-`, `*`, `~/`, comparisons, rounding and `compareTo`
- Storage profiles : `roundToProfile(StorageProfile, {alignment, rounding})`, `alignmentSlack(...)`, `isAligned(...)`
- Formatting: `toHumanReadable(BigSizeUnit)`, `toHumanReadableAuto({...})`
- Parsing:
  - `static parse(String, {standard, rounding})`
  - `static tryParse(String, {standard, rounding}) -> ParseResult<BigByteConverter>` (NEW in 2.3.0)
  - Composite expressions supported for large units
- Interop: `toByteConverter()`, `fromByteConverter(ByteConverter)`

## DataRate

- Constructors: bits/bytes per second in SI and IEC
- `bitsPerSecond`, `bytesPerSecond`, `transferTimeForBytes(bytes)`
- Window estimates : `transferableBytes(Duration window) -> ByteConverter`
- `toHumanReadableAuto({...})`, `toHumanReadableAutoWith(ByteFormatOptions)`
- Parsing:
  - `static parse(String input, {standard})`
  - `static tryParse(String input, {standard}) -> ParseResult<DataRate>` (NEW in 2.3.0)
  - Composite expressions with size/duration math supported

## BigDataRate

- Constructors mirror `DataRate` but accept `BigInt` for exact throughput: `bitsPerSecond`, `bytesPerSecond`, decimal (`kiloBitsPerSecond`, …) and IEC (`kibiBitsPerSecond`, …).
- Properties: `bitsPerSecond`, `bytesPerSecond`, `bytesPerSecondExact`.
- Helpers: `transferableBytes(Duration window) -> BigByteConverter`, `toDataRate()` for interoperability.
- Formatting: `toHumanReadableAuto({...})`.
- Parsing:
  - `static parse(String input, {standard, rounding})`
  - `static tryParse(String input, {standard, rounding}) -> ParseResult<BigDataRate>`

## TransferPlan

- Constructor: `TransferPlan({required ByteConverter totalBytes, required DataRate rate, ByteConverter? transferredBytes, Duration? elapsed})`.
- Properties: `totalBytes`, `rate`, `transferredBytes`, `elapsed`, `progressFraction`, `percentComplete`, `remainingBytes`, `estimatedTotalDuration`, `remainingDuration`, `etaString({pending, done})`.
- Methods: `copyWith(...)` for immutable updates.
- Extensions:
  - `ByteConverter.estimateTransfer(DataRate rate, {Duration? elapsed, ByteConverter? transferredBytes})`.
  - `DataRate.transferableBytes(Duration window) -> ByteConverter`.
  - `BigDataRate.transferableBytes(Duration window) -> BigByteConverter`.

## StorageProfile

- `StorageProfile({required List<StorageAlignment> alignments, String? defaultAlignment, RoundingMode defaultRounding = RoundingMode.ceil})`.
- `StorageAlignment({required String name, required int blockSizeBytes, RoundingMode? rounding})`.
- API: `alignmentNames`, `defaultAlignment`, `hasAlignment(name)`, `resolve(name)`, `blockSizeBytes([name])`, `roundingFor({alignment, override})`.
- Consumed by `ByteConverter` / `BigByteConverter` via `roundToProfile`, `alignmentSlack`, and `isAligned`.

## ByteStats & BigByteStats

- `ByteStats.sum(Iterable<Object?> values) -> double`
- `ByteStats.average(Iterable<Object?> values) -> double`
- `ByteStats.percentile(Iterable<Object?> values, double percentile) -> double`
- `ByteStats.histogram(Iterable<Object?> values, {required List<double> buckets}) -> Histogram` with `HistogramBucket { double? upperBound, int count }` and `totalCount`.
- `BigByteStats` mirrors the API but operates on `BigInt`, returning `BigInt` sums and `BigHistogram` buckets.

## FormatterSnapshot

- Constructors: `FormatterSnapshot.size({required Iterable<double> sizeSamples, required Iterable<ByteFormatOptions> options, String Function(double)? sampleLabeler, String Function(ByteFormatOptions)? optionLabeler})` and `FormatterSnapshot.rate({required Iterable<DataRate> rateSamples, required Iterable<ByteFormatOptions> options, String Function(DataRate)? sampleLabeler, String Function(ByteFormatOptions)? optionLabeler})`.
- Methods: `buildMatrix() -> List<List<String>>`, `toMarkdownTable({bool includeHeader = true})`, `toCsv({String delimiter = ',', bool includeHeader = true})`.

## Utilities

- `parseByteSizeAuto(...) -> ParsedByteSize` with `ParsedNormal` and `ParsedBig`
- `ByteFormatOptions` shared by sizes/rates formatters (includes `locale` and `useGrouping` in 2.3.0)
- `ByteFormatOptions.per` for rate time base ('s', 'ms', 'min', 'h')
- `NetworkOverhead.typicalFractionEthernetIpv4Tcp({int mtu = 1500}) -> double` — preset overhead fraction (~5.13% at MTU 1500)
- `NetworkOverhead.effectiveRateEthernetIpv4Tcp(DataRate nominal, {int mtu = 1500}) -> DataRate` — preset effective payload rate
- `ParseResult<T>` for non-throwing parse diagnostics (NEW in 2.3.0):
  - Properties: `isSuccess`, `value`, `originalInput`, `normalizedInput`, `detectedUnit`, `isBitInput`, `parsedNumber`, `error`
  - `ParseError` with `message`, `position`, `exception`

### Pluralization (NEW)

- `BytePluralization.format(num value, String unit, {PluralizationOptions options, String? plural}) -> String` — smart pluralization with locale-aware rules
- `BytePluralization.unitFor(num value, String unit, {PluralizationOptions options}) -> String` — returns the correctly pluralized unit name
- `BytePluralization.pluralize(String word) -> String` — basic pluralization (e.g., "byte" → "bytes")
- Extensions: `int.withUnit('byte')`, `double.withUnit('megabyte', precision: 1)`

See [Utilities](/guides/utilities/) → Pluralization for examples and supported locales.

### Fast formatting helpers

Public fast-path formatters with minimal overhead for the most common scenarios. These bypass advanced features like locale, grouping, NBSP, fullForm, fixed width, or signs.

- `fastHumanizeSiBytes(double bytes, {int precision = 2}) -> String`  
  Units: B, KB, MB, GB, TB, PB

- `fastHumanizeIecBytes(double bytes, {int precision = 2}) -> String`  
  Units: B, KiB, MiB, GiB, TiB, PiB

- `fastHumanizeSiBits(double bytes, {int precision = 2}) -> String`  
  Units: b, Kb, Mb, Gb, Tb

- `fastHumanizeSiRateBytesPerSecond(double bytesPerSecond, {int precision = 2, String per = 's'}) -> String`  
  Units: B/s, KB/s, MB/s, GB/s, TB/s; time base via `per` = 's'|'ms'|'min'|'h'

- `fastHumanizeSiRateBitsPerSecond(double bitsPerSecond, {int precision = 2, String per = 's'}) -> String`  
  Units: b/s, Kb/s, Mb/s, Gb/s, Tb/s; time base via `per` = 's'|'ms'|'min'|'h'

### Streaming quantiles

- Factories:
  - `StreamingQuantiles(List<double> quantiles)` — default P² estimator (low memory, fast; good for a few quantiles on mostly stationary data)
  - `StreamingQuantiles.tDigest({int compression = 200})` — TDigest estimator (better tail behavior and multi-quantile accuracy; slightly higher overhead)
- Methods:
  - `add(Object? value)` — stream values (supports `double`, `num`, `ByteConverter`, `BigByteConverter`, `BigInt` via conversion)
  - `estimate(double percentile)` — percentile in 0..100
- Tradeoffs:
  - P² uses 5-marker updates per target quantile; tiny footprint, fastest
  - TDigest maintains compressed centroids and interpolates; more accurate in tails and across many quantiles

### Interop adapters

- `OSParsingModes.parseLinuxHuman(String input) -> ParseResult<ByteConverter>`
- `OSParsingModes.parseWindowsShort(String input) -> ParseResult<ByteConverter>`

## Localization helpers (NEW in 2.3.0)
## Network Overhead (NEW)

Helpers for modeling protocol/link overhead and computing payload throughput:

- `NetworkOverhead.fractionForPacket({ required int payloadBytes, int l2Bytes = 18, int l3Bytes = 20, int l4Bytes = 20, int preambleBytes = 8, int interframeGapBytes = 12 }) -> double`
  - Returns fraction in [0,1] for overhead/(overhead+payload)
  - Defaults approximate Ethernet + IPv4 + TCP base headers and wire overhead

- `NetworkOverhead.effectiveRate(DataRate nominal, { double overheadFraction = 0.0 }) -> DataRate`
  - Applies simple overhead fraction to obtain payload rate

- `NetworkOverhead.effectiveRateForPacket(DataRate nominal, { int mtu = 1500, ... }) -> DataRate`
  - Estimates payload rate using packet-level model (assumes full-size packets)

- `TransferPlan.estimatedTotalDurationWithOverhead(double overheadFraction) -> Duration?`
- `TransferPlan.remainingDurationWithOverhead(double overheadFraction) -> Duration?`
  - Overhead-aware ETA helpers

See [Utilities](/guides/utilities/) → Network Overhead for examples.
## Time & Number Helpers

- Relative time formatting:
  - `RelativeTime.format(Duration) -> String` — e.g., "2 hours"
  - `RelativeTime.formatAgo(Duration) -> String` — e.g., "2 hours ago"
  - `RelativeTime.formatFromNow(Duration) -> String` — e.g., "in 2 hours"
  - Extensions on `Duration` and `DateTime`: `.ago`, `.fromNow`, `.relative`, `.humanRelative`, `.asCountdown`

- Natural time delta:
  - `NaturalTimeDelta(Duration).natural|precise|short|countdown` — friendly descriptions like "about 5 minutes"
  - Extension: `Duration.natural`, `Duration.naturalPrecise`, `Duration.naturalShort`, `Duration.countdown`

- SI number formatting:
  - `SINumber.humanize(num, {precision=2, unit='', space=false}) -> String` — e.g., `1500000` → "1.5M"
  - `SINumber.humanizeFull(num) -> String` — e.g., "1.5 mega"
  - `SINumber.engineering(num, {precision=2}) -> String` — e.g., "1.5 × 10³"
  - `SINumber.parse(String) -> double?` — e.g., "1.5M" → `1500000.0`
  - Extensions on `num`: `.si`, `.toSI(...)`, `.engineering`

- Ordinal numbers:
  - `ByteOrdinal.format(int) -> String` — e.g., `21` → "21st"
  - `ByteOrdinal.getSuffix(int) -> String` — e.g., `42` → "nd"
  - `ByteOrdinal.toWords(int) -> String` — e.g., `1` → "first"
  - Extensions on `int`: `.ordinal`, `.ordinalSuffix`, `.ordinalWords`

## Negative Values & Deltas

- `NegativeByteFormatter.format(double bytes, {NegativeValueOptions options, int decimals=2}) -> String` — display styles for decreases/increases
- `NegativeByteFormatter.formatDelta(SizeDelta, {NegativeValueOptions options, int decimals=2}) -> String`
- `NegativeByteFormatter.formatComparison(double fromBytes, double toBytes, {int decimals=2, bool showPercentage=true}) -> String`
- `NegativeByteFormatter.formatWithArrow(double bytes, {int decimals=2}) -> String` — "↑ 488.28 KB" / "↓ 488.28 KB"
- `NegativeValueOptions` presets: `defaults`, `parentheses`, `verbose`, `delta`
- `SizeDelta(from, to)` with helpers: `difference`, `absoluteDifference`, `isIncrease|isDecrease|isUnchanged`, `percentageChange`, `percentageChangeFormatted`, `format()`
- Extensions on `ByteConverter` and `BigByteConverter`: `.deltaTo(...)`, `.deltaFrom(...)`, `.formatSigned(showPlus: true)`

See [Utilities](/guides/utilities/) → Negative Values for detailed examples.

From `byte_converter_intl.dart`:

- `enableByteConverterIntl()` - Enable locale-aware number formatting
- `disableByteConverterIntl()` - Disable locale-aware formatting

From `byte_converter.dart`:

- `registerLocalizedUnitNames(String locale, Map<String, String> names)` - Register custom unit translations
- `clearLocalizedUnitNames(String locale)` - Clear custom translations
- `localizedUnitName(String symbol, {String? locale})` - Look up localized unit name
- `resolveLocalizedUnitSymbol(String token, {String? locale})` - Reverse map localized tokens to canonical unit symbols
- `disableDefaultLocalizedUnitNames()` / `enableDefaultLocalizedUnitNames()` - Tree-shakable toggles for built-in localized names
