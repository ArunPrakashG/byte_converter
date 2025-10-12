import 'dart:collection';
import 'dart:core';

/// Default localized unit names keyed by base locale (lowercase) and unit symbol.
///
/// Symbols follow the same casing conventions as the humanize pipeline:
/// - Byte units use uppercase symbols (e.g. `KB`, `MiB`, `B`).
/// - Bit units use lowercase symbols (e.g. `kb`, `mib`, `b`).
const Map<String, Map<String, String>> _defaultLocalizedUnits = {
  'en': {
    'QB': 'quettabytes',
    'RB': 'ronnabytes',
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
    'qb': 'quettabits',
    'rb': 'ronnabits',
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
    'QB': 'Quettabyte',
    'RB': 'Ronnabyte',
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
    'qb': 'Quettabit',
    'rb': 'Ronnabit',
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
    'QB': 'quettaoctets',
    'RB': 'ronnaoctets',
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
    'qb': 'quettabits',
    'rb': 'ronnabits',
    'yib': 'yobibits',
    'zib': 'zébibits',
    'eib': 'exbibits',
    'pib': 'pébibits',
    'tib': 'tébibits',
    'gib': 'gibibits',
    'mib': 'mébibits',
    'kib': 'kibibits',
  },
  'hi': {
    'QB': 'क्वेट्टाबाइट्स',
    'RB': 'रॉनाबाइट्स',
    'YB': 'योट्टाबाइट्स',
    'ZB': 'ज़ेट्टाबाइट्स',
    'EB': 'एक्साबाइट्स',
    'PB': 'पेटाबाइट्स',
    'TB': 'टेराबाइट्स',
    'GB': 'गीगाबाइट्स',
    'MB': 'मेगाबाइट्स',
    'KB': 'किलोबाइट्स',
    'B': 'बाइट्स',
    'YiB': 'योबिबाइट्स',
    'ZiB': 'ज़ेबिबाइट्स',
    'EiB': 'एक्सिबाइट्स',
    'PiB': 'पेबीबाइट्स',
    'TiB': 'टेबीबाइट्स',
    'GiB': 'गिबिबाइट्स',
    'MiB': 'मेबीबाइट्स',
    'KiB': 'किबिबाइट्स',
    'yb': 'योट्टाबिट्स',
    'zb': 'ज़ेट्टाबिट्स',
    'eb': 'एक्साबिट्स',
    'pb': 'पेटाबिट्स',
    'tb': 'टेराबिट्स',
    'gb': 'गीगाबिट्स',
    'mb': 'मेगाबिट्स',
    'kb': 'किलोबिट्स',
    'b': 'बिट्स',
    'qb': 'क्वेट्टाबिट्स',
    'rb': 'रॉनाबिट्स',
    'yib': 'योबिबिट्स',
    'zib': 'ज़ेबिबिट्स',
    'eib': 'एक्सिबिट्स',
    'pib': 'पेबीबिट्स',
    'tib': 'टेबीबिट्स',
    'gib': 'गिबिबिट्स',
    'mib': 'मेबीबिट्स',
    'kib': 'किबिबिट्स',
  },
  'es': {
    'QB': 'quettabytes',
    'RB': 'ronnabytes',
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
    'qb': 'quettabits',
    'rb': 'ronnabits',
    'yib': 'yobibits',
    'zib': 'zebibits',
    'eib': 'exbibits',
    'pib': 'pebibits',
    'tib': 'tebibits',
    'gib': 'gibibits',
    'mib': 'mebibits',
    'kib': 'kibibits',
  },
  'pt': {
    'QB': 'quettabytes',
    'RB': 'ronnabytes',
    'YB': 'yottabytes',
    'ZB': 'zettabytes',
    'EB': 'exabytes',
    'PB': 'petabytes',
    'TB': 'terabytes',
    'GB': 'gigabytes',
    'MB': 'megabytes',
    'KB': 'quilobytes',
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
    'kb': 'quilobits',
    'b': 'bits',
    'qb': 'quettabits',
    'rb': 'ronnabits',
    'yib': 'yobibits',
    'zib': 'zebibits',
    'eib': 'exbibits',
    'pib': 'pebibits',
    'tib': 'tebibits',
    'gib': 'gibibits',
    'mib': 'mebibits',
    'kib': 'kibibits',
  },
  'ja': {
    'QB': 'クエタバイト',
    'RB': 'ロナバイト',
    'YB': 'ヨタバイト',
    'ZB': 'ゼタバイト',
    'EB': 'エクサバイト',
    'PB': 'ペタバイト',
    'TB': 'テラバイト',
    'GB': 'ギガバイト',
    'MB': 'メガバイト',
    'KB': 'キロバイト',
    'B': 'バイト',
    'YiB': 'ヨビバイト',
    'ZiB': 'ゼビバイト',
    'EiB': 'エクスビバイト',
    'PiB': 'ペビバイト',
    'TiB': 'テビバイト',
    'GiB': 'ギビバイト',
    'MiB': 'メビバイト',
    'KiB': 'キビバイト',
    'yb': 'ヨタビット',
    'zb': 'ゼタビット',
    'eb': 'エクサビット',
    'pb': 'ペタビット',
    'tb': 'テラビット',
    'gb': 'ギガビット',
    'mb': 'メガビット',
    'kb': 'キロビット',
    'b': 'ビット',
    'qb': 'クエタビット',
    'rb': 'ロナビット',
    'yib': 'ヨビビット',
    'zib': 'ゼビビット',
    'eib': 'エクスビビット',
    'pib': 'ペビビット',
    'tib': 'テビビット',
    'gib': 'ギビビット',
    'mib': 'メビビット',
    'kib': 'キビビット',
  },
  'zh': {
    'QB': '夸字节',
    'RB': '罗字节',
    'YB': '尧字节',
    'ZB': '泽字节',
    'EB': '艾字节',
    'PB': '拍字节',
    'TB': '太字节',
    'GB': '吉字节',
    'MB': '兆字节',
    'KB': '千字节',
    'B': '字节',
    'YiB': '尧二进制字节',
    'ZiB': '泽二进制字节',
    'EiB': '艾二进制字节',
    'PiB': '拍二进制字节',
    'TiB': '太二进制字节',
    'GiB': '吉二进制字节',
    'MiB': '兆二进制字节',
    'KiB': '千二进制字节',
    'yb': '尧比特',
    'zb': '泽比特',
    'eb': '艾比特',
    'pb': '拍比特',
    'tb': '太比特',
    'gb': '吉比特',
    'mb': '兆比特',
    'kb': '千比特',
    'b': '比特',
    'qb': '夸比特',
    'rb': '罗比特',
    'yib': '尧二进制比特',
    'zib': '泽二进制比特',
    'eib': '艾二进制比特',
    'pib': '拍二进制比特',
    'tib': '太二进制比特',
    'gib': '吉二进制比特',
    'mib': '兆二进制比特',
    'kib': '千二进制比特',
  },
  'ru': {
    'QB': 'кветтабайты',
    'RB': 'роннабайты',
    'YB': 'йоттабайты',
    'ZB': 'зеттабайты',
    'EB': 'эксабайты',
    'PB': 'петабайты',
    'TB': 'терабайты',
    'GB': 'гигабайты',
    'MB': 'мегабайты',
    'KB': 'килобайты',
    'B': 'байты',
    'YiB': 'йобибайты',
    'ZiB': 'зебибайты',
    'EiB': 'эксбибайты',
    'PiB': 'пебибайты',
    'TiB': 'тебибайты',
    'GiB': 'гибибайты',
    'MiB': 'мебибайты',
    'KiB': 'кибибайты',
    'yb': 'йоттабиты',
    'zb': 'зеттабиты',
    'eb': 'эксабиты',
    'pb': 'петабиты',
    'tb': 'терабиты',
    'gb': 'гигабиты',
    'mb': 'мегабиты',
    'kb': 'килобиты',
    'b': 'биты',
    'qb': 'кветтабиты',
    'rb': 'роннабиты',
    'yib': 'йобибиты',
    'zib': 'зебибиты',
    'eib': 'эксбибиты',
    'pib': 'пебибиты',
    'tib': 'тебибиты',
    'gib': 'гибибиты',
    'mib': 'мебибиты',
    'kib': 'кибибиты',
  },
};

