class WorkerDocument {
  final String workerId;
  final String? nicFrontUrl;
  final String? nicBackUrl;
  final String? selfieUrl;
  final String? addressProofUrl;
  final String status;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  WorkerDocument({
    required this.workerId,
    this.nicFrontUrl,
    this.nicBackUrl,
    this.selfieUrl,
    this.addressProofUrl,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory WorkerDocument.fromJson(Map<String, dynamic> json) {
    return WorkerDocument(
      workerId: json['workerId'] as String? ?? '',
      nicFrontUrl: json['nicFrontUrl'] as String?,
      nicBackUrl: json['nicBackUrl'] as String?,
      selfieUrl: json['selfieUrl'] as String?,
      addressProofUrl: json['addressProofUrl'] as String?,
      status: json['status'] as String? ?? 'pending',
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workerId': workerId,
      'nicFrontUrl': nicFrontUrl,
      'nicBackUrl': nicBackUrl,
      'selfieUrl': selfieUrl,
      'addressProofUrl': addressProofUrl,
      'status': status,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
    };
  }
}
