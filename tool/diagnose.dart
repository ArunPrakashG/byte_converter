import 'package:byte_converter/byte_converter.dart';

void main() {
  final r = DataRate.tryParse('100 Mbps + 50 Mbps');
  print(
      'isSuccess=${r.isSuccess} err=${r.error?.message} normalized=${r.normalizedInput} detected=${r.detectedUnit}');
}
