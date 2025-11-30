import 'dart:convert';
import 'dart:io';

import 'package:byte_converter/byte_converter_full.dart';
import 'package:byte_converter/src/humanize_options.dart' show SiKSymbolCase;

void main(List<String> args) {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    _printHelp();
    exit(0);
  }
  final cmd = args.first;
  final rest = args.skip(1).toList();
  switch (cmd) {
    case 'parse':
      if (rest.isEmpty) {
        _die('Usage: bytec parse "<size>" [--iec|--jedec] [--strict-bits]');
      }
      final input = rest.first;
      final standard = rest.contains('--iec')
          ? ByteStandard.iec
          : rest.contains('--jedec')
              ? ByteStandard.jedec
              : ByteStandard.si;
      final strictBits = rest.contains('--strict-bits');
      final r = ByteConverter.tryParse(
        input,
        standard: standard,
        strictBits: strictBits,
      );
      if (!r.isSuccess) {
        _die('Error: ${r.error?.message}');
      }
      final bytes = r.value!;
      stdout.writeln(bytes.toHumanReadableAuto(standard: standard));
      break;
    case 'rate':
      if (rest.isEmpty) {
        _die(
            'Usage: bytec rate "<rate>" [--iec|--jedec] [--bytes] [--per s|ms|min|h] [--truncate] [--nbsp] [--si-lower-k] [--pattern "..."]');
      }
      final input = rest.first;
      final perIdx = rest.indexOf('--per');
      final per =
          perIdx != -1 && perIdx + 1 < rest.length ? rest[perIdx + 1] : 's';
      final useBytes = rest.contains('--bytes');
      final standard = rest.contains('--iec')
          ? ByteStandard.iec
          : rest.contains('--jedec')
              ? ByteStandard.jedec
              : ByteStandard.si;
      final r = DataRate.tryParse(input, standard: standard);
      if (!r.isSuccess) {
        _die('Error: ${r.error?.message}');
      }
      final rate = r.value!;
      final truncate = rest.contains('--truncate');
      final nbsp = rest.contains('--nbsp');
      final useLowerK = rest.contains('--si-lower-k');
      final fwIdxR = rest.indexOf('--fixed-width');
      final fixedWidthR = fwIdxR != -1 && fwIdxR + 1 < rest.length
          ? int.tryParse(rest[fwIdxR + 1])
          : null;
      final patIdxR = rest.indexOf('--pattern');
      final patternR =
          patIdxR != -1 && patIdxR + 1 < rest.length ? rest[patIdxR + 1] : null;
      if (patternR != null && patternR.isNotEmpty) {
        stdout.writeln(rate.formatWith(
          patternR,
          options: ByteFormatOptions(
            standard: standard,
            useBytes: useBytes,
            truncate: truncate,
            nonBreakingSpace: nbsp,
            siKSymbolCase:
                useLowerK ? SiKSymbolCase.lowerK : SiKSymbolCase.upperK,
            fixedWidth: fixedWidthR,
          ),
          per: per,
        ));
      } else {
        stdout.writeln(rate.toHumanReadableAuto(
            standard: standard,
            useBytes: useBytes,
            per: per,
            truncate: truncate,
            nonBreakingSpace: nbsp,
            siKSymbolCase:
                useLowerK ? SiKSymbolCase.lowerK : SiKSymbolCase.upperK,
            fixedWidth: fixedWidthR));
      }
      break;
    case 'format':
      if (rest.isEmpty) {
        _die(
            'Usage: bytec format <bytes> [--iec|--jedec] [--bits] [--truncate] [--nbsp] [--si-lower-k] [--fixed-width n] [--pattern "..."]');
      }
      final value = double.tryParse(rest.first);
      if (value == null) {
        _die('Invalid number: ${rest.first}');
      }
      final standard = rest.contains('--iec')
          ? ByteStandard.iec
          : rest.contains('--jedec')
              ? ByteStandard.jedec
              : ByteStandard.si;
      final useBits = rest.contains('--bits');
      final useLowerK = rest.contains('--si-lower-k');
      final patIdx = rest.indexOf('--pattern');
      final pattern =
          patIdx != -1 && patIdx + 1 < rest.length ? rest[patIdx + 1] : null;
      final fwIdx = rest.indexOf('--fixed-width');
      final fixedWidth = fwIdx != -1 && fwIdx + 1 < rest.length
          ? int.tryParse(rest[fwIdx + 1])
          : null;
      final c = ByteConverter(value);
      final truncate = rest.contains('--truncate');
      final nbsp = rest.contains('--nbsp');
      if (pattern != null && pattern.isNotEmpty) {
        stdout.writeln(c.formatWith(pattern,
            options: ByteFormatOptions(
              useBytes: !useBits,
              truncate: truncate,
              nonBreakingSpace: nbsp,
              standard: standard,
              siKSymbolCase:
                  useLowerK ? SiKSymbolCase.lowerK : SiKSymbolCase.upperK,
              fixedWidth: fixedWidth,
            )));
      } else {
        stdout.writeln(c.toHumanReadableAuto(
            standard: standard,
            useBits: useBits,
            truncate: truncate,
            nonBreakingSpace: nbsp,
            siKSymbolCase:
                useLowerK ? SiKSymbolCase.lowerK : SiKSymbolCase.upperK,
            fixedWidth: fixedWidth));
      }
      break;
    case 'parse-localized':
      if (rest.isEmpty) {
        _die(
            'Usage: bytec parse-localized "<size>" [--locale xx] [--iec|--jedec]');
      }
      final input = rest.first;
      final locIdx = rest.indexOf('--locale');
      final locale =
          locIdx != -1 && locIdx + 1 < rest.length ? rest[locIdx + 1] : null;
      final standard = rest.contains('--iec')
          ? ByteStandard.iec
          : rest.contains('--jedec')
              ? ByteStandard.jedec
              : ByteStandard.si;
      final r = parseLocalized(input, locale: locale, standard: standard);
      if (!r.isSuccess) {
        _die('Error: ${r.error?.message}');
      }
      stdout.writeln(r.value!.toHumanReadableAuto(standard: standard));
      break;
    case 'os-parse':
      if (rest.isEmpty) {
        _die('Usage: bytec os-parse "<token>" (--linux|--windows)');
      }
      final input = rest.first;
      final isLinux = rest.contains('--linux');
      final isWindows = rest.contains('--windows');
      if (!isLinux && !isWindows) {
        _die('Specify one of --linux or --windows');
      }
      final r = isLinux
          ? OSParsingModes.parseLinuxHuman(input)
          : OSParsingModes.parseWindowsShort(input);
      if (!r.isSuccess) {
        _die('Error: ${r.error?.message}');
      }
      stdout.writeln(r.value!.toHumanReadableAuto());
      break;
    case 'transfer-plan':
      // bytec transfer-plan "<size>" --rate "<rate>" [--window "<rate>,<seconds>" ...] [--throttle x] [--elapsed s]
      if (rest.isEmpty) {
        _die(
            'Usage: bytec transfer-plan "<size>" --rate "<rate>" [--window "<rate>,<seconds>"]... [--throttle x] [--elapsed s]');
      }
      final sizeInput = rest.first;
      int idxOf(List<String> a, String k) => a.indexOf(k);
      String? opt(List<String> a, String k) => () {
            final i = idxOf(a, k);
            return i != -1 && i + 1 < a.length ? a[i + 1] : null;
          }();
      final rateStr = opt(rest, '--rate');
      if (rateStr == null) {
        _die('Missing --rate');
      }
      final size = ByteConverter.parse(sizeInput);
      final rate = DataRate.parse(rateStr);
      final elapsedStr = opt(rest, '--elapsed');
      final elapsed =
          elapsedStr != null ? Duration(seconds: int.parse(elapsedStr)) : null;
      final plan = size.estimateTransfer(rate, elapsed: elapsed);
      // windows
      for (var i = 0; i < rest.length; i++) {
        if (rest[i] == '--window' && i + 1 < rest.length) {
          final w = rest[i + 1];
          final parts = w.split(',');
          if (parts.length != 2) {
            _die('Bad --window "$w". Expected "<rate>,<seconds>"');
          }
          final wr = DataRate.parse(parts[0]);
          final dur = Duration(seconds: int.parse(parts[1]));
          plan.addRateWindow(RateWindow(rate: wr, duration: dur));
        }
      }
      final thr = opt(rest, '--throttle');
      if (thr != null) {
        plan.setThrottle(double.parse(thr));
      }
      stdout.writeln('ETA: ${plan.estimatedTotalDuration}');
      stdout.writeln('Remaining: ${plan.remainingDuration}');
      stdout.writeln('ETA string: ${plan.etaString()}');
      break;
    case 'streaming-quantiles':
      // Read stdin numbers, report p50/p95/p99
      final qs = StreamingQuantiles([0.5, 0.95, 0.99]);
      stdin.transform(utf8.decoder).transform(const LineSplitter()).listen(
          (line) {
        final v = double.tryParse(line.trim());
        if (v != null) {
          qs.add(v);
        }
      }, onDone: () {
        stdout.writeln('p50 ~ ${qs.estimate(50)}');
        stdout.writeln('p95 ~ ${qs.estimate(95)}');
        stdout.writeln('p99 ~ ${qs.estimate(99)}');
      });
      // Do not break; keep running until stdin closes
      return;
    default:
      _die('Unknown command: $cmd');
  }
}

