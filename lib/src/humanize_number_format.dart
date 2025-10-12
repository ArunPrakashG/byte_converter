import 'humanize_options.dart';

/// Signature for a number formatter used by the humanize pipeline.
typedef HumanizeNumberFormatter = String Function(
  double value,
  HumanizeOptions options,
);

HumanizeNumberFormatter? _registeredFormatter;

/// Returns the currently registered humanize number formatter, if any.
HumanizeNumberFormatter? get humanizeNumberFormatter => _registeredFormatter;

/// Registers a global number formatter used by humanize to render the numeric
/// portion of the output. Pass `null` via [clearHumanizeNumberFormatter] to
/// restore the default formatting behavior.
void registerHumanizeNumberFormatter(HumanizeNumberFormatter formatter) {
  _registeredFormatter = formatter;
}

/// Clears any previously registered number formatter.
void clearHumanizeNumberFormatter() {
  _registeredFormatter = null;
}
