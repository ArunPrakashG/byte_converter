import 'byte_enums.dart';

/// Hints to bias unit selection and standards automatically.
enum UnitPolicy {
  auto,
  preferBinaryPowers, // bias to IEC
  memory, // IEC
  storage, // JEDEC
  network, // SI
}

/// Rounding strategy for formatting numeric output.
enum FormattingRoundingMode {
  halfAwayFromZero,
  halfToEven,
}

/// Controls the letter-case of the SI kilo symbol for bytes.
/// lowerK -> kB (preferred SI), upperK -> KB (legacy/JEDEC-style for some UIs).
enum SiKSymbolCase { lowerK, upperK }

class HumanizeOptions {
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
  final ByteStandard standard;
  final bool useBits;
  final int precision;
  final bool showSpace;

  /// If true and [spacer] is not provided, inserts a non-breaking space (NBSP)
  /// between number and unit when [showSpace] is true.
  final bool nonBreakingSpace;
  final bool fullForm;
  final Map<String, String>? fullForms;
  final String? separator;
  final String? spacer;
  final int? minimumFractionDigits;
  final int? maximumFractionDigits;

  /// When true and min/max fraction digits are provided, format by truncating
  /// toward zero instead of rounding.
  final bool truncate;
  final bool signed;
  final String? forceUnit;
  final String? locale;
  final bool useGrouping;
  final UnitPolicy? policy;
  final FormattingRoundingMode roundingMode;
  final SiKSymbolCase siKSymbolCase;

  /// Pad the numeric portion to a fixed width (character count) using spaces.
  /// Applies to the numeric substring only (before the spacer and unit).
  /// When null or <= 0, no padding is applied.
  final int? fixedWidth;

  /// When true, include the sign character in the fixedWidth calculation.
  /// If signed is true and value >= 0, a leading space is used for alignment.
  final bool includeSignInWidth;
}

class HumanizeResult {
  const HumanizeResult(this.value, this.symbol, this.text);
  final double value;
  final String symbol;
  final String text;
}
