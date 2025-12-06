import '../data_rate.dart';

/// Network overhead estimation utilities.
///
/// Provides helpers to model protocol/link overhead and compute effective
/// payload throughput from nominal link speeds.
abstract class NetworkOverhead {
  NetworkOverhead._();

  /// Estimates the overhead fraction for a single packet/frame.
  ///
  /// Defaults reflect typical Ethernet + IPv4 + TCP minimum headers plus
  /// preamble and interframe gap on the wire.
  ///
  /// Returns a fraction in [0,1]: overhead / (overhead + payload).
  static double fractionForPacket({
    required int payloadBytes,
    int l2Bytes = 18, // Ethernet header + FCS (14 + 4)
    int l3Bytes = 20, // IPv4 base header (no options)
    int l4Bytes = 20, // TCP base header (no options)
    int preambleBytes = 8, // 7-byte preamble + 1-byte SFD
    int interframeGapBytes = 12, // 12-byte IFG
  }) {
    final overhead =
        l2Bytes + l3Bytes + l4Bytes + preambleBytes + interframeGapBytes;
    final total = overhead + payloadBytes;
    if (total <= 0) return 0.0;
    return overhead / total;
  }

  /// Convenience preset: typical Ethernet + IPv4 + TCP overhead fraction.
  ///
  /// Uses a standard [mtu] of 1500 by default and minimum header sizes.
  static double typicalFractionEthernetIpv4Tcp({int mtu = 1500}) {
    const l2Bytes = 18;
    const l3Bytes = 20;
    const l4Bytes = 20;
    const preambleBytes = 8;
    const interframeGapBytes = 12;
    final headers = l2Bytes + l3Bytes + l4Bytes;
    final payloadBytes = mtu - headers;
    if (payloadBytes <= 0) return 0.0;
    return fractionForPacket(
      payloadBytes: payloadBytes,
      l2Bytes: l2Bytes,
      l3Bytes: l3Bytes,
      l4Bytes: l4Bytes,
      preambleBytes: preambleBytes,
      interframeGapBytes: interframeGapBytes,
    );
  }

  /// Applies a simple overhead fraction to compute effective payload rate.
  static DataRate effectiveRate(
    DataRate nominal, {
    double overheadFraction = 0.0,
  }) {
    final fraction = overheadFraction.clamp(0.0, 1.0);
    final bps = nominal.bitsPerSecond * (1.0 - fraction);
    return DataRate.bitsPerSecond(bps);
  }

  /// Computes effective payload rate using a packet-level overhead model.
  ///
  /// Uses the [mtu] and header defaults to estimate per-packet payload and
  /// derive an overhead fraction via [fractionForPacket]. Assumes full-size
  /// packets under steady-state transmission.
  static DataRate effectiveRateForPacket(
    DataRate nominal, {
    int mtu = 1500,
    int l2Bytes = 18,
    int l3Bytes = 20,
    int l4Bytes = 20,
    int preambleBytes = 8,
    int interframeGapBytes = 12,
  }) {
    final headers = l2Bytes + l3Bytes + l4Bytes;
    final payloadBytes = mtu - headers;
    if (payloadBytes <= 0) {
      return DataRate.bitsPerSecond(0);
    }
    final fraction = fractionForPacket(
      payloadBytes: payloadBytes,
      l2Bytes: l2Bytes,
      l3Bytes: l3Bytes,
      l4Bytes: l4Bytes,
      preambleBytes: preambleBytes,
      interframeGapBytes: interframeGapBytes,
    );
    return effectiveRate(nominal, overheadFraction: fraction);
  }

  /// Convenience preset: effective payload rate for Ethernet + IPv4 + TCP.
  static DataRate effectiveRateEthernetIpv4Tcp(DataRate nominal,
      {int mtu = 1500}) {
    return effectiveRateForPacket(nominal, mtu: mtu);
  }
}
