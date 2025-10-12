class ByteRange {
  ByteRange(this.start, this.end)
      : assert(start >= BigInt.zero && end >= BigInt.zero && end >= start,
            'Invalid range: start <= end and both non-negative');

  final BigInt start;
  final BigInt end; // inclusive-exclusive [start, end)

  BigInt get length => end - start;

  bool intersects(ByteRange other) {
    return start < other.end && other.start < end;
  }

  ByteRange? intersection(ByteRange other) {
    if (!intersects(other)) return null;
    final s = start > other.start ? start : other.start;
    final e = end < other.end ? end : other.end;
    return ByteRange(s, e);
  }

  List<ByteRange> subtract(ByteRange other) {
    final i = intersection(other);
    if (i == null) return [this];
    final result = <ByteRange>[];
    if (start < i.start) result.add(ByteRange(start, i.start));
    if (i.end < end) result.add(ByteRange(i.end, end));
    return result;
  }

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
