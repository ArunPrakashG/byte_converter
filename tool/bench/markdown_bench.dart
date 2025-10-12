import 'dart:io';
import 'dart:math';

import 'package:byte_converter/byte_converter.dart';
import 'package:filesize/filesize.dart' as fs;

typedef Task = void Function();

Duration _timeWithWarmup(Task task, int iterations,
    {int warmup = 2000, int rounds = 3}) {
  // Warm up JIT
  for (var i = 0; i < warmup; i++) {
    task();
  }
  final runs = <int>[];
  for (var r = 0; r < rounds; r++) {
    final sw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      task();
    }
    sw.stop();
    runs.add(sw.elapsedMicroseconds);
  }
  runs.sort();
  return Duration(microseconds: runs[runs.length ~/ 2]);
}

String _fmtOpsPerSec(Duration d, int iters) {
  final s = d.inMicroseconds / 1e6;
  if (s == 0) return '∞';
  final ops = iters / s;
  if (ops >= 1e6) return '${(ops / 1e6).toStringAsFixed(1)}M';
  if (ops >= 1e3) return '${(ops / 1e3).toStringAsFixed(1)}k';
  return ops.toStringAsFixed(0);
}

String _mdTable(List<String> headers, List<List<String>> rows) {
  final h = '| ${headers.join(' | ')} |\n';
  final sep = '| ${headers.map((_) => '---').join(' | ')} |\n';
  final r = rows.map((c) => '| ${c.join(' | ')} |').join('\n');
  return '$h$sep$r\n';
}

