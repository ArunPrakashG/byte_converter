import 'dart:collection';

/// Default localized unit names keyed by base locale (lowercase) and unit symbol.
///
/// Symbols follow the same casing conventions as the humanize pipeline:
/// - Byte units use uppercase symbols (e.g. `KB`, `MiB`, `B`).
/// - Bit units use lowercase symbols (e.g. `kb`, `mib`, `b`).
const Map<String, Map<String, String>> _defaultLocalizedUnits = {
  'en': {
    'YB': 'yottabytes',
    'ZB': 'zettabytes',
    'EB': 'exabytes',
    'PB': 'petabytes',
    'TB': 'terabytes',
    'GB': 'gigabytes',
    'MB': 'megabytes',
    'KB': 'kilobytes',
    'B': 'bytes',
    'YiB': 'yobibytes',
    'ZiB': 'zebibytes',
    'EiB': 'exbibytes',
    'PiB': 'pebibytes',
    'TiB': 'tebibytes',
    'GiB': 'gibibytes',
    'MiB': 'mebibytes',
    'KiB': 'kibibytes',
    'yb': 'yottabits',
    'zb': 'zettabits',
    'eb': 'exabits',
    'pb': 'petabits',
    'tb': 'terabits',
    'gb': 'gigabits',
    'mb': 'megabits',
    'kb': 'kilobits',
    'b': 'bits',
    'yib': 'yobibits',
    'zib': 'zebibits',
    'eib': 'exbibits',
    'pib': 'pebibits',
    'tib': 'tebibits',
    'gib': 'gibibits',
    'mib': 'mebibits',
    'kib': 'kibibits',
  },
  'de': {
    'YB': 'Yottabyte',
    'ZB': 'Zettabyte',
    'EB': 'Exabyte',
    'PB': 'Petabyte',
    'TB': 'Terabyte',
    'GB': 'Gigabyte',
    'MB': 'Megabyte',
    'KB': 'Kilobyte',
    'B': 'Byte',
    'YiB': 'Yobibyte',
    'ZiB': 'Zebibyte',
    'EiB': 'Exbibyte',
    'PiB': 'Pebibyte',
    'TiB': 'Tebibyte',
    'GiB': 'Gibibyte',
    'MiB': 'Mebibyte',
    'KiB': 'Kibibyte',
    'yb': 'Yottabit',
    'zb': 'Zettabit',
    'eb': 'Exabit',
    'pb': 'Petabit',
    'tb': 'Terabit',
    'gb': 'Gigabit',
    'mb': 'Megabit',
    'kb': 'Kilobit',
    'b': 'Bit',
    'yib': 'Yobibit',
    'zib': 'Zebibit',
    'eib': 'Exbibit',
    'pib': 'Pebibit',
    'tib': 'Tebibit',
    'gib': 'Gibibit',
    'mib': 'Mebibit',
    'kib': 'Kibibit',
  },
  'fr': {
    'YB': 'yottaoctets',
    'ZB': 'zettaoctets',
    'EB': 'exoctets',
    'PB': 'pétaoctets',
    'TB': 'téraoctets',
    'GB': 'gigaoctets',
    'MB': 'mégaoctets',
    'KB': 'kilooctets',
    'B': 'octets',
    'YiB': 'yobioctets',
    'ZiB': 'zebioctets',
    'EiB': 'exbioctets',
    'PiB': 'pébioctets',
    'TiB': 'tébioctets',
    'GiB': 'gibioctets',
    'MiB': 'mébioctets',
    'KiB': 'kibioctets',
    'yb': 'yottabits',
    'zb': 'zettabits',
    'eb': 'exabits',
    'pb': 'pétabits',
    'tb': 'térabits',
    'gb': 'gigabits',
    'mb': 'mégabits',
    'kb': 'kilobits',
    'b': 'bits',
    'yib': 'yobibits',
    'zib': 'zébibits',
    'eib': 'exbibits',
    'pib': 'pébibits',
    'tib': 'tébibits',
    'gib': 'gibibits',
    'mib': 'mébibits',
    'kib': 'kibibits',
  },
};

final Map<String, Map<String, String>> _customLocalizedUnits = {};

Map<String, String> localizedUnitNameMapForDefaultLocale() =>
    UnmodifiableMapView(_defaultLocalizedUnits['en']!);

String? _lookupInMaps(String localeKey, String symbol) {
  final custom = _customLocalizedUnits[localeKey];
  if (custom != null && custom.containsKey(symbol)) {
    return custom[symbol];
  }
  final defaults = _defaultLocalizedUnits[localeKey];
  if (defaults != null && defaults.containsKey(symbol)) {
    return defaults[symbol];
  }
  return null;
}

String? localizedUnitName(String symbol, {String? locale}) {
  if (locale == null || locale.isEmpty) return null;
  final normalized = locale.toLowerCase();
  final exact = _lookupInMaps(normalized, symbol);
  if (exact != null) return exact;

  final separatorIndex = normalized.indexOf(RegExp('[-_]'));
  if (separatorIndex != -1) {
    final base = normalized.substring(0, separatorIndex);
    final baseMatch = _lookupInMaps(base, symbol);
    if (baseMatch != null) return baseMatch;
  }

  return null;
}

void registerLocalizedUnitNames(String locale, Map<String, String> names) {
  final key = locale.toLowerCase();
  final existing = _customLocalizedUnits.putIfAbsent(key, HashMap.new);
  existing.addAll(names);
}

void clearLocalizedUnitNames(String locale) {
  _customLocalizedUnits.remove(locale.toLowerCase());
}
