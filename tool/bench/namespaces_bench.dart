import 'dart:math';

import 'package:byte_converter/byte_converter.dart';

/// Benchmark for the new namespace features.
///
/// Run with: dart run tool/bench/namespaces_bench.dart

typedef Task = void Function();

class _Bench {
  _Bench(this.name, this.task) : iterations = 20000;
  final String name;
  final Task task;
  final int iterations;

  void run() {
    // Warmup
    for (var i = 0; i < 100; i++) {
      task();
    }

    final sw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      task();
    }
    sw.stop();
    final ms = sw.elapsedMilliseconds;
    final us = sw.elapsedMicroseconds;
    final usPerOp = us / iterations;
    final ips = iterations / (us / 1e6);
    print(
        '[BENCH] $name: ${ms}ms for $iterations iters  -> ${usPerOp.toStringAsFixed(2)} µs/op  -> ${ips.toStringAsFixed(0)} ops/s');
  }
}

void main(List<String> args) {
  // Sample data
  final sizes = List<double>.generate(1000, (i) => 100 + i * 123.456);
  final rnd = Random(42);

  // Pre-create converters for more accurate benchmarking
  final converters = sizes.map((s) => ByteConverter(s)).toList();
  final comparePairs = List.generate(100, (i) {
    final a = converters[rnd.nextInt(converters.length)];
    final b = converters[rnd.nextInt(converters.length)];
    return (a, b);
  });

  print('=' * 60);
  print('Namespace Feature Benchmarks');
  print('=' * 60);
  print('');

  // Baseline benchmark
  print('--- Baseline (existing humanize) ---');
  final baselineTasks = <_Bench>[
    _Bench('humanize(si)', () {
      final c = converters[rnd.nextInt(converters.length)];
      c.toHumanReadableAuto(standard: ByteStandard.si);
    }),
  ];
  for (final b in baselineTasks) {
    b.run();
  }

  print('');
  print('--- Display Namespace ---');
  final displayTasks = <_Bench>[
    _Bench('display.fuzzy', () {
      final c = converters[rnd.nextInt(converters.length)];
      c.display.fuzzy;
    }),
    _Bench('display.scientific()', () {
      final c = converters[rnd.nextInt(converters.length)];
      c.display.scientific();
    }),
    _Bench('display.scientific(ascii)', () {
      final c = converters[rnd.nextInt(converters.length)];
      c.display.scientific(ascii: true);
    }),
    _Bench('display.fractional()', () {
      final c = converters[rnd.nextInt(converters.length)];
      c.display.fractional();
    }),
    _Bench('display.gnu()', () {
      final c = converters[rnd.nextInt(converters.length)];
      c.display.gnu();
    }),
    _Bench('display.fullWords()', () {
      final c = converters[rnd.nextInt(converters.length)];
      c.display.fullWords();
    }),
    _Bench('display.withCommas()', () {
      final c = converters[rnd.nextInt(converters.length)];
      c.display.withCommas();
    }),
  ];
  for (final b in displayTasks) {
    b.run();
  }

  print('');
  print('--- Output Namespace ---');
  final outputTasks = <_Bench>[
    _Bench('output.asArray', () {
      final c = converters[rnd.nextInt(converters.length)];
      c.output.asArray;
    }),
    _Bench('output.asTuple', () {
      final c = converters[rnd.nextInt(converters.length)];
      c.output.asTuple;
    }),
    _Bench('output.asMap', () {
      final c = converters[rnd.nextInt(converters.length)];
      c.output.asMap;
    }),
    _Bench('output.exponent', () {
      final c = converters[rnd.nextInt(converters.length)];
      c.output.exponent;
    }),
    _Bench('output.unitLevel', () {
      final c = converters[rnd.nextInt(converters.length)];
      c.output.unitLevel;
    }),
    _Bench('output.asJson', () {
      final c = converters[rnd.nextInt(converters.length)];
      c.output.asJson;
    }),
  ];
  for (final b in outputTasks) {
    b.run();
  }

  print('');
  print('--- Comparison Namespace ---');
  final compareTasks = <_Bench>[
    _Bench('compare.percentOf', () {
      final pair = comparePairs[rnd.nextInt(comparePairs.length)];
      pair.$1.compare.percentOf(pair.$2);
    }),
    _Bench('compare.percentageBar', () {
      final pair = comparePairs[rnd.nextInt(comparePairs.length)];
      pair.$1.compare.percentageBar(pair.$2);
    }),
    _Bench('compare.relativeTo', () {
      final pair = comparePairs[rnd.nextInt(comparePairs.length)];
      pair.$1.compare.relativeTo(pair.$2);
    }),
    _Bench('compare.difference', () {
      final pair = comparePairs[rnd.nextInt(comparePairs.length)];
      pair.$1.compare.difference(pair.$2);
    }),
    _Bench('compare.ratio', () {
      final pair = comparePairs[rnd.nextInt(comparePairs.length)];
      pair.$1.compare.ratio(pair.$2);
    }),
    _Bench('compare.clamp', () {
      final c = converters[rnd.nextInt(converters.length)];
      final min = ByteConverter.fromKiloBytes(100);
      final max = ByteConverter.fromMegaBytes(100);
      c.compare.clamp(min, max);
    }),
    _Bench('ByteComparison.compressionRatio', () {
      final pair = comparePairs[rnd.nextInt(comparePairs.length)];
      ByteComparison.compressionRatio(pair.$1, pair.$2);
    }),
  ];
  for (final b in compareTasks) {
    b.run();
  }

  print('');
  print('--- Accessibility Namespace ---');
  final accessTasks = <_Bench>[
    _Bench('accessibility.screenReader', () {
      final c = converters[rnd.nextInt(converters.length)];
      c.accessibility.screenReader();
    }),
    _Bench('accessibility.ariaLabel', () {
      final c = converters[rnd.nextInt(converters.length)];
      c.accessibility.ariaLabel();
    }),
    _Bench('accessibility.voiceDescription', () {
      final c = converters[rnd.nextInt(converters.length)];
      c.accessibility.voiceDescription();
    }),
    _Bench('accessibility.summary', () {
      final c = converters[rnd.nextInt(converters.length)];
      c.accessibility.summary();
    }),
  ];
  for (final b in accessTasks) {
    b.run();
  }

  print('');
  print('=' * 60);
  print('Benchmark Summary');
  print('=' * 60);
  print('');
  print('Target performance (from todo.md):');
  print('  display.fuzzy              < 5µs');
  print('  display.scientific         < 3µs');
  print('  display.gnu                < 2µs');
  print('  output.asArray             < 1µs');
  print('  output.asTuple             < 0.5µs');
  print('  compare.percentOf          < 1µs');
  print('  accessibility.screenReader < 10µs');
  print('');
}
