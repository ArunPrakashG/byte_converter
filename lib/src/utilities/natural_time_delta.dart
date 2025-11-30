/// Human-friendly time descriptions for durations.
///
/// Provides natural language representations of time durations,
/// useful for transfer ETAs, backup estimates, and user-friendly displays.
///
/// Example:
/// ```dart
/// final duration = Duration(minutes: 2, seconds: 30);
/// print(duration.natural);  // "about 2 minutes"
///
/// final short = Duration(milliseconds: 500);
/// print(short.natural);  // "less than a second"
/// ```
class NaturalTimeDelta {
  /// Creates a natural time delta formatter.
  const NaturalTimeDelta(this._duration);

  final Duration _duration;

  /// Returns a natural language description of the duration.
  ///
  /// Examples:
  /// - "less than a second"
  /// - "a few seconds"
  /// - "about 30 seconds"
  /// - "about a minute"
  /// - "about 5 minutes"
  /// - "about an hour"
  /// - "about 2 hours"
  /// - "about a day"
  /// - "about 3 days"
  String get natural {
    final seconds = _duration.inSeconds;
    final minutes = _duration.inMinutes;
    final hours = _duration.inHours;
    final days = _duration.inDays;

    if (seconds < 1) {
      return 'less than a second';
    }
    if (seconds < 5) {
      return 'a few seconds';
    }
    if (seconds < 30) {
      return 'about ${_roundToNearest(seconds, 5)} seconds';
    }
    if (seconds < 60) {
      return 'about ${_roundToNearest(seconds, 10)} seconds';
    }
    if (minutes < 2) {
      return 'about a minute';
    }
    if (minutes < 60) {
      return 'about $minutes minutes';
    }
    if (hours < 2) {
      return 'about an hour';
    }
    if (hours < 24) {
      return 'about $hours hours';
    }
    if (days < 2) {
      return 'about a day';
    }
    if (days < 7) {
      return 'about $days days';
    }
    if (days < 14) {
      return 'about a week';
    }
    if (days < 30) {
      return 'about ${days ~/ 7} weeks';
    }
    if (days < 60) {
      return 'about a month';
    }
    if (days < 365) {
      return 'about ${days ~/ 30} months';
    }
    if (days < 730) {
      return 'about a year';
    }
    return 'about ${days ~/ 365} years';
  }

  /// Returns a precise natural description with more detail.
  ///
  /// Examples:
  /// - "2 minutes and 30 seconds"
  /// - "1 hour and 15 minutes"
  String get precise {
    final seconds = _duration.inSeconds % 60;
    final minutes = _duration.inMinutes % 60;
    final hours = _duration.inHours % 24;
    final days = _duration.inDays;

    final parts = <String>[];

    if (days > 0) {
      parts.add('$days ${days == 1 ? 'day' : 'days'}');
    }
    if (hours > 0) {
      parts.add('$hours ${hours == 1 ? 'hour' : 'hours'}');
    }
    if (minutes > 0) {
      parts.add('$minutes ${minutes == 1 ? 'minute' : 'minutes'}');
    }
    if (seconds > 0 && days == 0 && hours == 0) {
      parts.add('$seconds ${seconds == 1 ? 'second' : 'seconds'}');
    }

    if (parts.isEmpty) {
      return 'less than a second';
    }
    if (parts.length == 1) {
      return parts.first;
    }
    if (parts.length == 2) {
      return '${parts[0]} and ${parts[1]}';
    }
    return '${parts.sublist(0, parts.length - 1).join(', ')}, and ${parts.last}';
  }

  /// Returns a short natural description.
  ///
  /// Examples:
  /// - "< 1s"
  /// - "30s"
  /// - "2m"
  /// - "1h 30m"
  /// - "2d 5h"
  String get short {
    final seconds = _duration.inSeconds % 60;
    final minutes = _duration.inMinutes % 60;
    final hours = _duration.inHours % 24;
    final days = _duration.inDays;

    if (_duration.inSeconds < 1) {
      return '< 1s';
    }
    if (days > 0) {
      if (hours > 0) {
        return '${days}d ${hours}h';
      }
      return '${days}d';
    }
    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    }
    if (minutes > 0) {
      if (seconds > 0 && minutes < 10) {
        return '${minutes}m ${seconds}s';
      }
      return '${minutes}m';
    }
    return '${seconds}s';
  }

  /// Returns remaining time format (countdown style).
  ///
  /// Examples:
  /// - "0:30" (30 seconds)
  /// - "2:30" (2 minutes 30 seconds)
  /// - "1:02:30" (1 hour 2 minutes 30 seconds)
  String get countdown {
    final seconds = _duration.inSeconds % 60;
    final minutes = _duration.inMinutes % 60;
    final hours = _duration.inHours;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  int _roundToNearest(int value, int nearest) {
    return ((value + nearest ~/ 2) ~/ nearest) * nearest;
  }
}

/// Extension to add natural time formatting to Duration.
extension NaturalTimeDeltaExtension on Duration {
  /// Returns a [NaturalTimeDelta] formatter for this duration.
  NaturalTimeDelta get naturalDelta => NaturalTimeDelta(this);

  /// Returns a natural language description of this duration.
  String get natural => NaturalTimeDelta(this).natural;

  /// Returns a precise natural description of this duration.
  String get naturalPrecise => NaturalTimeDelta(this).precise;

  /// Returns a short natural description of this duration.
  String get naturalShort => NaturalTimeDelta(this).short;

  /// Returns a countdown-style format of this duration.
  String get countdown => NaturalTimeDelta(this).countdown;
}
