import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A worker's recurring weekly availability pattern
class DayAvailability extends Equatable {
  final String day; // 'monday' .. 'sunday'
  final List<TimeSlot> slots;

  const DayAvailability({required this.day, required this.slots});

  bool isAvailableAt(String startTime, String endTime) {
    return slots.any((s) => s.contains(startTime, endTime));
  }

  Map<String, dynamic> toJson() => {
    'day': day,
    'slots': slots.map((s) => s.toJson()).toList(),
  };

  factory DayAvailability.fromJson(Map<String, dynamic> json) =>
      DayAvailability(
        day: json['day'] as String,
        slots: (json['slots'] as List<dynamic>? ?? [])
            .map((s) => TimeSlot.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [day, slots];
}

/// A contiguous time window (HH:mm 24-hour format)
class TimeSlot extends Equatable {
  final String start; // e.g. "08:00"
  final String end; // e.g. "13:00"

  const TimeSlot({required this.start, required this.end});

  /// Returns true if [start]..[end] fits entirely within this slot
  bool contains(String reqStart, String reqEnd) {
    return _toMinutes(start) <= _toMinutes(reqStart) &&
        _toMinutes(end) >= _toMinutes(reqEnd);
  }

  int _toMinutes(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Map<String, dynamic> toJson() => {'start': start, 'end': end};

  factory TimeSlot.fromJson(Map<String, dynamic> json) =>
      TimeSlot(start: json['start'] as String, end: json['end'] as String);

  @override
  List<Object?> get props => [start, end];
}

/// Full availability calendar for a worker
/// Stored at: workers/{workerId}/calendar/availability
class WorkerCalendar extends Equatable {
  final String workerId;
  final Map<String, DayAvailability> recurring; // key = 'monday' etc.
  final Map<String, String> exceptions; // 'YYYY-MM-DD' → 'booked'|'unavailable'
  final DateTime? updatedAt;

  const WorkerCalendar({
    required this.workerId,
    required this.recurring,
    this.exceptions = const {},
    this.updatedAt,
  });

  static WorkerCalendar empty(String workerId) =>
      WorkerCalendar(workerId: workerId, recurring: {});

  bool get hasSchedule => recurring.isNotEmpty;

  /// Check if the worker is available for a given date + time window
  bool isAvailable({
    required DateTime date,
    required String startTime,
    required String endTime,
  }) {
    final dateKey = _dateKey(date);
    if (exceptions.containsKey(dateKey)) return false;

    final dayName = _dayName(date);
    final dayAvail = recurring[dayName];
    if (dayAvail == null) return false;

    return dayAvail.isAvailableAt(startTime, endTime);
  }

  /// Block a date (mark as booked)
  WorkerCalendar withBookedDate(DateTime date) =>
      copyWith(exceptions: {...exceptions, _dateKey(date): 'booked'});

  /// Unblock a date
  WorkerCalendar withReleasedDate(DateTime date) {
    final newExceptions = Map<String, String>.from(exceptions)
      ..remove(_dateKey(date));
    return copyWith(exceptions: newExceptions);
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _dayName(DateTime d) => const [
    '',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ][d.weekday];

  WorkerCalendar copyWith({
    String? workerId,
    Map<String, DayAvailability>? recurring,
    Map<String, String>? exceptions,
    DateTime? updatedAt,
  }) => WorkerCalendar(
    workerId: workerId ?? this.workerId,
    recurring: recurring ?? this.recurring,
    exceptions: exceptions ?? this.exceptions,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'workerId': workerId,
    'recurring': recurring.map((k, v) => MapEntry(k, v.toJson())),
    'exceptions': exceptions,
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  factory WorkerCalendar.fromJson(
    Map<String, dynamic> json, {
    required String workerId,
  }) {
    final recurringRaw = json['recurring'] as Map<String, dynamic>? ?? {};
    return WorkerCalendar(
      workerId: workerId,
      recurring: recurringRaw.map(
        (k, v) =>
            MapEntry(k, DayAvailability.fromJson(v as Map<String, dynamic>)),
      ),
      exceptions: (json['exceptions'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, v as String),
      ),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  @override
  List<Object?> get props => [workerId, recurring, exceptions];
}
