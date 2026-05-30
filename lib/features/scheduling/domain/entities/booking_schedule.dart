import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recurrence_rule.dart';

/// The scheduling portion of a booking request
class BookingSchedule extends Equatable {
  final DateTime date;
  final String startTime;  // "HH:mm" 24-hour
  final String endTime;    // "HH:mm" 24-hour
  final int durationHours;
  final String timezone;
  final RecurrenceRule recurrence;

  const BookingSchedule({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    this.timezone = 'Asia/Colombo',
    this.recurrence = RecurrenceRule.once,
  });

  bool get isRecurring => recurrence.isRecurring;

  /// Human-readable label e.g. "Tue 17 Jun, 09:00 – 13:00"
  String get displayLabel {
    final d = date;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday]} ${d.day} ${months[d.month]}, $startTime – $endTime';
  }

  BookingSchedule copyWith({
    DateTime? date,
    String? startTime,
    String? endTime,
    int? durationHours,
    String? timezone,
    RecurrenceRule? recurrence,
  }) =>
      BookingSchedule(
        date: date ?? this.date,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        durationHours: durationHours ?? this.durationHours,
        timezone: timezone ?? this.timezone,
        recurrence: recurrence ?? this.recurrence,
      );

  Map<String, dynamic> toJson() => {
        'date': Timestamp.fromDate(date),
        'startTime': startTime,
        'endTime': endTime,
        'durationHours': durationHours,
        'timezone': timezone,
        'recurrence': recurrence.toJson(),
      };

  factory BookingSchedule.fromJson(Map<String, dynamic> json) =>
      BookingSchedule(
        date: (json['date'] as Timestamp).toDate(),
        startTime: json['startTime'] as String? ?? '09:00',
        endTime: json['endTime'] as String? ?? '13:00',
        durationHours: json['durationHours'] as int? ?? 4,
        timezone: json['timezone'] as String? ?? 'Asia/Colombo',
        recurrence: json['recurrence'] != null
            ? RecurrenceRule.fromJson(
                json['recurrence'] as Map<String, dynamic>)
            : RecurrenceRule.once,
      );

  @override
  List<Object?> get props =>
      [date, startTime, endTime, durationHours, recurrence];
}
