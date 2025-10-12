// no imports

/// Lightweight t-digest implementation for streaming quantile estimation.
///
/// Keeps sorted centroids and greedily compresses using a size bound based on
/// cumulative quantile position. Quantiles are estimated via boundary
/// interpolation between adjacent centroids.
class TDigest {
  /// Creates a t-digest with a target [compression] (cluster upper bound).
  /// Higher values use more memory and provide more accurate tails.
  TDigest({this.compression = 200}) : assert(compression > 20);

  /// Target compression parameter controlling cluster sizes.
  final int compression;
  final List<_Centroid> _centroids = <_Centroid>[];
  double _count = 0;

  /// Total weight of all samples added.
  double get count => _count;

  /// Adds a single sample [x] with optional weight [w] (default 1).
  void add(double x, [double w = 1]) {
    if (x.isNaN || x.isInfinite) return;
    if (w <= 0) return;
    _count += w;
    // Insert in sorted order
    final i = _lowerBound(x);
    if (i < _centroids.length && (_centroids[i].mean - x).abs() <= 1e-12) {
      _centroids[i].add(x, w);
    } else {
      _centroids.insert(i, _Centroid(x, w));
    }
    _compress();
  }

  /// Adds all values from [values] with unit weight.
  void addAll(Iterable<double> values) {
    for (final v in values) {
      add(v);
    }
  }

  /// Estimates the value at quantile [q] where q is in [0,1].
  double quantile(double q) {
    if (_centroids.isEmpty) return double.nan;
    if (q <= 0) return _centroids.first.mean;
    if (q >= 1) return _centroids.last.mean;
    final target = q * _count;

    // Precompute boundaries for interpolation
    final lowerBounds = List<double>.filled(_centroids.length, 0);
    final upperBounds = List<double>.filled(_centroids.length, 0);
    for (var i = 0; i < _centroids.length; i++) {
      final c = _centroids[i];
      final prev = i > 0 ? _centroids[i - 1] : null;
      final next = i + 1 < _centroids.length ? _centroids[i + 1] : null;
      lowerBounds[i] = prev == null ? c.mean : (prev.mean + c.mean) / 2;
      upperBounds[i] = next == null ? c.mean : (c.mean + next.mean) / 2;
    }

    var cum = 0.0;
    for (var i = 0; i < _centroids.length; i++) {
      final c = _centroids[i];
      final nextCum = cum + c.weight;
      if (target <= nextCum) {
        final prop = ((target - cum) / c.weight).clamp(0.0, 1.0);
        final lo = lowerBounds[i];
        final hi = upperBounds[i];
        return lo + (hi - lo) * prop;
      }
      cum = nextCum;
    }
    return _centroids.last.mean;
  }

  void _compress() {
    if (_centroids.length <= 1) return;
    final total = _count;
    final merged = <_Centroid>[];
    var cum = 0.0;
    var current = _centroids.first.copy();

    double maxClusterSize(double q) {
      // Standard size bound used in many t-digest implementations
      return (4 * total * q * (1 - q)) / compression;
    }

    for (var i = 1; i < _centroids.length; i++) {
      final c = _centroids[i];
      final q = (cum + current.weight + c.weight) / total; // center of merged
      final cap = maxClusterSize(q);
      if (current.weight + c.weight <= cap || current.weight <= 1e-12) {
        current.absorb(c);
      } else {
        merged.add(current);
        cum += current.weight;
        current = c.copy();
      }
    }
    merged.add(current);
    _centroids
      ..clear()
      ..addAll(merged);
  }

  int _lowerBound(double x) {
    var lo = 0, hi = _centroids.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_centroids[mid].mean < x) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}

class _Centroid {
  _Centroid(this.mean, this.weight);
  double mean;
  double weight;

  void add(double x, double w) {
    final total = weight + w;
    mean = (mean * weight + x * w) / total;
    weight = total;
  }

  void absorb(_Centroid other) => add(other.mean, other.weight);
  _Centroid copy() => _Centroid(mean, weight);
}
