import 'byte_enums.dart';

class HumanizeOptions {
  const HumanizeOptions({
    this.standard = ByteStandard.si,
    this.useBits = false,
    this.precision = 2,
    this.showSpace = true,
    this.fullForm = false,
    this.fullForms,
    this.separator,
    this.spacer,
    this.minimumFractionDigits,
    this.maximumFractionDigits,
    this.signed = false,
    this.forceUnit,
    this.locale,
    this.useGrouping = true,
  });
  final ByteStandard standard;
  final bool useBits;
  final int precision;
  final bool showSpace;
  final bool fullForm;
  final Map<String, String>? fullForms;
  final String? separator;
  final String? spacer;
  final int? minimumFractionDigits;
  final int? maximumFractionDigits;
  final bool signed;
  final String? forceUnit;
  final String? locale;
  final bool useGrouping;
}

class HumanizeResult {
  const HumanizeResult(this.value, this.symbol, this.text);
  final double value;
  final String symbol;
  final String text;
}
