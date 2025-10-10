import 'byte_enums.dart';

/// Describes a single alignment class within a [StorageProfile].
class StorageAlignment {
  const StorageAlignment({
    required this.name,
    required this.blockSizeBytes,
    this.rounding,
  })  : assert(name != '', 'Alignment name cannot be empty'),
        assert(blockSizeBytes > 0, 'Block size must be greater than zero');

  /// Human readable name of the alignment bucket (e.g. `sector`, `block`).
  final String name;

  /// Size of the alignment bucket expressed in bytes.
  final int blockSizeBytes;

  /// Optional override for rounding behaviour when aligning to this bucket.
  final RoundingMode? rounding;
}

/// Defines storage alignment preferences used by byte converters when rounding
/// to device specific buckets.
class StorageProfile {
  StorageProfile({
    required List<StorageAlignment> alignments,
    String? defaultAlignment,
    this.defaultRounding = RoundingMode.ceil,
  })  : assert(
          alignments.isNotEmpty,
          'StorageProfile requires at least one alignment',
        ),
        _alignments = _buildAlignmentMap(alignments) {
    final key = _normalize(defaultAlignment ?? alignments.first.name);
    if (!_alignments.containsKey(key)) {
      final names = alignments.map((a) => a.name).join(', ');
      throw ArgumentError(
        'Unknown default alignment "$defaultAlignment". Available: $names',
      );
    }
    _defaultAlignmentKey = key;
  }

  factory StorageProfile.single({
    required String name,
    required int blockSizeBytes,
    RoundingMode defaultRounding = RoundingMode.ceil,
    RoundingMode? rounding,
  }) =>
      StorageProfile(
        alignments: [
          StorageAlignment(
            name: name,
            blockSizeBytes: blockSizeBytes,
            rounding: rounding,
          ),
        ],
        defaultAlignment: name,
        defaultRounding: defaultRounding,
      );

  final Map<String, StorageAlignment> _alignments;
  late final String _defaultAlignmentKey;

  /// Fallback rounding behaviour when no per-alignment override is provided.
  final RoundingMode defaultRounding;

  /// All configured alignments in their original declaration order.
  List<StorageAlignment> get alignments =>
      _alignments.values.toList(growable: false);

  /// Returns the canonical name of the default alignment bucket.
  String get defaultAlignment => _alignments[_defaultAlignmentKey]!.name;

  /// Human friendly listing of available alignment names.
  List<String> get alignmentNames => _alignments.values
      .map((alignment) => alignment.name)
      .toList(growable: false);

  /// Checks if an alignment with the provided [name] exists (case insensitive).
  bool hasAlignment(String name) => _alignments.containsKey(_normalize(name));

  /// Resolves an alignment using the provided [name] or falls back to the
  /// profile's default alignment when omitted.
  StorageAlignment resolve([String? name]) {
    final key = name == null ? _defaultAlignmentKey : _normalize(name);
    final alignment = _alignments[key];
    if (alignment == null) {
      final names = alignmentNames.join(', ');
      throw ArgumentError('Unknown alignment "$name". Available: $names');
    }
    return alignment;
  }

  /// Retrieves the block size (in bytes) for the requested alignment.
  int blockSizeBytes([String? alignment]) => resolve(alignment).blockSizeBytes;

  /// Determines the rounding strategy for the specified alignment taking into
  /// account any explicit override supplied by the caller.
  RoundingMode roundingFor({String? alignment, RoundingMode? override}) {
    if (override != null) return override;
    final resolved = resolve(alignment);
    return resolved.rounding ?? defaultRounding;
  }

  static Map<String, StorageAlignment> _buildAlignmentMap(
    List<StorageAlignment> alignments,
  ) {
    final seen = <String, StorageAlignment>{};
    for (final alignment in alignments) {
      final key = _normalize(alignment.name);
      if (seen.containsKey(key)) {
        throw ArgumentError('Duplicate alignment name "${alignment.name}"');
      }
      seen[key] = alignment;
    }
    return Map.unmodifiable(seen);
  }

  static String _normalize(String name) => name.trim().toLowerCase();
}
