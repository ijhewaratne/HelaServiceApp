class Incident {
  final String incidentId;
  final String bookingId;
  final String reportedBy;
  final String type;
  final String description;
  final String severity;
  final String status;
  final DateTime createdAt;

  Incident({
    required this.incidentId,
    required this.bookingId,
    required this.reportedBy,
    required this.type,
    required this.description,
    required this.severity,
    required this.status,
    required this.createdAt,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      incidentId: json['incidentId'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      reportedBy: json['reportedBy'] as String? ?? '',
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      severity: json['severity'] as String? ?? 'low',
      status: json['status'] as String? ?? 'open',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'incidentId': incidentId,
      'bookingId': bookingId,
      'reportedBy': reportedBy,
      'type': type,
      'description': description,
      'severity': severity,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
