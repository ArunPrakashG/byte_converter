import 'dart:math';

import 'package:byte_converter/byte_converter_full.dart';
import 'package:test/test.dart';

void main() {
  group('StreamingQuantiles (P²)', () {
    test('estimates p50/p95/p99 within tolerance on normal-like data', () {
      final rnd = Random(42);
      final sq = StreamingQuantiles([0.5, 0.95, 0.99]);
      final samples = <double>[];

      // Generate 10k samples ~N(1000, 200)
      double boxMuller() {
        // Basic Box-Muller
        final u1 = max(rnd.nextDouble(), 1e-12);
        final u2 = rnd.nextDouble();
        final r = sqrt(-2.0 * log(u1));
        final theta = 2 * pi * u2;
        return r * cos(theta);
      }

      for (var i = 0; i < 10000; i++) {
        final v = 1000 + 200 * boxMuller();
        samples.add(v);
        sq.add(v);
      }

      samples.sort();
      double exact(double p) {
        final rank = p * (samples.length - 1);
        final lo = rank.floor();
        final hi = rank.ceil();
        if (lo == hi) return samples[lo];
        return samples[lo] + (samples[hi] - samples[lo]) * (rank - lo);
      }

      final p50e = exact(0.5);
      final p95e = exact(0.95);
      final p99e = exact(0.99);

      final p50 = sq.estimate(50);
      final p95 = sq.estimate(95);
      final p99 = sq.estimate(99);

      // Tolerances are loose; P² is approximate and our init is simplified
      expect((p50 - p50e).abs(), lessThan(25));
      expect((p95 - p95e).abs(), lessThan(40));
      expect((p99 - p99e).abs(), lessThan(60));
    });

    test('fallback exact percentile before initialization', () {
      final sq = StreamingQuantiles([0.5]);
      sq.add(10);
      sq.add(20);
      sq.add(30);
      // Not initialized until 5 samples, so uses exact percentile over buffer
      expect(sq.estimate(50), closeTo(20, 1e-6));
      sq.add(40);
      sq.add(50); // initialize
      // After initialization, estimate still near 30 (median ~30 for 10..50 sample)
      expect(sq.estimate(50), closeTo(30, 10));
    });
  });
}
