# ByteConverter

Provides a simple interface for conversion of Digital values such as Bytes, KiloBytes etc.

Created from templates made available by Stagehand under a BSD-style
[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).

## Usage

A simple usage example:

```dart
import 'package:byte_converter/byte_converter.dart';

main() {
  double bytes = 100000;

  ByteConverter converter = ByteConverter(bytes);
  print('$bytes bytes is ${converter.kiloBytes} Kb');
  print('$bytes bytes is ${converter.megaBytes} Mb');
  print('$bytes bytes is ${converter.gigaBytes} Gb');
  print('$bytes bytes is ${converter.teraBytes} Tb');

  // or

  double gigaByte = 70.5;
  converter = ByteConverter.fromGigaBytes(gigaByte);
  print('$bytes bytes is ${converter.kiloBytes} Kb');
  print('$bytes bytes is ${converter.megaBytes} Mb');
  print('$bytes bytes is ${converter.gigaBytes} Gb');
  print('$bytes bytes is ${converter.teraBytes} Tb');
}
```

## License

This project is licensed under MIT License. Read about it here: [MIT License](license)

## Features and bugs

Please file feature requests and bugs here [issue tracker][tracker].

[tracker]: https://github.com/ArunPrakashG/byte_converter/issues
[license]: https://github.com/ArunPrakashG/byte_converter/blob/553e21c54c5625e18cbf49c3338b884892e728c1/LICENSE