void _printHelp() {
  stdout.writeln('bytec - byte converter CLI');
  stdout.writeln('Commands:');
  stdout.writeln('  parse  "<size>"   Parse a size string');
  stdout.writeln('  rate   "<rate>"   Parse a data rate string');
  stdout.writeln('  format <bytes>     Format a raw byte count');
  stdout.writeln(
      '  parse-localized "<size>" [--locale xx] Parse using localized unit words');
  stdout.writeln(
      '  os-parse "<token>" (--linux|--windows)    Parse common OS outputs');
  stdout.writeln(
      '  transfer-plan "<size>" --rate "<rate>" [--window "<rate>,<seconds>"]... [--throttle x] [--elapsed s]');
  stdout.writeln(
      '  streaming-quantiles   Read numbers from stdin and print p50/p95/p99');
  stdout.writeln('Flags:');
  stdout.writeln('  --iec | --jedec  Select unit standard (default SI)');
  stdout.writeln('  --bits           Format bits instead of bytes');
  stdout.writeln(
      '  --truncate       Use truncation for fraction digits instead of rounding');
  stdout.writeln(
      '  --nbsp           Use non-breaking space between number and unit');
  stdout.writeln(
      '  --strict-bits    Disallow fractional bit inputs when parsing');
  stdout
      .writeln('  --si-lower-k     Use SI "kB" instead of "KB" for kilo bytes');
  stdout
      .writeln('  --pattern        Pattern formatting (e.g., "0.0 u", "0 U")');
  stdout
      .writeln('  --per            For rate: choose time base (s, ms, min, h)');
  stdout.writeln(
      '  --fixed-width n  Pad numeric portion to width n using spaces');
}

Never _die(String message) {
  stderr.writeln(message);
  exit(2);
}
