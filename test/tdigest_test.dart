import 'dart:math';

import 'package:byte_converter/byte_converter_full.dart';
import 'package:test/test.dart';

void main() {
  group('TDigest', () {
    test('uniform [0,1) quantiles', () {
      final t = TDigest(compression: 200);
      final rnd = Random(1);
      final data = List<double>.generate(5000, (_) => rnd.nextDouble());
      for (final x in data) {
        t.add(x);
      }

      data.sort();
      double exact(double p) {
        final r = p * (data.length - 1);
        final lo = r.floor();
        final hi = r.ceil();
        if (lo == hi) return data[lo];
        return data[lo] + (data[hi] - data[lo]) * (r - lo);
      }

      expect((t.quantile(0.5) - exact(0.5)).abs(), lessThan(0.03));
      expect((t.quantile(0.95) - exact(0.95)).abs(), lessThan(0.05));
      expect((t.quantile(0.99) - exact(0.99)).abs(), lessThan(0.07));
    });

    test('normal-like quantiles', () {
      final t = TDigest(compression: 200);
      final rnd = Random(2);
      double normal() {
        final u1 = max(rnd.nextDouble(), 1e-9);
        final u2 = rnd.nextDouble();
        final r = sqrt(-2 * log(u1));
        final th = 2 * pi * u2;
        return r * cos(th);
      }

      final data = List<double>.generate(8000, (_) => 100 + 20 * normal());
      for (final x in data) {
        t.add(x);
      }
      data.sort();

      double exact(double p) {
        final r = p * (data.length - 1);
        final lo = r.floor();
        final hi = r.ceil();
        if (lo == hi) return data[lo];
        return data[lo] + (data[hi] - data[lo]) * (r - lo);
      }

      expect((t.quantile(0.5) - exact(0.5)).abs(), lessThan(1.5));
      expect((t.quantile(0.95) - exact(0.95)).abs(), lessThan(3.5));
      expect((t.quantile(0.99) - exact(0.99)).abs(), lessThan(6));
    });
  });
}
