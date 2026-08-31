import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum RecurrencePattern { once, weekly, biweekly, monthly }

enum TimeFlexibility {
  exact,
  plusMinus2h,
  morningAny,
  afternoonAny,
  eveningAny,
}

/// Defines how a booking repeats and how flexible the time window is
class RecurrenceRule extends Equatable {
  final RecurrencePattern pattern;
  final DateTime? endDate; // null = open-ended (max 6 months enforced)
  final int? maxOccurrences;
  final TimeFlexibility timeFlexibility;
  final String? parentBookingId; // null on the root; set on generated instances

  const RecurrenceRule({
    required this.pattern,
    this.endDate,
    this.maxOccurrences,
    this.timeFlexibility = TimeFlexibility.exact,
    this.parentBookingId,
  });

  static const RecurrenceRule once = RecurrenceRule(
    pattern: RecurrencePattern.once,
  );

  bool get isRecurring => pattern != RecurrencePattern.once;
  bool get isInstance => parentBookingId != null;

  /// Number of days between occurrences
  int get intervalDays {
    switch (pattern) {
      case RecurrencePattern.weekly:
        return 7;
      case RecurrencePattern.biweekly:
        return 14;
      case RecurrencePattern.monthly:
        return 30;
      case RecurrencePattern.once:
        return 0;
    }
  }

  /// Generate all future dates for this recurrence from [firstDate]
  List<DateTime> generateDates(DateTime firstDate) {
    if (!isRecurring) return [firstDate];

    final dates = <DateTime>[];
    var current = firstDate;
    final cutoff = endDate ?? firstDate.add(const Duration(days: 180));
    final limit = maxOccurrences ?? 999;

    while (current.isBefore(cutoff) && dates.length < limit) {
      dates.add(current);
      if (pattern == RecurrencePattern.monthly) {
        current = DateTime(
          current.year,
          current.month + 1,
          current.day,
          current.hour,
          current.minute,
        );
      } else {
        current = current.add(Duration(days: intervalDays));
      }
    }
    return dates;
  }

  RecurrenceRule copyWith({
    RecurrencePattern? pattern,
    DateTime? endDate,
    int? maxOccurrences,
    TimeFlexibility? timeFlexibility,
    String? parentBookingId,
  }) => RecurrenceRule(
    pattern: pattern ?? this.pattern,
    endDate: endDate ?? this.endDate,
    maxOccurrences: maxOccurrences ?? this.maxOccurrences,
    timeFlexibility: timeFlexibility ?? this.timeFlexibility,
    parentBookingId: parentBookingId ?? this.parentBookingId,
  );

  Map<String, dynamic> toJson() => {
    'pattern': pattern.name,
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    'maxOccurrences': maxOccurrences,
    'timeFlexibility': timeFlexibility.name,
    'parentBookingId': parentBookingId,
  };

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) => RecurrenceRule(
    pattern: RecurrencePattern.values.firstWhere(
      (e) => e.name == (json['pattern'] as String?),
      orElse: () => RecurrencePattern.once,
    ),
    endDate: json['endDate'] != null
        ? (json['endDate'] as Timestamp).toDate()
        : null,
    maxOccurrences: json['maxOccurrences'] as int?,
    timeFlexibility: TimeFlexibility.values.firstWhere(
      (e) => e.name == (json['timeFlexibility'] as String?),
      orElse: () => TimeFlexibility.exact,
    ),
    parentBookingId: json['parentBookingId'] as String?,
  );

  @override
  List<Object?> get props => [
    pattern,
    endDate,
    maxOccurrences,
    timeFlexibility,
    parentBookingId,
  ];
}
