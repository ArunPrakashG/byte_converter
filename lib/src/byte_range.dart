/// Inclusive-exclusive byte range [start, end) backed by BigInt.
class ByteRange {
  /// Creates a byte range [start, end). Both bounds must be non-negative and
  /// [end] must be greater than or equal to [start].
  ByteRange(this.start, this.end)
      : assert(start >= BigInt.zero && end >= BigInt.zero && end >= start,
            'Invalid range: start <= end and both non-negative');

  /// Start offset (inclusive).
  final BigInt start;

  /// End offset (exclusive).
  final BigInt end; // inclusive-exclusive [start, end)

  /// Length of the range in bytes.
  BigInt get length => end - start;

  /// Returns true if this range intersects with [other].
  bool intersects(ByteRange other) {
    return start < other.end && other.start < end;
  }

  /// Returns the intersection between this range and [other], or null when
  /// disjoint.
  ByteRange? intersection(ByteRange other) {
    if (!intersects(other)) return null;
    final s = start > other.start ? start : other.start;
    final e = end < other.end ? end : other.end;
    return ByteRange(s, e);
  }

  /// Subtract [other] from this range, returning up to two residual ranges.
  List<ByteRange> subtract(ByteRange other) {
    final i = intersection(other);
    if (i == null) return [this];
    final result = <ByteRange>[];
    if (start < i.start) result.add(ByteRange(start, i.start));
    if (i.end < end) result.add(ByteRange(i.end, end));
    return result;
  }

  /// Minimal union covering this and [other]. Adjacent or overlapping ranges
  /// are merged; disjoint non-adjacent ranges return the covering span.
  ByteRange union(ByteRange other) {
    if (!intersects(other) && end != other.start && other.end != start) {
      // For non-overlapping non-adjacent ranges, return the minimal covering range
      final s = start < other.start ? start : other.start;
      final e = end > other.end ? end : other.end;
      return ByteRange(s, e);
    }
    // Merge overlapping/adjacent
    final s = start < other.start ? start : other.start;
    final e = end > other.end ? end : other.end;
    return ByteRange(s, e);
  }
}
