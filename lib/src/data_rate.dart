import '_parsing.dart';
import 'byte_enums.dart';
import 'format_options.dart';
// ignore_for_file: prefer_constructors_over_static_methods

/// Represents a network/data rate. Internally stored as bits per second.
class DataRate implements Comparable<DataRate> {
  const DataRate.bitsPerSecond(this._bitsPerSecond)
      : assert(_bitsPerSecond >= 0, 'Rate cannot be negative');

  factory DataRate.bytesPerSecond(double bytesPerSecond) =>
      DataRate.bitsPerSecond(bytesPerSecond * 8.0);

  // Named constructors (SI)
  factory DataRate.kiloBitsPerSecond(double value) =>
      DataRate.bitsPerSecond(value * 1000);
  factory DataRate.megaBitsPerSecond(double value) =>
      DataRate.bitsPerSecond(value * 1000 * 1000);
  factory DataRate.gigaBitsPerSecond(double value) =>
      DataRate.bitsPerSecond(value * 1000 * 1000 * 1000);

  factory DataRate.kiloBytesPerSecond(double value) =>
      DataRate.bytesPerSecond(value * 1000);
  factory DataRate.megaBytesPerSecond(double value) =>
      DataRate.bytesPerSecond(value * 1000 * 1000);
  factory DataRate.gigaBytesPerSecond(double value) =>
      DataRate.bytesPerSecond(value * 1000 * 1000 * 1000);

  // Named constructors (IEC)
  factory DataRate.kibiBitsPerSecond(double value) =>
      DataRate.bitsPerSecond(value * 1024);
  factory DataRate.mebiBitsPerSecond(double value) =>
      DataRate.bitsPerSecond(value * 1024 * 1024);
  factory DataRate.gibiBitsPerSecond(double value) =>
      DataRate.bitsPerSecond(value * 1024 * 1024 * 1024);

  factory DataRate.kibiBytesPerSecond(double value) =>
      DataRate.bytesPerSecond(value * 1024);
  factory DataRate.mebiBytesPerSecond(double value) =>
      DataRate.bytesPerSecond(value * 1024 * 1024);
  factory DataRate.gibiBytesPerSecond(double value) =>
      DataRate.bytesPerSecond(value * 1024 * 1024 * 1024);
  final double _bitsPerSecond;

  double get bitsPerSecond => _bitsPerSecond;
  double get bytesPerSecond => _bitsPerSecond / 8.0;

  Duration transferTimeForBytes(double bytes) {
    if (_bitsPerSecond == 0) return Duration.zero;
    final seconds = (bytes * 8.0) / _bitsPerSecond;
    return Duration(microseconds: (seconds * 1e6).ceil());
  }

  String toHumanReadableAuto({
    ByteStandard standard = ByteStandard.si,
    bool useBytes = false,
    int precision = 2,
    bool showSpace = true,
    bool fullForm = false,
    Map<String, String>? fullForms,
    String? separator,
    String? spacer,
    int? minimumFractionDigits,
    int? maximumFractionDigits,
    bool signed = false,
    String? forceUnit,
  }) {
    final baseBytesPerSec = useBytes ? bytesPerSecond : bitsPerSecond / 8.0;
    // Reuse humanize on bytes per second and then append '/s'
    final res = humanize(
      baseBytesPerSec,
      HumanizeOptions(
        standard: standard,
        useBits: useBytes ? false : true, // if not bytes, use bits
        precision: precision,
        showSpace: showSpace,
        fullForm: fullForm,
        fullForms: fullForms,
        separator: separator,
        spacer: spacer,
        minimumFractionDigits: minimumFractionDigits,
        maximumFractionDigits: maximumFractionDigits,
        signed: signed,
        forceUnit: forceUnit,
      ),
    );
    // Use existing formatted text from humanize (includes sign/spacing/locale), then append '/s'
    final formatted = res.text;
    return '$formatted/s';
  }

  /// Convenience overload using ByteFormatOptions.
  String toHumanReadableAutoWith(ByteFormatOptions options) =>
      toHumanReadableAuto(
        standard: options.standard,
        useBytes: options.useBytes,
        precision: options.precision,
        showSpace: options.showSpace,
        fullForm: options.fullForm,
        fullForms: options.fullForms,
        separator: options.separator,
        spacer: options.spacer,
        minimumFractionDigits: options.minimumFractionDigits,
        maximumFractionDigits: options.maximumFractionDigits,
        signed: options.signed,
        forceUnit: options.forceUnit,
      );

  static DataRate parse(
    String input, {
    ByteStandard standard = ByteStandard.si,
  }) {
    final r = parseRate(input: input, standard: standard);
    return DataRate.bitsPerSecond(r.bitsPerSecond);
  }

  @override
  int compareTo(DataRate other) =>
      _bitsPerSecond.compareTo(other._bitsPerSecond);

  @override
  String toString() => toHumanReadableAuto();
}
