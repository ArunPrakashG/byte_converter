library byte_converter_intl;

import 'package:intl/intl.dart';

import 'src/humanize_number_format.dart';
import 'src/humanize_options.dart';

export 'byte_converter.dart';

typedef NumberFormatFactory = NumberFormat Function(String locale);

NumberFormat _defaultDecimalPattern(String locale) =>
    NumberFormat.decimalPattern(locale);

void enableByteConverterIntl({NumberFormatFactory? numberFormatFactory}) {
  registerHumanizeNumberFormatter(
    _IntlHumanizeNumberFormatter(
      numberFormatFactory ?? _defaultDecimalPattern,
    ).format,
  );
}

void disableByteConverterIntl() => clearHumanizeNumberFormatter();

class _IntlHumanizeNumberFormatter {
  _IntlHumanizeNumberFormatter(this._factory);

  final NumberFormatFactory _factory;
  final Map<String, NumberFormat> _cache = {};

  String format(double value, HumanizeOptions options) {
    final locale = options.locale;
    if (locale == null || locale.isEmpty) {
      return '';
    }

    final min = options.minimumFractionDigits ?? 0;
    final max = options.maximumFractionDigits ??
        (options.minimumFractionDigits ?? options.precision);
    final key = '$locale|$min|$max|${options.useGrouping}';

    try {
      final formatter = _cache.putIfAbsent(key, () {
        final fmt = _factory(locale);
        if (!options.useGrouping) {
          fmt.turnOffGrouping();
        }
        fmt.minimumFractionDigits = min;
        fmt.maximumFractionDigits = max;
        return fmt;
      });
      return formatter.format(value);
    } catch (_) {
      return '';
    }
  }
}
