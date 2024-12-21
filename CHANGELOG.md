# Changelog

## 1.0.0

- Initial version, with base methods.

## 1.1.0

- Implemented various static methods for conversion to and from digital values.
- Implemented properties to make it easier to get different types of digital values for the value which is used to instantiate the ByteConvert instance.

## 1.2.0

- Renamed toHumanReadableString(...) to toHumanReadable(...) to simplify the api.

## 1.3.0

- Upgrade to null safety.

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
