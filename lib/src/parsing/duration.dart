part of '../_parsing.dart';

final _durationHintRegExp = RegExp(
  r'(ns|nano(?:second)?s?|us|µs|μs|micro(?:second)?s?|ms|millisecond(?:s)?|s|sec|secs|second(?:s)?|m|min|mins|minute(?:s)?|h|hr|hrs|hour(?:s)?|d|day|days)\s*$',
  caseSensitive: false,
);

bool _looksLikeDurationLiteral(String literal) {
  final lower = literal.trim().toLowerCase();
  return _durationHintRegExp.hasMatch(lower);
}

double _parseDurationLiteral(String literal) {
  final text = _trimAndNormalize(literal).replaceAll('μ', 'µ');
  final regex =
      RegExp(r'^([+-]?[0-9\.,\u00A0_\s]+)?\s*([a-zµ]+)$', caseSensitive: false);
  final match = regex.firstMatch(text);
  if (match == null) {
    throw FormatException('Invalid duration literal: $literal');
  }
  final numberStr = match.group(1);
  final number = numberStr == null || numberStr.trim().isEmpty
      ? 1.0
      : double.parse(_normalizeNumber(numberStr));
  final unitRaw = match.group(2)!.toLowerCase();
  final unit = unitRaw.replaceAll('μ', 'µ');
  const factors = {
    'ns': 1e-9,
    'nanosecond': 1e-9,
    'nanoseconds': 1e-9,
    'us': 1e-6,
    'µs': 1e-6,
    'microsecond': 1e-6,
    'microseconds': 1e-6,
    'ms': 1e-3,
    'millisecond': 1e-3,
    'milliseconds': 1e-3,
    's': 1.0,
    'sec': 1.0,
    'secs': 1.0,
    'second': 1.0,
    'seconds': 1.0,
    'm': 60.0,
    'min': 60.0,
    'mins': 60.0,
    'minute': 60.0,
    'minutes': 60.0,
    'h': 3600.0,
    'hr': 3600.0,
    'hrs': 3600.0,
    'hour': 3600.0,
    'hours': 3600.0,
    'd': 86400.0,
    'day': 86400.0,
    'days': 86400.0,
  };
  final factor = factors[unit];
  if (factor == null) {
    throw FormatException('Unknown duration unit: $unitRaw');
  }
  final seconds = number * factor;
  if (seconds.isNaN || seconds.isInfinite) {
    throw FormatException('Duration evaluates to an invalid value: $literal');
  }
  return seconds;
}
