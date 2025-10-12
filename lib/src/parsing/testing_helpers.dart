part of '../_parsing.dart';

// Test-only forwarding helpers to validate internal behaviors without exposing them publicly.
// Not exported in the public API; referenced by tests via package:byte_converter/src/_parsing.dart import.

/// Exposes the internal unit symbol resolver for tests.
String testUnitSymbolFor(
  String chosenSymbol,
  bool useBits,
  ByteStandard effectiveStandard,
  HumanizeOptions opt,
) =>
    _unitSymbolFor(chosenSymbol, useBits, effectiveStandard, opt);

/// Exposes the internal sign prefix logic for tests.
String testSignedPrefixFor(double v, HumanizeOptions opt) =>
    _signedPrefixFor(v, opt);
