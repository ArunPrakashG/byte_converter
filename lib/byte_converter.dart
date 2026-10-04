/// Provides a simple interface for conversion of Digital values such as Bytes, KiloBytes etc.
///
/// This is the core export containing essential classes for most use cases.
///
/// **Import Options:**
/// ```dart
/// // Core: sizes, rates, parsing, formatting, display/output/compare/
/// // accessibility/storage/rate namespaces, transfer planning
/// import 'package:byte_converter/byte_converter.dart';
///
/// // Everything above plus statistics, streaming, bit operations,
/// // validation, accumulators, interop and unit-name localization
/// import 'package:byte_converter/byte_converter_full.dart';
///
/// // Built-in locale number formatting (no extra dependency)
/// import 'package:byte_converter/byte_converter_lite.dart';
/// ```
///
/// This package has no runtime dependencies. To format numbers with
/// `package:intl`, register a formatter with [registerHumanizeNumberFormatter].
library;

// ─────────────────────────────────────────────────────────────────────────────
// Core Classes
// ─────────────────────────────────────────────────────────────────────────────

/// BigInt support for exascale+ values
export 'src/big_byte_converter.dart';
export 'src/big_data_rate.dart';

/// Core byte converter class
export 'src/byte_converter_base.dart';

/// Size delta (difference between two sizes)
export 'src/byte_delta.dart';

/// Essential enums (ByteStandard, SizeUnit, RateUnit)
export 'src/byte_enums.dart';

/// Size range (min/max bounds)
export 'src/byte_range.dart';

/// Compound formatting options
export 'src/compound_format.dart' show CompoundFormatOptions;

/// Data rate (bandwidth) handling
export 'src/data_rate.dart';

/// Extensions on int, double for .bytes, .kiloBytes, .megaBytes, etc.
export 'src/extensions.dart';

/// Formatting options for humanized output
export 'src/format_options.dart' show ByteFormatOptions;

/// Pluggable number formatter hook (use it to bring your own i18n, e.g. intl)
export 'src/humanize_number_format.dart';

/// Humanize options (passed to number formatters) and its enums
export 'src/humanize_options.dart'
    show FormattingRoundingMode, HumanizeOptions, SiKSymbolCase, UnitPolicy;

/// Namespace extensions: display, output, compare, accessibility, storage, rate
export 'src/namespaces.dart';

/// Parse result wrapper with diagnostics
export 'src/parse_result.dart';

/// Storage profiles for disk alignment
export 'src/storage_profile.dart';

/// Transfer planning and ETA estimation
export 'src/transfer_plan.dart';

/// Byte division and chunking utilities
export 'src/utilities/byte_division.dart';

/// Smart pluralization for byte-related terms
export 'src/utilities/byte_pluralization.dart';

/// Network overhead estimation utilities
export 'src/utilities/network_overhead.dart';
