import 'package:byte_converter/byte_converter.dart';

void main() {
  // ignore: omit_local_variable_types
  double bytes = 100000;

  // ignore: omit_local_variable_types
  ByteConverter converter = ByteConverter(bytes);
  print('$bytes bytes is ${converter.kiloBytes} Kb');
  print('$bytes bytes is ${converter.megaBytes} Mb');
  print('$bytes bytes is ${converter.gigaBytes} Gb');
  print('$bytes bytes is ${converter.teraBytes} Tb');

  // or

  // ignore: omit_local_variable_types
  double gigaByte = 70.5;
  converter = ByteConverter.fromGigaBytes(gigaByte);
  print('$bytes bytes is ${converter.kiloBytes} Kb');
  print('$bytes bytes is ${converter.megaBytes} Mb');
  print('$bytes bytes is ${converter.gigaBytes} Gb');
  print('$bytes bytes is ${converter.teraBytes} Tb');
}
