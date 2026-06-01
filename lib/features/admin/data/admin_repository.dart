import 'package:cloud_firestore/cloud_firestore.dart';
import '../../worker/domain/entities/worker_profile.dart';
import '../../customer/domain/booking.dart';
import '../domain/incident.dart';

/// A blue-tier upgrade request submitted by a worker.
class BlueTierVerification {
  final String workerId;
  final String status;
  final DateTime submittedAt;
  final String? workerName;
  final List<ReferenceContact> references;
  final String? policeClearanceFrontUrl;

  const BlueTierVerification({
    required this.workerId,
    required this.status,
    required this.submittedAt,
    this.workerName,
    required this.references,
    this.policeClearanceFrontUrl,
  });
}

class ReferenceContact {
  final int index;
  final String name;
  final String phone;
  final String relation;
  final String verificationStatus; // pending / called_confirmed / called_refused / no_answer
  final String? callNotes;

  const ReferenceContact({
    required this.index,
    required this.name,
    required this.phone,
    required this.relation,
    required this.verificationStatus,
    this.callNotes,
  });
}

class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<BlueTierVerification>> getBlueTierPendingVerifications() async {
    final snap = await _firestore
        .collection('worker_verifications')
        .where('requestedTier', isEqualTo: 'blue')
        .where('status', isEqualTo: 'pending_review')
        .orderBy('submittedAt', descending: false)
        .get();

    return snap.docs.map((doc) {
      final d = doc.data();
      final refs = (d['references'] as List<dynamic>? ?? [])
          .asMap()
          .entries
          .map((e) {
        final r = e.value as Map<String, dynamic>;
        return ReferenceContact(
          index: e.key,
          name: r['name'] as String? ?? '',
          phone: r['phone'] as String? ?? '',
          relation: r['relation'] as String? ?? '',
          verificationStatus: r['verificationStatus'] as String? ?? 'pending',
          callNotes: r['callNotes'] as String?,
        );
      }).toList();
      return BlueTierVerification(
        workerId: doc.id,
        status: d['status'] as String? ?? 'pending_review',
        submittedAt: (d['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        workerName: d['workerName'] as String?,
        references: refs,
        policeClearanceFrontUrl:
            (d['policeClearance'] as Map<String, dynamic>?)?['frontUrl'] as String?,
      );
    }).toList();
  }

  Future<void> logReferenceCallOutcome({
    required String workerId,
    required int referenceIndex,
    required String outcome, // called_confirmed / called_refused / no_answer
    required String notes,
  }) async {
    final doc = await _firestore
        .collection('worker_verifications')
        .doc(workerId)
        .get();
    if (!doc.exists) return;

    final refs =
        List<Map<String, dynamic>>.from(doc.data()!['references'] as List);
    if (referenceIndex < refs.length) {
      refs[referenceIndex] = {
        ...refs[referenceIndex],
        'verificationStatus': outcome,
        'callNotes': notes,
        'calledAt': FieldValue.serverTimestamp(),
      };
    }
    await _firestore.collection('worker_verifications').doc(workerId).update({
      'references': refs,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> approveBlueTierUpgrade(String workerId) async {
    final batch = _firestore.batch();
    batch.update(
      _firestore.collection('worker_verifications').doc(workerId),
      {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'currentTier': 'blue',
      },
    );
    batch.update(
      _firestore.collection('workers').doc(workerId),
      {
        'verificationTier': 'blue',
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
  }

  Future<void> rejectBlueTierUpgrade(String workerId, String reason) async {
    await _firestore
        .collection('worker_verifications')
        .doc(workerId)
        .update({
      'status': 'rejected',
      'rejectionReason': reason,
      'rejectedAt': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('workers').doc(workerId).update({
      'verificationStatus': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<WorkerProfile>> getPendingWorkers() async {
    final snap = await _firestore
        .collection('workers')
        .where('verificationStatus', whereIn: ['pending_review', 'documents_submitted'])
        .orderBy('createdAt', descending: false)
        .limit(50)
        .get();

    return snap.docs.map((doc) {
      final d = doc.data();
      return WorkerProfile(
        uid: doc.id,
        nic: d['nic'] as String? ?? '',
        name: d['fullName'] as String? ?? d['name'] as String? ?? 'Worker',
        phone: d['mobileNumber'] as String? ?? d['phone'] as String? ?? '',
        district: d['district'] as String? ?? 'Colombo',
        serviceTypes: (d['services'] as List<dynamic>?)
                ?.map((s) => s as String)
                .toList() ??
            [],
        languages: (d['languages'] as List<dynamic>?)
                ?.map((l) => l as String)
                .toList() ??
            ['Sinhala'],
        verificationStatus: d['verificationStatus'] as String? ?? 'pending',
        rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
        completedJobs: d['totalJobs'] as int? ?? 0,
        isAvailable: d['isOnline'] as bool? ?? false,
        availabilityMode: 'full_time',
      );
    }).toList();
  }

  Future<void> updateWorkerStatus(String workerId, String status) async {
    await _firestore.collection('workers').doc(workerId).update({
      'verificationStatus': status,
      if (status == 'approved') 'isVerified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Booking>> getActiveBookings() async {
    final snap = await _firestore
        .collection('bookings')
        .where('status', whereIn: [
          'pending',
          'confirmed',
          'workerAssigned',
          'workerEnRoute',
          'workerArrived',
          'inProgress',
        ])
        .orderBy('createdAt', descending: true)
        .limit(30)
        .get();

    return snap.docs.map((doc) {
      final d = doc.data();
      // Map new Booking schema → legacy admin Booking model
      final scheduledDate = d['scheduledDate'];
      String bookingDate = '';
      if (scheduledDate is Timestamp) {
        final dt = scheduledDate.toDate();
        bookingDate = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
      } else if (scheduledDate is String) {
        bookingDate = scheduledDate;
      }

      final addr = d['address'] as Map<String, dynamic>?;
      final addressText = addr != null
          ? '${addr['houseNumber'] ?? ''}, ${addr['city'] ?? ''}'
          : d['addressText'] as String? ?? '-';

      return Booking(
        bookingId: doc.id,
        customerId: d['customerId'] as String? ?? '',
        workerId: d['workerId'] as String?,
        serviceType: d['serviceType'] as String? ?? 'cleaning',
        packageType: '${d['durationHours'] ?? 4}_hours',
        bookingDate: bookingDate,
        startTime: d['scheduledTime'] as String? ?? '09:00',
        durationHours: d['durationHours'] as int? ?? 4,
        addressText: addressText,
        addressLat: addr != null
            ? (addr['latitude'] as num?)?.toDouble() ?? 6.89
            : 6.89,
        addressLng: addr != null
            ? (addr['longitude'] as num?)?.toDouble() ?? 79.86
            : 79.86,
        specialNotes: d['notes'] as String? ?? '',
        status: d['status'] as String? ?? 'pending',
        price: (d['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
        paymentStatus: d['paymentStatus'] as String? ?? 'unpaid',
        createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  }

  Future<void> assignWorkerToBooking(String bookingId, String workerId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'workerId': workerId,
      'status': 'workerAssigned',
      'assignedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Also update job_request so dispatch knows this is taken
    await _firestore.collection('job_requests').doc(bookingId).set({
      'assignedWorkerId': workerId,
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Incident>> getOpenIncidents() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Incident(
        incidentId: 'inc_888',
        bookingId: 'bk_123',
        reportedBy: 'cus_456',
        type: 'late_arrival',
        description: 'Worker arrived 40 minutes late',
        severity: 'medium',
        status: 'open',
        createdAt: DateTime.now()
      )
    ];
  }
}
