library fast_format;

/// Ultra-fast formatter for simple SI bytes use-cases.
///
/// Constraints:
/// - Standard: SI
/// - Units: B, KB, MB, GB, TB, PB (bytes only)
/// - No locale/grouping, no NBSP, no signed, no fullForm, no fixedWidth.
/// - Precision: [precision] digits (trailing zeros trimmed).
///
/// This bypasses general features and takes the fastest route.
String fastHumanizeSiBytes(double bytes, {int precision = 2}) {
  const tb = 1e12;
  const gb = 1e9;
  const mb = 1e6;
  const kb = 1e3;
  String sym;
  double base;
  if (bytes >= tb) {
    base = tb;
    sym = 'TB';
  } else if (bytes >= gb) {
    base = gb;
    sym = 'GB';
  } else if (bytes >= mb) {
    base = mb;
    sym = 'MB';
  } else if (bytes >= kb) {
    base = kb;
    sym = 'KB';
  } else {
    base = 1.0;
    sym = 'B';
  }
  final v = bytes / base;
  final s = _toFixedTrim(v, precision);
  return '$s $sym';
}

/// Ultra-fast formatter for simple IEC bytes use-cases.
/// Units: B, KiB, MiB, GiB, TiB, PiB.
String fastHumanizeIecBytes(double bytes, {int precision = 2}) {
  const tib = 1099511627776.0; // 1024^4
  const gib = 1073741824.0; // 1024^3
  const mib = 1048576.0; // 1024^2
  const kib = 1024.0; // 1024^1
  String sym;
  double base;
  if (bytes >= tib) {
    base = tib;
    sym = 'TiB';
  } else if (bytes >= gib) {
    base = gib;
    sym = 'GiB';
  } else if (bytes >= mib) {
    base = mib;
    sym = 'MiB';
  } else if (bytes >= kib) {
    base = kib;
    sym = 'KiB';
  } else {
    base = 1.0;
    sym = 'B';
  }
  final v = bytes / base;
  final s = _toFixedTrim(v, precision);
  return '$s $sym';
}

/// Ultra-fast formatter for SI bits.
String fastHumanizeSiBits(double bytes, {int precision = 2}) {
  final bits = bytes * 8.0;
  const tb = 1e12;
  const gb = 1e9;
  const mb = 1e6;
  const kb = 1e3;
  String sym;
  double base;
  if (bits >= tb) {
    base = tb;
    sym = 'Tb';
  } else if (bits >= gb) {
    base = gb;
    sym = 'Gb';
  } else if (bits >= mb) {
    base = mb;
    sym = 'Mb';
  } else if (bits >= kb) {
    base = kb;
    sym = 'Kb';
  } else {
    base = 1.0;
    sym = 'b';
  }
  final v = bits / base;
  final s = _toFixedTrim(v, precision);
  return '$s $sym';
}

String _toFixedTrim(double v, int precision) {
  final intV = v.truncateToDouble();
  if (v == intV) return intV.toInt().toString();
  var s = v.toStringAsFixed(precision);
  final dot = s.indexOf('.');
  if (dot == -1) return s;
  var end = s.length;
  while (end > dot + 1 && s.codeUnitAt(end - 1) == 0x30) {
    end--;
  }
  if (end == dot + 1) end = dot;
  if (end == s.length) return s;
  return s.substring(0, end);
}
