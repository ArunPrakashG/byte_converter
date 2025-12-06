import 'package:byte_converter/byte_converter.dart';
import 'package:test/test.dart';

void main() {
  group('NetworkOverhead', () {
    test('fractionForPacket typical Ethernet+IPv4+TCP', () {
      // MTU 1500; headers 18+20+20; payload 1442
      final fraction = NetworkOverhead.fractionForPacket(
        payloadBytes: 1442,
        l2Bytes: 18,
        l3Bytes: 20,
        l4Bytes: 20,
        preambleBytes: 8,
        interframeGapBytes: 12,
      );
      expect(fraction, closeTo(78 / 1520, 1e-6));
    });

    test('typicalFractionEthernetIpv4Tcp preset', () {
      final fraction =
          NetworkOverhead.typicalFractionEthernetIpv4Tcp(mtu: 1500);
      expect(fraction, closeTo(78 / 1520, 1e-6));
    });

    test('effectiveRate applies fraction', () {
      final nominal = DataRate.megaBitsPerSecond(100); // 100 Mb/s
      final eff = NetworkOverhead.effectiveRate(nominal, overheadFraction: 0.1);
      expect(eff.bitsPerSecond, closeTo(90e6, 1e-3));
    });

    test('effectiveRateForPacket approximates overhead for MTU=1500', () {
      final nominal = DataRate.gigaBitsPerSecond(1); // 1 Gb/s
      final eff = NetworkOverhead.effectiveRateForPacket(nominal);
      // Expected ~ (1 - 78/1520) * 1e9 bps
      final expected = (1 - (78 / 1520)) * 1e9;
      expect(eff.bitsPerSecond, closeTo(expected, 1e5));
    });

    test('effectiveRateEthernetIpv4Tcp preset', () {
      final nominal = DataRate.gigaBitsPerSecond(1); // 1 Gb/s
      final eff =
          NetworkOverhead.effectiveRateEthernetIpv4Tcp(nominal, mtu: 1500);
      final expected = (1 - (78 / 1520)) * 1e9;
      expect(eff.bitsPerSecond, closeTo(expected, 1e5));
    });
  });

  group('TransferPlan overhead durations', () {
    test('estimated and remaining duration with overhead', () {
      final total = ByteConverter.fromGigaBytes(1); // 1 GB
      final rate = DataRate.megaBytesPerSecond(100); // 100 MB/s nominal
      final plan = total.estimateTransfer(rate);

      final noOverheadTotal = plan.estimatedTotalDuration;
      final withOverheadTotal = plan.estimatedTotalDurationWithOverhead(0.1);
      expect(noOverheadTotal, isNotNull);
      expect(withOverheadTotal, isNotNull);
      // Overhead increases total duration
      expect(withOverheadTotal!.inSeconds,
          greaterThan(noOverheadTotal!.inSeconds));

      final noOverheadRemaining = plan.remainingDuration;
      final withOverheadRemaining = plan.remainingDurationWithOverhead(0.1);
      expect(noOverheadRemaining, isNotNull);
      expect(withOverheadRemaining, isNotNull);
      expect(withOverheadRemaining!.inSeconds,
          greaterThan(noOverheadRemaining!.inSeconds));
    });
  });
}
