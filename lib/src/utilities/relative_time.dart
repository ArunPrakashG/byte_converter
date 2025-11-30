/// Relative time formatting utilities for human-readable time expressions.
///
/// Converts [Duration] or timestamps to relative time strings like
/// "2 hours ago", "in 5 minutes", or "just now".
///
/// Example:
/// ```dart
/// // Using Duration extension
/// final elapsed = Duration(hours: 2, minutes: 30);
/// print(elapsed.ago);         // "2 hours ago"
/// print(elapsed.fromNow);     // "in 2 hours"
///
/// // Using DateTime extension
/// final pastDate = DateTime.now().subtract(Duration(days: 3));
/// print(pastDate.relative);   // "3 days ago"
///
/// // Using RelativeTime utility
/// print(RelativeTime.format(Duration(minutes: 45)));        // "45 minutes"
/// print(RelativeTime.formatAgo(Duration(seconds: 30)));     // "30 seconds ago"
/// print(RelativeTime.formatFromNow(Duration(hours: 1)));    // "in 1 hour"
/// ```
library;

/// Configuration options for relative time formatting.
class RelativeTimeOptions {
  /// Create options for relative time formatting.
  const RelativeTimeOptions({
    this.abbreviated = false,
    this.numeric = false,
    this.threshold = const Duration(seconds: 5),
    this.nowLabel = 'just now',
    this.agoSuffix = 'ago',
    this.fromNowPrefix = 'in',
    this.includeSeconds = true,
  });

  /// Use abbreviated units (e.g., "2h" instead of "2 hours").
  final bool abbreviated;

  /// Always use numeric values (e.g., "1 day ago" vs "yesterday").
  final bool numeric;

  /// Duration threshold for "just now" label.
  final Duration threshold;

  /// Label for very recent times.
  final String nowLabel;

  /// Suffix for past times.
  final String agoSuffix;

  /// Prefix for future times.
  final String fromNowPrefix;

  /// Include seconds in output for small durations.
  final bool includeSeconds;

  /// Default options.
  static const RelativeTimeOptions defaults = RelativeTimeOptions();

  /// Abbreviated format options.
  static const RelativeTimeOptions abbreviated_ = RelativeTimeOptions(
    abbreviated: true,
  );

  /// Creates a copy with modified options.
  RelativeTimeOptions copyWith({
    bool? abbreviated,
    bool? numeric,
    Duration? threshold,
    String? nowLabel,
    String? agoSuffix,
    String? fromNowPrefix,
    bool? includeSeconds,
  }) {
    return RelativeTimeOptions(
      abbreviated: abbreviated ?? this.abbreviated,
      numeric: numeric ?? this.numeric,
      threshold: threshold ?? this.threshold,
      nowLabel: nowLabel ?? this.nowLabel,
      agoSuffix: agoSuffix ?? this.agoSuffix,
      fromNowPrefix: fromNowPrefix ?? this.fromNowPrefix,
      includeSeconds: includeSeconds ?? this.includeSeconds,
    );
  }
}

/// Relative time formatting utilities.
abstract class RelativeTime {
  RelativeTime._();

  static const _units = [
    (Duration.microsecondsPerDay * 365, 'year', 'y'),
    (Duration.microsecondsPerDay * 30, 'month', 'mo'),
    (Duration.microsecondsPerDay * 7, 'week', 'w'),
    (Duration.microsecondsPerDay, 'day', 'd'),
    (Duration.microsecondsPerHour, 'hour', 'h'),
    (Duration.microsecondsPerMinute, 'minute', 'm'),
    (Duration.microsecondsPerSecond, 'second', 's'),
  ];

  /// Formats a duration as a relative time string.
  ///
  /// Returns just the duration part without "ago" or "in" prefix/suffix.
  /// Example: Duration(hours: 2) → "2 hours"
  static String format(
    Duration duration, {
    RelativeTimeOptions options = RelativeTimeOptions.defaults,
  }) {
    final micros = duration.inMicroseconds.abs();

    if (micros == 0) {
      return options.nowLabel;
    }

    for (final (unitMicros, name, abbr) in _units) {
      if (micros >= unitMicros) {
        final value = micros ~/ unitMicros;
        if (options.abbreviated) {
          return '$value$abbr';
        }
        return '$value ${_pluralize(value, name)}';
      }
    }

    // Less than a second
    if (options.includeSeconds) {
      final ms = duration.inMilliseconds.abs();
      if (options.abbreviated) {
        return '${ms}ms';
      }
      return '$ms ${_pluralize(ms, 'millisecond')}';
    }

    return options.nowLabel;
  }

