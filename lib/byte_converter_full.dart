/// Full byte conversion library with all features.
///
/// This export includes everything from the main [byte_converter] library
/// plus advanced features:
///
/// **Statistics & Quantiles:**
/// - [ByteStats] - Statistical aggregation of byte values
/// - [TDigest] - Streaming quantile estimation
///
/// **Streaming & Instrumentation:**
/// - [StreamInstrumentation] - Stream progress tracking
/// - [BandwidthAccumulator] - Bandwidth monitoring
///
/// **Advanced Formatting:**
/// - [FormatterSnapshot] - Capture formatter state
/// - [CompoundFormatOptions] - Multi-unit formatting
/// - [FastFormat] - Low-level formatting
///
/// **Interoperability:**
/// - [InteropAdapters] - OS-specific parsing adapters
/// - [UnifiedParse] - Cross-standard parsing
///
/// **Localization (basic):**
/// - Unit name registration functions
/// - For full i18n with intl package, use `byte_converter_intl.dart`
///
/// For most use cases, the standard import is sufficient:
/// ```dart
/// import 'package:byte_converter/byte_converter.dart';
/// ```
///
/// Use this full export when you need advanced features:
/// ```dart
/// import 'package:byte_converter/byte_converter_full.dart';
/// ```
library byte_converter_full;

// ─────────────────────────────────────────────────────────────────────────────
// Core Library (everything from byte_converter.dart)
// ─────────────────────────────────────────────────────────────────────────────

export 'byte_converter.dart';

/// Statistical aggregation of byte values (sum, avg, percentiles)
export 'src/byte_stats.dart';

/// Full compound format options
export 'src/compound_format.dart';

/// Low-level fast formatting
export 'src/fast_format.dart';

/// Capture and restore formatter state
export 'src/formatter_snapshot.dart';

/// OS-specific parsing adapters (Linux, macOS, Windows)
export 'src/interop_adapters.dart';

/// Unit name localization functions
export 'src/localized_unit_names.dart'
    show
        registerLocalizedUnitNames,
        clearLocalizedUnitNames,
        localizedUnitName,
        registerLocalizedSynonyms,
        clearLocalizedSynonyms,
        registerLocalizedSingularNames,
        clearLocalizedSingularNames,
        localizedUnitSingularName,
        resolveLocalizedUnitSymbol,
        enableDefaultLocalizedUnitNames,
        disableDefaultLocalizedUnitNames;

/// Stream progress tracking and callbacks
export 'src/stream_instrumentation.dart';

/// T-Digest streaming quantile estimation
export 'src/tdigest.dart';

/// Unified cross-standard parsing utilities
export 'src/unified_parse.dart';
