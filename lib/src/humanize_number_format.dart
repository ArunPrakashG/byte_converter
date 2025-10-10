import 'humanize_options.dart';

typedef HumanizeNumberFormatter = String Function(
  double value,
  HumanizeOptions options,
);

HumanizeNumberFormatter? _registeredFormatter;

HumanizeNumberFormatter? get humanizeNumberFormatter => _registeredFormatter;

void registerHumanizeNumberFormatter(HumanizeNumberFormatter formatter) {
  _registeredFormatter = formatter;
}

void clearHumanizeNumberFormatter() {
  _registeredFormatter = null;
}
