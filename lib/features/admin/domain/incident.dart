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
      incidentId: json['incidentId'] ?? '',
      bookingId: json['bookingId'] ?? '',
      reportedBy: json['reportedBy'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'low',
      status: json['status'] ?? 'open',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
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