  /// Formats a duration as a past time string.
  ///
  /// Example: Duration(hours: 2) → "2 hours ago"
  static String formatAgo(
    Duration duration, {
    RelativeTimeOptions options = RelativeTimeOptions.defaults,
  }) {
    final micros = duration.inMicroseconds.abs();

    if (micros < options.threshold.inMicroseconds) {
      return options.nowLabel;
    }

    final base = format(duration, options: options);
    return '$base ${options.agoSuffix}';
  }

  /// Formats a duration as a future time string.
  ///
  /// Example: Duration(hours: 2) → "in 2 hours"
  static String formatFromNow(
    Duration duration, {
    RelativeTimeOptions options = RelativeTimeOptions.defaults,
  }) {
    final micros = duration.inMicroseconds.abs();

    if (micros < options.threshold.inMicroseconds) {
      return options.nowLabel;
    }

    final base = format(duration, options: options);
    return '${options.fromNowPrefix} $base';
  }

  /// Formats the time difference from a DateTime to now.
  ///
  /// Automatically determines if the time is in the past or future.
  static String fromDateTime(
    DateTime dateTime, {
    DateTime? now,
    RelativeTimeOptions options = RelativeTimeOptions.defaults,
  }) {
    final reference = now ?? DateTime.now();
    final difference = dateTime.difference(reference);

    if (difference.isNegative) {
      return formatAgo(difference.abs(), options: options);
    } else {
      return formatFromNow(difference, options: options);
    }
  }

  /// Formats as a human-friendly relative description.
  ///
  /// Uses words like "yesterday", "tomorrow" when applicable.
  static String humanize(
    Duration duration, {
    bool isPast = true,
    bool numeric = false,
  }) {
    final micros = duration.inMicroseconds.abs();
    final days = micros ~/ Duration.microsecondsPerDay;

    if (!numeric) {
      // Special cases for common durations
      if (days == 0) {
        final hours = micros ~/ Duration.microsecondsPerHour;
        if (hours == 0) {
          final minutes = micros ~/ Duration.microsecondsPerMinute;
          if (minutes < 1) return isPast ? 'just now' : 'right now';
          if (minutes == 1) return isPast ? 'a minute ago' : 'in a minute';
          if (minutes < 60) {
            return isPast ? '$minutes minutes ago' : 'in $minutes minutes';
          }
        }
        if (hours == 1) return isPast ? 'an hour ago' : 'in an hour';
        return isPast ? '$hours hours ago' : 'in $hours hours';
      }

      if (days == 1) return isPast ? 'yesterday' : 'tomorrow';
      if (days < 7) return isPast ? '$days days ago' : 'in $days days';

      final weeks = days ~/ 7;
      if (weeks == 1) return isPast ? 'last week' : 'next week';
      if (weeks < 4) return isPast ? '$weeks weeks ago' : 'in $weeks weeks';

      final months = days ~/ 30;
      if (months == 1) return isPast ? 'last month' : 'next month';
      if (months < 12) {
        return isPast ? '$months months ago' : 'in $months months';
      }

      final years = days ~/ 365;
      if (years == 1) return isPast ? 'last year' : 'next year';
      return isPast ? '$years years ago' : 'in $years years';
    }

    // Numeric format (always uses numbers)
    return isPast
        ? formatAgo(duration, options: const RelativeTimeOptions(numeric: true))
        : formatFromNow(duration,
            options: const RelativeTimeOptions(numeric: true));
  }