void main(List<String> args) async {
  // Simple arg parsing for: --iterations, --warmup, --rounds, --best-of, --seed
  int readInt(String name, String fallback) {
    final idx = args.indexOf('--$name');
    if (idx != -1 && idx + 1 < args.length) {
      final v = int.tryParse(args[idx + 1]);
      if (v != null && v > 0) return v;
    }
    return int.parse(fallback);
  }

  final iterations = readInt('iterations', '20000');
  final warmup = readInt('warmup', '2000');
  final rounds = readInt('rounds', '3');
  final bestOf = readInt('best-of', '1');
  int seed = 42;
  final seedIdx = args.indexOf('--seed');
  if (seedIdx != -1 && seedIdx + 1 < args.length) {
    seed = int.tryParse(args[seedIdx + 1]) ?? 42;
  }

  Duration timeTask(Task task) =>
      _timeWithWarmup(task, iterations, warmup: warmup, rounds: rounds);

  Duration runBestOf(Task task) {
    if (bestOf <= 1) return timeTask(task);
    Duration best = const Duration(days: 3650);
    for (var i = 0; i < bestOf; i++) {
      final d = timeTask(task);
      if (d < best) best = d;
    }
    return best;
  }

  final rnd = Random(seed);
  final sizes = List<double>.generate(2000, (i) => 100 + i * 123.456);
  final samples = List.generate(500, (_) => sizes[rnd.nextInt(sizes.length)]);
  final os = Platform.operatingSystem;
  final cores = Platform.numberOfProcessors;
  final dartVer = Platform.version.split(' ').first;

  // Bench 1: Humanize (SI, bytes)
  final bcSiHuman = runBestOf(() {
    final v = samples[rnd.nextInt(samples.length)];
    ByteConverter(v).toHumanReadableAuto(standard: ByteStandard.si);
  });
  final bcSiHumanRich = runBestOf(() {
    final v = samples[rnd.nextInt(samples.length)];
    ByteConverter(v).toHumanReadableAutoWith(
        const ByteFormatOptions(locale: 'en', useGrouping: true));
  });
  final fsSiHuman = runBestOf(() {
    final v = samples[rnd.nextInt(samples.length)];
    fs.filesize(v.toInt(), 1); // expects integer bytes
  });

  // Bench 1b: Humanize (IEC, bits) — no direct competitor in tested set
  final bcIecBitsHuman = runBestOf(() {
    final v = samples[rnd.nextInt(samples.length)];
    ByteConverter(v)
        .toHumanReadableAuto(standard: ByteStandard.iec, useBits: true);
  });

  // Bench 2: Parse (common forms)
  final parseInputs = ['1.5 GB', '2 GiB', '999 KB', '12.5 MB'];
  final bcParse = runBestOf(() {
    final s = parseInputs[rnd.nextInt(parseInputs.length)];
    ByteConverter.parse(s);
  });

  // Bench 3: DataRate humanize per:min
  final rate = DataRate.megaBitsPerSecond(200);
  final bcRate = runBestOf(() {
    rate.toHumanReadableAuto(per: 'min');
  });

  // Bench 4: Compound formatting
  final bcCompound = runBestOf(() {
    final v = samples[rnd.nextInt(samples.length)];
    ByteConverter(v).toHumanReadableCompound();
  });

  // Bench 5: BigByteConverter humanize
  final bigSamples =
      List.generate(500, (_) => (rnd.nextDouble() * 1e12).toInt());
  final bcBigHuman = runBestOf(() {
    final idx = rnd.nextInt(bigSamples.length);
    final v = bigSamples[idx];
    BigByteConverter(BigInt.from(v)).toHumanReadableAuto();
  });

  // Bench 6: Localized humanize (en) using intl
  final bcLocalized = runBestOf(() {
    final v = samples[rnd.nextInt(samples.length)];
    ByteConverter(v)
        .toHumanReadableAutoWith(const ByteFormatOptions(locale: 'en'));
  });

  // Bench 7: Pattern formatting
  final bcPattern = runBestOf(() {
    final v = samples[rnd.nextInt(samples.length)];
    ByteConverter(v)
        .formatWith('S0.0 u', options: const ByteFormatOptions(signed: true));
  });

  // P² vs TDigest (throughput only)
  final stream = List<double>.generate(20000, (_) => rnd.nextDouble());
  final p2 = StreamingQuantiles([0.5, 0.95, 0.99]);
  final td = StreamingQuantiles.tDigest(compression: 200);
  final swP2 = Stopwatch()..start();
  for (final x in stream) {
    p2.add(x);
  }
  swP2.stop();
  final swTd = Stopwatch()..start();
  for (final x in stream) {
    td.add(x);
  }
  swTd.stop();

  final rowsCore = <List<String>>[
    [
      'Humanize (SI, bytes)',
      _fmtOpsPerSec(bcSiHuman, iterations),
      _fmtOpsPerSec(fsSiHuman, iterations)
    ],
    [
      'Humanize (SI, bytes, locale+grouping)',
      _fmtOpsPerSec(bcSiHumanRich, iterations),
      '—'
    ],
    ['Humanize (IEC, bits)', _fmtOpsPerSec(bcIecBitsHuman, iterations), '—'],
    ['Parse (sizes)', _fmtOpsPerSec(bcParse, iterations), '—'],
    ['Rate humanize (/min)', _fmtOpsPerSec(bcRate, iterations), '—'],
    ['Compound (mixed units)', _fmtOpsPerSec(bcCompound, iterations), '—'],
    ['BigByteConverter humanize', _fmtOpsPerSec(bcBigHuman, iterations), '—'],
    ['Humanize localized (en)', _fmtOpsPerSec(bcLocalized, iterations), '—'],
    ['Pattern formatting', _fmtOpsPerSec(bcPattern, iterations), '—'],
  ];

  final rowsQuant = <List<String>>[
    ['P² ingest ops/s', _fmtOpsPerSec(swP2.elapsed, stream.length)],
    ['TDigest ingest ops/s', _fmtOpsPerSec(swTd.elapsed, stream.length)],
  ];

  final buf = StringBuffer();
  buf.writeln('# Benchmarks');
  buf.writeln();
  buf.writeln('Microbenchmarks measured on this machine.');
  buf.writeln();
  buf.writeln('- OS: $os');
  buf.writeln('- CPU cores: $cores');
  buf.writeln('- Dart: $dartVer');
  buf.writeln('- Seed: $seed');
  buf.writeln('- Iterations: $iterations');
  buf.writeln('- Warmup: $warmup');
  buf.writeln('- Rounds: $rounds');
  buf.writeln('- Best-of: $bestOf');
  buf.writeln();
  buf.writeln('## Core operations');
  buf.writeln('Competitor for humanize: `filesize`');
  buf.writeln(_mdTable(
      ['Task', 'ByteConverter (ops/s)', 'filesize (ops/s)'], rowsCore));
  buf.writeln();
  buf.writeln('## Streaming quantiles');
  buf.writeln(_mdTable(['Task', 'Throughput (ops/s)'], rowsQuant));
  buf.writeln();
  buf.writeln('## Competitor coverage');
  final coverageRows = <List<String>>[
    ['Humanize (SI, bytes)', 'Yes', '`filesize`', 'Yes'],
    ['Humanize (IEC, bits)', 'Yes', '—', '—'],
    ['Pattern formatting', 'Yes', '—', '—'],
    ['Compound formatting', 'Yes', '—', '—'],
    ['Parsing sizes', 'Yes', '—', '—'],
    ['Parsing data rates', 'Yes', '—', '—'],
    ['Rate humanize', 'Yes', '—', '—'],
    ['BigInt precision', 'Yes', '—', '—'],
    [
      'Streaming quantiles',
      'Yes (P², TDigest)',
      '— (external TDigest libs may exist)',
      'Compared internal P² vs TDigest'
    ],
  ];
  buf.writeln(_mdTable(
      ['Feature', 'ByteConverter', 'Competitor(s)', 'Included?'],
      coverageRows));
  buf.writeln();
  buf.writeln('## Notes');
  buf.writeln(
      '- Methodology: median of ROUNDS timed rounds over ITERATIONS iterations, after ~WARMUP warmup calls; overall result is best-of BESTOF runs.');
  buf.writeln(
      '- Values: ROUNDS=$rounds, ITERATIONS=$iterations, WARMUP=$warmup, BESTOF=$bestOf, SEED=$seed');
  buf.writeln(
      '- The competitor `filesize` is a focused formatter for SI bytes and returns a string; it does not handle IEC bits, compound, parsing, or rates.');
  buf.writeln(
      '- ByteConverter supports many options (IEC/SI/JEDEC, bits/bytes, locale/grouping, NBSP, fixed width, patterns, compound, parsing, rates, BigInt). Some options (e.g., locale/grouping) add overhead as shown in the locale+grouping row.');
  buf.writeln(
      '- Microbenchmarks can vary across machines and runs. Consider running this script locally to compare on your environment.');
  buf.writeln(
      '- Repro tips (Windows): use High Performance/Ultimate power plan, plug in AC power on laptops, close background apps, and run a few times (best-of) to reduce scheduler noise.');

  final outPath = 'wiki/Benchmarks.md';
  await File(outPath).writeAsString(buf.toString());
  stdout.writeln('Wrote $outPath');
  stdout.writeln('\n${buf.toString()}');
}
