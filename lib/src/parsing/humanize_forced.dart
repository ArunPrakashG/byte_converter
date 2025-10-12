part of '../_parsing.dart';

// Forced-unit humanize fallback for uncommon cases not covered by micro fast-paths.
// Returns null when unable to map the provided unit for the selected standard.
HumanizeResult? _humanizeFastForced(
  double bytes,
  String unit,
  bool bits,
  ByteStandard standard,
  int precision,
) {
  final u = unit;
  final isBitUnit = u.endsWith('b') && !u.endsWith('B');
  final up = isBitUnit ? u.substring(0, u.length - 1) : u;
  final upper = up.toUpperCase();

  double base;
  String sym = u;

  if (bits) {
    final b = bytes * 8.0;
    switch (upper) {
      case 'PB':
      case 'P':
        base = 1e15;
        sym = 'Pb';
        break;
      case 'TB':
      case 'T':
        base = 1e12;
        sym = 'Tb';
        break;
      case 'GB':
      case 'G':
        base = 1e9;
        sym = 'Gb';
        break;
      case 'MB':
      case 'M':
        base = 1e6;
        sym = 'Mb';
        break;
      case 'KB':
      case 'K':
        base = 1e3;
        sym = 'Kb';
        break;
      case 'B':
      case '':
        base = 1.0;
        sym = 'b';
        break;
      default:
        switch (upper) {
          case 'KIB':
            base = 1024.0;
            sym = 'Kib';
            break;
          case 'MIB':
            base = 1048576.0;
            sym = 'Mib';
            break;
          case 'GIB':
            base = 1073741824.0;
            sym = 'Gib';
            break;
          case 'TIB':
            base = 1099511627776.0;
            sym = 'Tib';
            break;
          default:
            return null;
        }
    }
    final v = b / base;
    final s = _toFixedTrim(v, precision);
    return HumanizeResult(v, sym, '$s $sym');
  }

  // Bytes mapping depends on the selected standard for ambiguous SI-like byte units.
  switch (standard) {
    case ByteStandard.si:
      switch (upper) {
        case 'QB':
          base = 1e30;
          sym = 'QB';
          break;
        case 'RB':
          base = 1e27;
          sym = 'RB';
          break;
        case 'YB':
          base = 1e24;
          sym = 'YB';
          break;
        case 'ZB':
          base = 1e21;
          sym = 'ZB';
          break;
        case 'EB':
          base = 1e18;
          sym = 'EB';
          break;
        case 'PB':
          base = 1e15;
          sym = 'PB';
          break;
        case 'TB':
        case 'T':
          base = 1e12;
          sym = 'TB';
          break;
        case 'GB':
        case 'G':
          base = 1e9;
          sym = 'GB';
          break;
        case 'MB':
        case 'M':
          base = 1e6;
          sym = 'MB';
          break;
        case 'KB':
        case 'K':
          base = 1e3;
          sym = 'KB';
          break;
        case 'B':
        case '':
          base = 1.0;
          sym = 'B';
          break;
        default:
          // Allow IEC explicit symbols under SI request
          switch (upper) {
            case 'KIB':
              base = 1024.0;
              sym = 'KiB';
              break;
            case 'MIB':
              base = 1048576.0;
              sym = 'MiB';
              break;
            case 'GIB':
              base = 1073741824.0;
              sym = 'GiB';
              break;
            case 'TIB':
              base = 1099511627776.0;
              sym = 'TiB';
              break;
            default:
              return null;
          }
      }
      break;
    case ByteStandard.jedec:
      // JEDEC commonly defines KB/MB/GB/TB as 1024^n. Support these; defer others to slow path.
      switch (upper) {
        case 'TB':
        case 'T':
          base = 1024.0 * 1024 * 1024 * 1024;
          sym = 'TB';
          break;
        case 'GB':
        case 'G':
          base = 1024.0 * 1024 * 1024;
          sym = 'GB';
          break;
        case 'MB':
        case 'M':
          base = 1024.0 * 1024;
          sym = 'MB';
          break;
        case 'KB':
        case 'K':
          base = 1024.0;
          sym = 'KB';
          break;
        case 'B':
        case '':
          base = 1.0;
          sym = 'B';
          break;
        default:
          return null;
      }
      break;
    case ByteStandard.iec:
      switch (upper) {
        case 'YIB':
          base = 1024.0 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024;
          sym = 'YiB';
          break;
        case 'ZIB':
          base = 1024.0 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024;
          sym = 'ZiB';
          break;
        case 'EIB':
          base = 1024.0 * 1024 * 1024 * 1024 * 1024 * 1024;
          sym = 'EiB';
          break;
        case 'PIB':
          base = 1024.0 * 1024 * 1024 * 1024 * 1024;
          sym = 'PiB';
          break;
        case 'TIB':
          base = 1024.0 * 1024 * 1024 * 1024;
          sym = 'TiB';
          break;
        case 'GIB':
          base = 1024.0 * 1024 * 1024;
          sym = 'GiB';
          break;
        case 'MIB':
          base = 1024.0 * 1024;
          sym = 'MiB';
          break;
        case 'KIB':
          base = 1024.0;
          sym = 'KiB';
          break;
        case 'B':
        case '':
          base = 1.0;
          sym = 'B';
          break;
        default:
          return null;
      }
      break;
  }

  final v = bytes / base;
  final s = _toFixedTrim(v, precision);
  return HumanizeResult(v, sym, '$s $sym');
}