  /// Returns a multi-part relative time string.
  ///
  /// Example: Duration(hours: 2, minutes: 30) → "2 hours, 30 minutes"
  static String detailed(
    Duration duration, {
    int maxParts = 2,
    bool abbreviated = false,
  }) {
    var remaining = duration.inMicroseconds.abs();
    final parts = <String>[];

    for (final (unitMicros, name, abbr) in _units) {
      if (remaining >= unitMicros && parts.length < maxParts) {
        final value = remaining ~/ unitMicros;
        remaining = remaining % unitMicros;
        if (abbreviated) {
          parts.add('$value$abbr');
        } else {
          parts.add('$value ${_pluralize(value, name)}');
        }
      }
    }

    if (parts.isEmpty) {
      return abbreviated ? '0s' : '0 seconds';
    }

    return parts.join(abbreviated ? ' ' : ', ');
  }

  /// Returns a countdown-style string.
  ///
  /// Example: Duration(hours: 1, minutes: 30, seconds: 45) → "1:30:45"
  static String countdown(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${_pad(minutes)}:${_pad(seconds)}';
    }
    return '$minutes:${_pad(seconds)}';
  }

  /// Returns a progress-style string.
  ///
  /// Example: (elapsed: 30s, total: 60s) → "30s / 60s (50%)"
  static String progress(
    Duration elapsed,
    Duration total, {
    bool showPercentage = true,
  }) {
    final elapsedStr =
        format(elapsed, options: RelativeTimeOptions.abbreviated_);
    final totalStr = format(total, options: RelativeTimeOptions.abbreviated_);

    if (showPercentage && total.inMicroseconds > 0) {
      final percent =
          (elapsed.inMicroseconds / total.inMicroseconds * 100).round();
      return '$elapsedStr / $totalStr ($percent%)';
    }

    return '$elapsedStr / $totalStr';
  }

  /// Returns estimated time remaining.
  ///
  /// Given elapsed time and progress, estimates remaining time.
  static String eta(
    Duration elapsed,
    double progress, {
    bool abbreviated = false,
  }) {
    if (progress <= 0) return 'calculating...';
    if (progress >= 1) return 'complete';

    final totalEstimate = elapsed.inMicroseconds / progress;
    final remaining = Duration(
      microseconds: (totalEstimate - elapsed.inMicroseconds).round(),
    );

    final options = abbreviated
        ? RelativeTimeOptions.abbreviated_
        : RelativeTimeOptions.defaults;

    return format(remaining, options: options);
  }

  static String _pluralize(int count, String singular) {
    return count == 1 ? singular : '${singular}s';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}

/// Extension on [Duration] for relative time formatting.
extension RelativeDurationExtension on Duration {
  /// Formats as a past time string (e.g., "2 hours ago").
  String get ago => RelativeTime.formatAgo(this);

  /// Formats as a future time string (e.g., "in 2 hours").
  String get fromNow => RelativeTime.formatFromNow(this);

  /// Formats as a plain duration string (e.g., "2 hours").
  String get relative => RelativeTime.format(this);

  /// Human-friendly relative time (uses "yesterday", "tomorrow", etc.).
  String get humanRelative => RelativeTime.humanize(this);

  /// Multi-part format (e.g., "2 hours, 30 minutes").
  String detailed({int maxParts = 2, bool abbreviated = false}) {
    return RelativeTime.detailed(this,
        maxParts: maxParts, abbreviated: abbreviated);
  }

  /// Countdown format (e.g., "1:30:45").
  String get asCountdown => RelativeTime.countdown(this);

  /// Abbreviated format (e.g., "2h", "30m").
  String get abbreviated =>
      RelativeTime.format(this, options: RelativeTimeOptions.abbreviated_);
}

/// Extension on [DateTime] for relative time formatting.
extension RelativeDateTimeExtension on DateTime {
  /// Formats as relative time from now.
  ///
  /// Automatically determines past or future.
  String get relative => RelativeTime.fromDateTime(this);

  /// Formats as relative time from a specific reference point.
  String relativeFrom(DateTime reference) {
    return RelativeTime.fromDateTime(this, now: reference);
  }

  /// Human-friendly relative time.
  String get humanRelative {
    final diff = DateTime.now().difference(this);
    return RelativeTime.humanize(diff.abs(), isPast: !diff.isNegative);
  }

  /// Time ago from now (e.g., "2 hours ago").
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    return diff.isNegative
        ? RelativeTime.formatFromNow(diff.abs())
        : RelativeTime.formatAgo(diff);
  }
}
