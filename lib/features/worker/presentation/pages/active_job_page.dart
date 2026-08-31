import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../../injection_container.dart';
import '../../../../core/config/theme.dart';
import '../../../booking/domain/entities/booking.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Active Job Page — Worker check-in / check-out flow with GPS + photo
// ──────────────────────────────────────────────────────────────────────────────

class ActiveJobPage extends StatefulWidget {
  final String jobId;

  const ActiveJobPage({super.key, required this.jobId});

  @override
  State<ActiveJobPage> createState() => _ActiveJobPageState();
}

class _ActiveJobPageState extends State<ActiveJobPage> {
  Timer? _locationTimer;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;
  DateTime? _workStartedAt;
  bool _isSubmitting = false;
  String? _workerId;

  @override
  void initState() {
    super.initState();
    _workerId = FirebaseAuth.instance.currentUser?.uid;
    _startLocationTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  // ── Location tracking ──────────────────────────────────────────────────────

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        if (_workerId != null) {
          await sl<FirebaseFirestore>()
              .collection('worker_locations')
              .doc(_workerId)
              .set({
                'latitude': pos.latitude,
                'longitude': pos.longitude,
                'updatedAt': FieldValue.serverTimestamp(),
                'activeJobId': widget.jobId,
              });
        }
      } catch (_) {}
    });
  }

  void _startElapsedTimer(DateTime startedAt) {
    _workStartedAt = startedAt;
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(startedAt);
        });
      }
    });
  }

  // ── GPS helper ────────────────────────────────────────────────────────────

  Future<Position?> _getPosition() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Photo helper ──────────────────────────────────────────────────────────

  Future<String?> _captureAndUpload(String label) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1080,
    );
    if (picked == null) return null;
    final file = File(picked.path);
    try {
      final ref = sl<FirebaseStorage>().ref().child(
        'bookings/${widget.jobId}/$label.jpg',
      );
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  // ── Status transitions ────────────────────────────────────────────────────

  Future<void> _markArrived(String currentStatus) async {
    if (currentStatus != 'workerAssigned' && currentStatus != 'confirmed') {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final pos = await _getPosition();
      await sl<FirebaseFirestore>()
          .collection('bookings')
          .doc(widget.jobId)
          .update({
            'status': 'workerArrived',
            'updatedAt': FieldValue.serverTimestamp(),
            if (pos != null)
              'actualArrivalLocation': GeoPoint(pos.latitude, pos.longitude),
          });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _checkIn() async {
    setState(() => _isSubmitting = true);
    try {
      final pos = await _getPosition();
      final photoUrl = await _captureAndUpload('checkin');
      final now = DateTime.now();
      await sl<FirebaseFirestore>()
          .collection('bookings')
          .doc(widget.jobId)
          .update({
            'status': 'inProgress',
            'startedAt': Timestamp.fromDate(now),
            'checkIn': {
              'timestamp': Timestamp.fromDate(now),
              'latitude': pos?.latitude,
              'longitude': pos?.longitude,
              'photoUrl': photoUrl,
              'notes': null,
            },
            'updatedAt': FieldValue.serverTimestamp(),
          });
      _startElapsedTimer(now);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _checkOut(CheckRecord checkIn) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Complete this job?'),
        content: Text(
          'You have been working for ${_formatDuration(_elapsed)}. '
          'A photo will be taken as proof of completion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Complete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      final pos = await _getPosition();
      final photoUrl = await _captureAndUpload('checkout');
      final now = DateTime.now();
      final billableHours = _elapsed.inMinutes / 60.0;

      await sl<FirebaseFirestore>()
          .collection('bookings')
          .doc(widget.jobId)
          .update({
            'status': 'completed',
            'completedAt': Timestamp.fromDate(now),
            'checkOut': {
              'timestamp': Timestamp.fromDate(now),
              'latitude': pos?.latitude,
              'longitude': pos?.longitude,
              'photoUrl': photoUrl,
              'notes': null,
            },
            'billableHours': billableHours,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      _elapsedTimer?.cancel();
      _locationTimer?.cancel();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── SOS ───────────────────────────────────────────────────────────────────

  void _showSOS() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text(
          'This will immediately alert the HelaService safety team and share your GPS location. Only use in genuine emergencies.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final pos = await _getPosition();
              await sl<FirebaseFirestore>().collection('safety_alerts').add({
                'workerId': _workerId,
                'bookingId': widget.jobId,
                'customerId': '',
                'type': 'sosPanic',
                'severity': 'critical',
                'message': 'Worker triggered SOS during an active job.',
                'status': 'open',
                if (pos != null) 'latitude': pos.latitude,
                if (pos != null) 'longitude': pos.longitude,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('SOS sent. Help is on the way.'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: StreamBuilder<DocumentSnapshot>(
          stream: sl<FirebaseFirestore>()
              .collection('bookings')
              .doc(widget.jobId)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snap.data!.data() as Map<String, dynamic>? ?? {};
            final booking = Booking.fromJson(data, id: widget.jobId);
            final checkIn = booking.checkIn;

            // Start elapsed timer if already in progress
            if (booking.status == BookingStatus.inProgress &&
                booking.startedAt != null &&
                _workStartedAt == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _startElapsedTimer(booking.startedAt!);
              });
            }

            if (booking.status == BookingStatus.completed) {
              return _CompletedView(
                booking: booking,
                elapsed: _elapsed,
                onDone: () => context.go('/worker/dashboard'),
              );
            }

            return _buildActiveView(context, booking, checkIn);
          },
        ),
      ),
    );
  }

  Widget _buildActiveView(
    BuildContext context,
    Booking booking,
    CheckRecord? checkIn,
  ) {
    final stage = _stage(booking.status);
    final stageColor = _stageColor(stage);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: stageColor,
        foregroundColor: Colors.white,
        title: Text(_stageTitle(stage)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sos, color: Colors.white),
            tooltip: 'Emergency SOS',
            onPressed: _showSOS,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stage progress bar
          _StageBar(current: stage),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Elapsed timer (inProgress only)
                  if (stage == _JobStage.inProgress) ...[
                    _ElapsedCard(elapsed: _elapsed),
                    const SizedBox(height: 16),
                  ],

                  // Booking details card
                  _BookingDetailsCard(booking: booking),
                  const SizedBox(height: 16),

                  // Check-in photo (if taken)
                  if (checkIn?.photoUrl != null) ...[
                    _PhotoProofCard(
                      label: 'Check-in photo',
                      photoUrl: checkIn!.photoUrl!,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Instructions
                  if (booking.notes != null && booking.notes!.isNotEmpty)
                    _InstructionsCard(notes: booking.notes!),
                ],
              ),
            ),
          ),

          // Action button area
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: _ActionButton(
                stage: stage,
                booking: booking,
                checkIn: checkIn,
                isSubmitting: _isSubmitting,
                onMarkArrived: () => _markArrived(booking.status.name),
                onCheckIn: _checkIn,
                onCheckOut: checkIn != null ? () => _checkOut(checkIn) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static _JobStage _stage(BookingStatus status) {
    switch (status) {
      case BookingStatus.workerAssigned:
      case BookingStatus.confirmed:
        return _JobStage.enRoute;
      case BookingStatus.workerEnRoute:
        return _JobStage.enRoute;
      case BookingStatus.workerArrived:
        return _JobStage.arrived;
      case BookingStatus.inProgress:
        return _JobStage.inProgress;
      default:
        return _JobStage.enRoute;
    }
  }

  static Color _stageColor(_JobStage stage) {
    switch (stage) {
      case _JobStage.enRoute:
        return AppTheme.infoColor;
      case _JobStage.arrived:
        return AppTheme.warningColor;
      case _JobStage.inProgress:
        return AppTheme.successColor;
    }
  }

  static String _stageTitle(_JobStage stage) {
    switch (stage) {
      case _JobStage.enRoute:
        return 'En Route';
      case _JobStage.arrived:
        return 'At Location';
      case _JobStage.inProgress:
        return 'Job In Progress';
    }
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '${h}h ${m}m' : '${m}m ${s}s';
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Stage enum
// ──────────────────────────────────────────────────────────────────────────────

enum _JobStage { enRoute, arrived, inProgress }

// ──────────────────────────────────────────────────────────────────────────────
// Stage Progress Bar
// ──────────────────────────────────────────────────────────────────────────────

class _StageBar extends StatelessWidget {
  final _JobStage current;

  const _StageBar({required this.current});

  @override
  Widget build(BuildContext context) {
    const stages = ['En Route', 'Arrived', 'In Progress'];
    final idx = _JobStage.values.indexOf(current);
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: List.generate(stages.length, (i) {
          final done = i <= idx;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? AppTheme.primaryColor
                        : Theme.of(context).colorScheme.outline,
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    stages[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: done ? FontWeight.w600 : FontWeight.normal,
                      color: done
                          ? AppTheme.primaryColor
                          : Theme.of(context).colorScheme.outline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (i < stages.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i < idx
                          ? AppTheme.primaryColor
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Elapsed Timer Card
// ──────────────────────────────────────────────────────────────────────────────

class _ElapsedCard extends StatelessWidget {
  final Duration elapsed;

  const _ElapsedCard({required this.elapsed});

  @override
  Widget build(BuildContext context) {
    final h = elapsed.inHours;
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final display = h > 0 ? '$h:$m:$s' : '$m:$s';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.timer, color: AppTheme.successColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Time elapsed',
                style: TextStyle(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            display,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.successColor,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Booking Details Card
// ──────────────────────────────────────────────────────────────────────────────

class _BookingDetailsCard extends StatelessWidget {
  final Booking booking;

  const _BookingDetailsCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Job Details', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.home_repair_service,
            label: 'Service',
            value: booking.serviceCatalogId ?? booking.serviceType.name,
          ),
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: booking.address.fullAddress,
          ),
          _DetailRow(
            icon: Icons.timer_outlined,
            label: 'Booked duration',
            value:
                '${booking.durationHours ?? booking.schedule?.durationHours ?? 0} hrs',
          ),
          _DetailRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Your earnings',
            value:
                'LKR ${((booking.finalPrice ?? booking.estimatedPrice) * 0.80).toStringAsFixed(0)}',
            valueColor: AppTheme.successColor,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Photo Proof Card
// ──────────────────────────────────────────────────────────────────────────────

class _PhotoProofCard extends StatelessWidget {
  final String label;
  final String photoUrl;

  const _PhotoProofCard({required this.label, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.photo_camera,
                size: 16,
                color: AppTheme.successColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: AppTheme.successColor),
              ),
              const Spacer(),
              const Icon(
                Icons.check_circle,
                size: 16,
                color: AppTheme.successColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              photoUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 80,
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
                child: const Center(child: Icon(Icons.broken_image)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Instructions Card
// ──────────────────────────────────────────────────────────────────────────────

class _InstructionsCard extends StatelessWidget {
  final String notes;

  const _InstructionsCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: AppTheme.warningColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer instructions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.warningColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(notes, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Context-aware action button
// ──────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final _JobStage stage;
  final Booking booking;
  final CheckRecord? checkIn;
  final bool isSubmitting;
  final VoidCallback onMarkArrived;
  final VoidCallback onCheckIn;
  final VoidCallback? onCheckOut;

  const _ActionButton({
    required this.stage,
    required this.booking,
    required this.checkIn,
    required this.isSubmitting,
    required this.onMarkArrived,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    if (isSubmitting) {
      return const SizedBox(
        height: 52,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    switch (stage) {
      case _JobStage.enRoute:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.location_on),
                label: const Text('I\'ve Arrived at Location'),
                onPressed: onMarkArrived,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.map_outlined, size: 16),
                label: const Text('Open in Maps'),
                onPressed: () {},
              ),
            ),
          ],
        );

      case _JobStage.arrived:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Check In — Take Photo + GPS Stamp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                ),
                onPressed: onCheckIn,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A photo will be taken as proof of arrival.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        );

      case _JobStage.inProgress:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Complete Job — Check Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningColor,
                ),
                onPressed: onCheckOut,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A photo will be taken as proof of completion.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        );
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Completed View
// ──────────────────────────────────────────────────────────────────────────────

class _CompletedView extends StatelessWidget {
  final Booking booking;
  final Duration elapsed;
  final VoidCallback onDone;

  const _CompletedView({
    required this.booking,
    required this.elapsed,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final gross = booking.finalPrice ?? booking.estimatedPrice;
    final earnings = gross * 0.80;
    final hoursWorked = elapsed.inMinutes > 0
        ? elapsed.inMinutes / 60.0
        : (booking.durationHours ?? 0).toDouble();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                'Job Complete!',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Great work. Your earnings will be processed on the next payout day.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _SummaryTile(
                label: 'Time worked',
                value: '${hoursWorked.toStringAsFixed(1)} hrs',
              ),
              _SummaryTile(
                label: 'Gross amount',
                value: 'LKR ${gross.toStringAsFixed(0)}',
              ),
              _SummaryTile(
                label: 'Your earnings (80%)',
                value: 'LKR ${earnings.toStringAsFixed(0)}',
                valueColor: AppTheme.successColor,
                bold: true,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onDone,
                  child: const Text('Back to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _SummaryTile({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
