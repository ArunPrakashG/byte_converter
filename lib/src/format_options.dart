import 'byte_enums.dart';
import 'humanize_options.dart' show SiKSymbolCase;

/// Reusable formatter options for humanizing sizes and rates.
class ByteFormatOptions {
  const ByteFormatOptions({
    this.standard = ByteStandard.si,
    this.useBytes = false,
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
    this.siKSymbolCase = SiKSymbolCase.upperK,
    this.fixedWidth,
    this.includeSignInWidth = false,
  });
  final ByteStandard standard;
  final bool useBytes;
  final int precision;
  final bool showSpace;

  /// If true and [spacer] is not provided, insert NBSP between number and unit.
  final bool nonBreakingSpace;

  /// If true, output unit in full form (e.g., "kilobytes" instead of "kB").
  final bool fullForm;

  /// Optional overrides for full-form unit names, mapping default name => replacement.
  /// Example: {"kilobytes": "kilobyte"} to force singular regardless of value or localized terms.
  final Map<String, String>? fullForms;

  /// Decimal separator character (e.g., ","). If null, uses ".".
  final String? separator;

  /// Spacer between numeric value and unit (overrides [showSpace] if provided).
  final String? spacer;

  /// Minimum fraction digits to display. If provided, overrides [precision] behavior in favor of min/max strategy.
  final int? minimumFractionDigits;

  /// Maximum fraction digits to display. If provided, overrides [precision] behavior in favor of min/max strategy.
  final int? maximumFractionDigits;

  /// When true and min/max fraction digits are set, truncate instead of rounding.
  final bool truncate;

  /// Include a leading plus sign for positive values; zero is prefixed with a space for alignment.
  final bool signed;

  /// Force a specific unit symbol (e.g., "MB", "MiB", "Gb", "KiB"). When set, the formatter will not auto-scale.
  final String? forceUnit;

  /// Locale identifier (e.g., `en_US`) used for number formatting when the optional
  /// intl adapter (see `enableByteConverterIntl`) is enabled.
  final String? locale;

  /// Whether thousands grouping separators should be applied (ignored when locale is unset
  /// or the intl adapter is disabled).
  final bool useGrouping;

  /// SI kilo symbol letter-case preference.
  final SiKSymbolCase siKSymbolCase;

  /// Pad numeric portion to fixed width (spaces). Null/<=0 disables.
  final int? fixedWidth;
  final bool includeSignInWidth;

  @override
  String toString() {
    final parts = <String>[];
    if (standard != ByteStandard.si) parts.add('standard=$standard');
    if (useBytes) parts.add('useBytes=true');
    if (precision != 2) parts.add('precision=$precision');
    if (!showSpace) parts.add('showSpace=false');
    if (fullForm) parts.add('fullForm=true');
    if (fullForms != null && fullForms!.isNotEmpty) {
      parts.add('fullForms=${fullForms!.length}');
    }
    if (separator != null) parts.add('separator="$separator"');
    if (spacer != null) parts.add('spacer="$spacer"');
    if (nonBreakingSpace) parts.add('nbsp=true');
    if (minimumFractionDigits != null) {
      parts.add('minFrac=$minimumFractionDigits');
    }
    if (maximumFractionDigits != null) {
      parts.add('maxFrac=$maximumFractionDigits');
    }
    if (truncate) parts.add('truncate=true');
    if (signed) parts.add('signed=true');
    if (forceUnit != null) parts.add('forceUnit=$forceUnit');
    if (locale != null) parts.add('locale=$locale');
    if (!useGrouping) parts.add('useGrouping=false');
    if (siKSymbolCase == SiKSymbolCase.upperK) parts.add('siK=upper');
    if (fixedWidth != null && fixedWidth! > 0) {
      parts.add('fixedWidth=$fixedWidth');
    }
    if (includeSignInWidth) parts.add('includeSignInWidth=true');
    if (parts.isEmpty) return 'ByteFormatOptions(default)';
    return 'ByteFormatOptions(${parts.join(', ')})';
  }
}
