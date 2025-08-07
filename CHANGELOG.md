# Changelog

## 2.1.0

### Added - BigInt Support

- **BigByteConverter**: New class for arbitrary precision byte calculations using BigInt
- **Extended unit support**: Added Exabytes (EB), Zettabytes (ZB), and Yottabytes (YB) for both decimal and binary units
- **BigInt extensions**: Extensions for BigInt type to create BigByteConverter instances
- **Exact arithmetic methods**: `*Exact` getters that return BigInt values without precision loss
- **Cross-type conversion**: Convert between ByteConverter and BigByteConverter
- **Large-scale JSON serialization**: Support for serializing/deserializing extremely large numbers

### Use Cases for BigInt Support

- Data center storage calculations requiring exact precision
- Scientific computing with massive datasets
- Cryptographic applications where precision is critical
- Blockchain and distributed systems with large data requirements
- Future-proofing for exascale computing scenarios

### API Examples

```dart
// Ultra-precise calculations
final dataCenter = BigByteConverter.fromExaBytes(BigInt.from(5));
final cosmic = BigByteConverter.fromYottaBytes(BigInt.one);

// BigInt extensions
final huge = BigInt.parse('999999999999999999999').bytes;

// Exact arithmetic (no precision loss)
final exact = BigInt.from(1000000000).bytes;
print(exact.gigaBytesExact); // BigInt result
print(exact.gigaBytes);      // double approximation
```

## 2.0.0

### Breaking Changes

- Made ByteConverter class immutable
- Changed static factory methods to named constructors
- Removed deprecated methods
- Updated precision handling for integer values

### Added

- Binary unit support (KiB, MiB, GiB, TiB, PiB)
- Extension methods for fluent API
- JSON serialization support
- Math operations (+, -, \*, /)
- Comparison operators
- Cached calculations for better performance
- `Comparable` interface implementation

### Optimized

- String formatting and caching
- Unit conversion calculations
- Memory usage with lazy initialization
- Binary search for best unit selection
- Precision handling for whole numbers

### Fixed

- Incorrect KB unit display in string output
- Precision handling for integer values
- Memory leaks from repeated calculations
- Unit conversion accuracy