final Map<String, Map<String, String>> _customLocalizedUnits = {};
final Map<String, Map<String, String>> _customLocalizedSynonyms = {};
final Map<String, Map<String, String>> _customLocalizedSingular = {};
bool _defaultsEnabled = true;

Map<String, String> localizedUnitNameMapForDefaultLocale() =>
    UnmodifiableMapView(_defaultLocalizedUnits['en']!);

String? _lookupInMaps(String localeKey, String symbol) {
  final custom = _customLocalizedUnits[localeKey];
  if (custom != null && custom.containsKey(symbol)) {
    return custom[symbol];
  }
  if (_defaultsEnabled) {
    final defaults = _defaultLocalizedUnits[localeKey];
    if (defaults != null && defaults.containsKey(symbol)) {
      return defaults[symbol];
    }
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

/// Register per-locale synonyms that map localized words back to canonical symbols.
/// Example (fr): { 'octet': 'B', 'octets': 'B', 'kilooctets': 'KB', 'ko': 'KB' }
void registerLocalizedSynonyms(String locale, Map<String, String> synonyms) {
  final key = locale.toLowerCase();
  final existing = _customLocalizedSynonyms.putIfAbsent(key, HashMap.new);
  // Store case-insensitive keys by lowercasing
  existing
      .addAll({for (final e in synonyms.entries) e.key.toLowerCase(): e.value});
}

void clearLocalizedSynonyms(String locale) {
  _customLocalizedSynonyms.remove(locale.toLowerCase());
}

/// Register singular forms for full-form names per locale (optional).
/// keys must be canonical plural names from localizedUnitName (e.g., 'kilobytes'), values singular (e.g., 'kilobyte').
void registerLocalizedSingularNames(
    String locale, Map<String, String> singular) {
  final key = locale.toLowerCase();
  final existing = _customLocalizedSingular.putIfAbsent(key, HashMap.new);
  existing.addAll(singular);
}

void clearLocalizedSingularNames(String locale) {
  _customLocalizedSingular.remove(locale.toLowerCase());
}

/// Returns a singular name for the given unit symbol if available for the locale.
/// Falls back to plural name when no singular registered.
String? localizedUnitSingularName(String symbol,
    {String? locale, bool bits = false}) {
  if (locale == null || locale.isEmpty) return null;
  final plural =
      localizedUnitName(bits ? symbol.toLowerCase() : symbol, locale: locale);
  if (plural == null) return null;
  final key = locale.toLowerCase();
  final customMap = _customLocalizedSingular[key];
  if (customMap != null) {
    final singular = customMap[plural];
    if (singular != null) return singular;
  }
  return plural; // fallback
}

/// Resolve a localized token (possibly a full word or synonym) back to a canonical unit symbol.
/// This is used by parseLocalized helpers. Returns null if no mapping is found.
String? resolveLocalizedUnitSymbol(String token, {String? locale}) {
  if (token.isEmpty) return null;
  final t = token.toLowerCase();
  // 1) Custom synonyms take precedence
  if (locale != null && locale.isNotEmpty) {
    final key = locale.toLowerCase();
    final syn = _customLocalizedSynonyms[key];
    if (syn != null && syn.containsKey(t)) return syn[t];
  }

  // 2) Try to reverse-lookup default + custom localized names for the locale
  String? tryReverse(String loc) {
    final custom = _customLocalizedUnits[loc];
    if (custom != null) {
      for (final e in custom.entries) {
        if (e.value.toLowerCase() == t) return e.key;
      }
    }
    if (_defaultsEnabled) {
      final defaults = _defaultLocalizedUnits[loc];
      if (defaults != null) {
        for (final e in defaults.entries) {
          if (e.value.toLowerCase() == t) return e.key;
        }
      }
    }
    return null;
  }

  if (locale != null && locale.isNotEmpty) {
    final normalized = locale.toLowerCase();
    final exact = tryReverse(normalized);
    if (exact != null) return exact;
    final separatorIndex = normalized.indexOf(RegExp('[-_]'));
    if (separatorIndex != -1) {
      final base = normalized.substring(0, separatorIndex);
      final baseMatch = tryReverse(base);
      if (baseMatch != null) return baseMatch;
    }
  }

  // 3) Fallback to English reverse lookup
  final en = tryReverse('en');
  if (en != null) return en;

  // 4) Also accept raw symbols in any case
  const allSymbols = [
    'QB',
    'RB',
    'YB',
    'ZB',
    'EB',
    'PB',
    'TB',
    'GB',
    'MB',
    'KB',
    'B',
    'YiB',
    'ZiB',
    'EiB',
    'PiB',
    'TiB',
    'GiB',
    'MiB',
    'KiB',
    'qb',
    'rb',
    'yb',
    'zb',
    'eb',
    'pb',
    'tb',
    'gb',
    'mb',
    'kb',
    'b',
    'yib',
    'zib',
    'eib',
    'pib',
    'tib',
    'gib',
    'mib',
    'kib',
  ];
  final match = allSymbols.firstWhere(
    (s) => s.toLowerCase() == t,
    orElse: () => '',
  );
  return match.isEmpty ? null : match;
}

/// Disable built-in default localized unit names to enable tree-shaking strategies.
void disableDefaultLocalizedUnitNames() {
  _defaultsEnabled = false;
}

/// Re-enable built-in default localized unit names.
void enableDefaultLocalizedUnitNames() {
  _defaultsEnabled = true;
}
