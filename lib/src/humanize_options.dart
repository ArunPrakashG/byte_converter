/// Humanization configuration types controlling how values are rendered as text.
library byte_converter.humanize_options;

import 'byte_enums.dart';

/// Hints to bias unit selection and standards automatically.
enum UnitPolicy {
  /// No bias. Use the provided [HumanizeOptions.standard] as-is.
  auto,

  /// Prefer binary powers (IEC). Useful for memory and OS-level sizes.
  preferBinaryPowers,

  /// Alias for [preferBinaryPowers]; emphasizes memory use-cases.
  memory,

  /// Prefer JEDEC (KB/MB/GB as 1024^n). Common in storage UIs.
  storage,

  /// Prefer SI (KB/MB/GB as 1000^n). Typical for networking.
  network,
}

/// Rounding strategy for formatting numeric output.
enum FormattingRoundingMode {
  /// Round halves away from zero (1.5 -> 2, -1.5 -> -2).
  halfAwayFromZero,

  /// Banker's rounding to the nearest even (1.5 -> 2, 2.5 -> 2).
  halfToEven,
}

/// Controls the letter-case of the SI kilo symbol for bytes.
/// lowerK -> kB (preferred SI), upperK -> KB (legacy/JEDEC-style for some UIs).
enum SiKSymbolCase {
  /// Use lowercase k (kB) for SI kilo.
  lowerK,

  /// Use uppercase K (KB) for legacy/JEDEC-style displays.
  upperK,
}

/// Options that control how a byte value is humanized into text.
class HumanizeOptions {
  /// Creates options that control scaling, unit symbols/words, spacing,
  /// localization, and rounding when humanizing numeric values.
  const HumanizeOptions({
    this.standard = ByteStandard.si,
    this.useBits = false,
    this.precision = 2,
    this.showSpace = true,
    this.nonBreakingSpace = false,
    this.fullForm = false,
    this.fullForms,
    this.separator,
    this.spacer,
    this.minimumFractionDigits,
    this.maximumFractionDigits,
    this.truncate = false,
    this.signed = false,
    this.forceUnit,
    this.locale,
    this.useGrouping = true,
    this.policy,
    this.roundingMode = FormattingRoundingMode.halfAwayFromZero,
    this.siKSymbolCase = SiKSymbolCase.upperK,
    this.fixedWidth,
    this.includeSignInWidth = false,
  });

  /// Unit standard to use for scaling.
  final ByteStandard standard;

  /// When true, format as bits instead of bytes.
  final bool useBits;

  /// Legacy precision when min/max fraction digits are not given.
  final int precision;

  /// Whether to insert a space between number and unit (unless [spacer] overrides).
  final bool showSpace;

  /// If true and [spacer] is not provided, inserts a non-breaking space (NBSP)
  /// between number and unit when [showSpace] is true.
  final bool nonBreakingSpace;

  /// Output unit in full words when true (e.g., kilobytes).
  final bool fullForm;

  /// Optional map of full-form overrides (default full word -> replacement).
  final Map<String, String>? fullForms;

  /// Decimal separator override. When null, '.' is used.
  final String? separator;

  /// Spacer string between number and unit (overrides [showSpace]).
  final String? spacer;

  /// Minimum fraction digits to display.
  final int? minimumFractionDigits;

  /// Maximum fraction digits to display.
  final int? maximumFractionDigits;

  /// When true and min/max fraction digits are provided, format by truncating
  /// toward zero instead of rounding.
  final bool truncate;

  /// Include a sign for positive/zero values for alignment.
  final bool signed;

  /// Force a specific unit symbol; disables auto-scaling when set.
  final String? forceUnit;

  /// Locale used for number formatting when intl adapter is enabled.
  final String? locale;

  /// Whether thousands separators are used when formatting numbers.
  final bool useGrouping;

  /// Bias for auto unit selection across standards.
  final UnitPolicy? policy;

  /// Numeric rounding behavior.
  final FormattingRoundingMode roundingMode;

  /// SI kilo symbol letter case configuration.
  final SiKSymbolCase siKSymbolCase;

  /// Pad the numeric portion to a fixed width (character count) using spaces.
  /// Applies to the numeric substring only (before the spacer and unit).
  /// When null or <= 0, no padding is applied.
  final int? fixedWidth;

  /// When true, include the sign character in the fixedWidth calculation.
  /// If signed is true and value >= 0, a leading space is used for alignment.
  final bool includeSignInWidth;
}

/// Result of humanizing a raw byte quantity.
class HumanizeResult {
  /// Creates a result with the scaled numeric [value], the chosen unit
  /// [symbol], and the final formatted [text].
  const HumanizeResult(this.value, this.symbol, this.text);

  /// Scaled numeric value in the chosen unit (e.g., 1.23 for 1.23 MB).
  final double value;

  /// The unit symbol used (e.g., MB, MiB, kb).
  final String symbol;

  /// Final formatted text including number and unit (e.g., "1.23 MB").
  final String text;
}
