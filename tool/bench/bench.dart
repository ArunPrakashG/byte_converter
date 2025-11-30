import 'dart:math';

import 'package:byte_converter/byte_converter_full.dart';

typedef Task = void Function();

class _Bench {
  _Bench(this.name, this.task) : iterations = 20000;
  final String name;
  final Task task;
  final int iterations;

  void run() {
    final sw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      task();
    }
    sw.stop();
    final ms = sw.elapsedMilliseconds;
    final ips = iterations / (sw.elapsedMicroseconds / 1e6);
    print(
        '[BENCH] $name: ${ms}ms for $iterations iters  -> ${ips.toStringAsFixed(0)} ops/s');
  }
}

void main(List<String> args) {
  // Sample data
  final sizes = List<double>.generate(1000, (i) => 100 + i * 123.456);
  final rates = [
    '100 Mbps',
    '12.5 MB/s',
    '2 GiB/5s + 50 Mbps',
  ];
  final rnd = Random(42);

  // Prepare tasks
  final tasks = <_Bench>[
    _Bench('humanize(size si)', () {
      final v = sizes[rnd.nextInt(sizes.length)];
      final c = ByteConverter(v);
      c.toHumanReadableAuto(standard: ByteStandard.si);
    }),
    _Bench('humanize(size iec bits)', () {
      final v = sizes[rnd.nextInt(sizes.length)];
      final c = ByteConverter(v);
      c.toHumanReadableAuto(standard: ByteStandard.iec, useBits: true);
    }),
    _Bench('compound(size)', () {
      final v = sizes[rnd.nextInt(sizes.length)];
      final c = ByteConverter(v);
      c.toHumanReadableCompound();
    }),
    _Bench('parse(size si)', () {
      ByteConverter.parse('1.5 GB');
    }),
    _Bench('parse(size iec)', () {
      ByteConverter.parse('2 GiB', standard: ByteStandard.iec);
    }),
    _Bench('parse(rate)', () {
      DataRate.parse(rates[rnd.nextInt(rates.length)]);
    }),
    _Bench('parseByteSizeAuto', () {
      parseByteSizeAuto('12.34 GiB', standard: ByteStandard.iec);
    }),
    _Bench('parseLocalized fr', () {
      parseLocalized('1,5 kilooctets', locale: 'fr');
    }),
    _Bench('rate humanize per:min', () {
      final r = DataRate.megaBitsPerSecond(200);
      r.toHumanReadableAuto(per: 'min');
    }),
  ];

  print('Running microbenchmarks (${tasks.length} tasks)...');
  for (final b in tasks) {
    b.run();
  }

  // Accuracy vs throughput comparison: P² vs TDigest on synthetic streams
  print('\n[COMPARE] P² vs TDigest on normal-like stream');
  double normal(Random rnd) {
    final u1 = max(rnd.nextDouble(), 1e-9);
    final u2 = rnd.nextDouble();
    final r = sqrt(-2 * log(u1));
    final th = 2 * pi * u2;
    return r * cos(th);
  }

  final rnd2 = Random(123);
  final stream = List<double>.generate(20000, (_) => 100 + 20 * normal(rnd2));

  // Exact references
  final sorted = stream.toList()..sort();
  double exact(double p) {
    final r = p * (sorted.length - 1);
    final lo = r.floor();
    final hi = r.ceil();
    if (lo == hi) return sorted[lo];
    return sorted[lo] + (sorted[hi] - sorted[lo]) * (r - lo);
  }

  // P²
  final p2 = StreamingQuantiles([0.5, 0.95, 0.99]);
  final swP2 = Stopwatch()..start();
  for (final x in stream) {
    p2.add(x);
  }
  swP2.stop();
  final p2p50 = p2.estimate(50),
      p2p95 = p2.estimate(95),
      p2p99 = p2.estimate(99);

  // TDigest
  final td = StreamingQuantiles.tDigest(compression: 200);
  final swTd = Stopwatch()..start();
  for (final x in stream) {
    td.add(x);
  }
  swTd.stop();
  final tdp50 = td.estimate(50),
      tdp95 = td.estimate(95),
      tdp99 = td.estimate(99);

  print(
      'P²   time=${swP2.elapsedMilliseconds}ms  | p50 err=${(p2p50 - exact(0.5)).abs().toStringAsFixed(2)}  p95 err=${(p2p95 - exact(0.95)).abs().toStringAsFixed(2)}  p99 err=${(p2p99 - exact(0.99)).abs().toStringAsFixed(2)}');
  print(
      'TDig time=${swTd.elapsedMilliseconds}ms  | p50 err=${(tdp50 - exact(0.5)).abs().toStringAsFixed(2)}  p95 err=${(tdp95 - exact(0.95)).abs().toStringAsFixed(2)}  p99 err=${(tdp99 - exact(0.99)).abs().toStringAsFixed(2)}');
}
