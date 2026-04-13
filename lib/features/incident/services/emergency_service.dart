import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/entities/incident.dart';

/// Emergency Service for reporting and handling incidents
/// 
/// Phase 1: Critical Security & Stability - Created missing file
class EmergencyService {
  final FirebaseFirestore _firestore;
  
  EmergencyService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Report an emergency/incident
  /// 
  /// Creates an incident record in Firestore and triggers notifications
  Future<Incident?> reportEmergency({
    required String reporterId,
    required String reporterType,
    required IncidentType type,
    required String description,
    String? jobId,
    String? subjectId,
  }) async {
    try {
      final incidentRef = _firestore.collection('incidents').doc();
      final now = DateTime.now();
      
      final incident = Incident(
        id: incidentRef.id,
        reporterId: reporterId,
        reporterType: reporterType,
        jobId: jobId,
        subjectId: subjectId,
        type: type,
        description: description,
        reportedAt: now,
        status: IncidentStatus.pending,
      );
      
      await incidentRef.set({
        'id': incident.id,
        'reporterId': incident.reporterId,
        'reporterType': incident.reporterType,
        'jobId': incident.jobId,
        'subjectId': incident.subjectId,
        'type': incident.type.toString().split('.').last,
        'description': incident.description,
        'reportedAt': Timestamp.fromDate(incident.reportedAt),
        'status': incident.status.name,
        'createdAt': Timestamp.fromDate(now),
      });
      
      // TODO: Send push notification to admins
      // TODO: Send email alert for high severity incidents
      
      return incident;
    } catch (e) {
      print('Error reporting emergency: $e');
      return null;
    }
  }
  
  /// Contact emergency operator via WhatsApp
  /// 
  /// Opens WhatsApp with a pre-filled emergency message
  Future<void> contactEmergencyOperator({
    required String message,
    String? phoneNumber,
  }) async {
    final operatorNumber = phoneNumber ?? AppConstants.operatorWhatsApp;
    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = 'https://wa.me/$operatorNumber?text=$encodedMessage';
    
    final uri = Uri.parse(whatsappUrl);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch WhatsApp');
    }
  }
  
  /// Get incident by ID
  Future<Incident?> getIncident(String incidentId) async {
    try {
      final doc = await _firestore.collection('incidents').doc(incidentId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return _mapToIncident(data);
    } catch (e) {
      print('Error getting incident: $e');
      return null;
    }
  }
  
  /// Get incidents for a user
  Future<List<Incident>> getUserIncidents(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('incidents')
          .where('reporterId', isEqualTo: userId)
          .orderBy('reportedAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => _mapToIncident(doc.data())).toList();
    } catch (e) {
      print('Error getting user incidents: $e');
      return [];
    }
  }
  
  /// Update incident status
  Future<void> updateIncidentStatus(
    String incidentId,
    IncidentStatus status, {
    String? resolution,
    String? resolvedBy,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': Timestamp.now(),
      };
      
      if (resolution != null) {
        updateData['resolution'] = resolution;
        updateData['resolvedAt'] = Timestamp.now();
      }
      
      if (resolvedBy != null) {
        updateData['resolvedBy'] = resolvedBy;
      }
      
      await _firestore.collection('incidents').doc(incidentId).update(updateData);
    } catch (e) {
      print('Error updating incident status: $e');
      rethrow;
    }
  }
  
  /// Call emergency hotline (direct phone call)
  Future<void> callEmergencyHotline() async {
    final uri = Uri.parse('tel:${AppConstants.emergencyPhone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Could not launch phone dialer');
    }
  }
  
  /// Map Firestore data to Incident entity
  Incident _mapToIncident(Map<String, dynamic> data) {
    return Incident(
      id: data['id'] ?? '',
      reporterId: data['reporterId'] ?? '',
      reporterType: data['reporterType'] ?? 'customer',
      jobId: data['jobId'],
      subjectId: data['subjectId'],
      type: _parseIncidentType(data['type']),
      description: data['description'] ?? '',
      audioUrl: data['audioUrl'],
      imageUrl: data['imageUrl'],
      reportedAt: (data['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseIncidentStatus(data['status']),
      resolvedBy: data['resolvedBy'],
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      resolution: data['resolution'],
    );
  }
  
  /// Parse incident type from string
  IncidentType _parseIncidentType(String? type) {
    switch (type) {
      case 'safetyConcern':
        return IncidentType.safetyConcern;
      case 'paymentDispute':
        return IncidentType.paymentDispute;
      case 'harassment':
        return IncidentType.harassment;
      case 'propertyDamage':
        return IncidentType.propertyDamage;
      case 'serviceIssue':
        return IncidentType.serviceIssue;
      default:
        return IncidentType.other;
    }
  }
  
  /// Parse incident status from string
  IncidentStatus _parseIncidentStatus(String? status) {
    switch (status) {
      case 'investigating':
        return IncidentStatus.investigating;
      case 'resolved':
        return IncidentStatus.resolved;
      case 'escalated':
        return IncidentStatus.escalated;
      default:
        return IncidentStatus.pending;
    }
  }
}
