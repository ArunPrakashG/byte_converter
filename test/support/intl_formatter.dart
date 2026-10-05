import 'package:byte_converter/byte_converter.dart';
import 'package:intl/intl.dart';

/// The documented recipe for plugging package:intl into humanized output.
String intlHumanizeFormatter(double value, HumanizeOptions o) {
  final locale = o.locale;
  if (locale == null || locale.isEmpty) return ''; // fall back to default
  final f = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = o.minimumFractionDigits ?? 0
    ..maximumFractionDigits =
        o.maximumFractionDigits ?? o.minimumFractionDigits ?? o.precision;
  if (!o.useGrouping) f.turnOffGrouping();
  return f.format(value);
}
