import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/worker_application.dart';
import 'active_job_page.dart';

class JobOfferPage extends StatefulWidget {
  final String workerId;
  
  const JobOfferPage({Key? key, required this.workerId}) : super(key: key);

  @override
  _JobOfferPageState createState() => _JobOfferPageState();
}

class _JobOfferPageState extends State<JobOfferPage> {
  StreamSubscription<DocumentSnapshot>? _offerSubscription;
  bool _hasActiveOffer = false;
  Map<String, dynamic>? _currentOffer;
  Timer? _countdownTimer;
  int _secondsLeft = 30;
  
  @override
  void initState() {
    super.initState();
    _listenForOffers();
  }

  void _listenForOffers() {
    // Listen to job_offers collection for this worker
    _offerSubscription = FirebaseFirestore.instance
        .collection('job_offers')
        .where('workerId', isEqualTo: widget.workerId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final offer = snapshot.docs.first.data() as Map<String, dynamic>;
        _showOffer(offer, snapshot.docs.first.id);
      }
    });
  }

  void _showOffer(Map<String, dynamic> offer, String offerId) {
    setState(() {
      _hasActiveOffer = true;
      _currentOffer = offer;
      _secondsLeft = 30;
    });

    // Start countdown
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _declineOffer(offerId);
          timer.cancel();
        }
      });
    });

    // Show modal or navigate to offer screen
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOfferModal(offer, offerId),
    );
  }

  Widget _buildOfferModal(Map<String, dynamic> offer, String offerId) {
    final earnings = offer['estimatedEarnings'] as double;
    final distance = offer['distanceKm'] as double;
    final serviceType = offer['serviceType'] as String;
    final houseNumber = offer['houseNumber'] as String;
    final landmark = offer['landmark'] as String;

    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Progress bar (30 second timer)
          LinearProgressIndicator(
            value: _secondsLeft / 30,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _secondsLeft < 10 ? Colors.red : Colors.green,
            ),
            minHeight: 6,
          ),
          
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NEW JOB REQUEST',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_secondsLeft s',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
                // Earnings (Big)
                Center(
                  child: Column(
                    children: [
                      Text(
                        'LKR ${earnings.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      Text('Estimated earnings'),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                
                // Job details
                _buildDetailRow(Icons.work, _getServiceName(serviceType)),
                _buildDetailRow(Icons.location_on, '$distance km away'),
                _buildDetailRow(Icons.home, '$houseNumber, $landmark'),
                
                SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => _declineOffer(offerId),
                        child: Text('Decline'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => _acceptJob(offerId, offer['jobId']),
                        child: Text(
                          'ACCEPT JOB',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getServiceName(String type) {
    // Map to display names
    final map = {
      'cleaning': 'Home Cleaning',
      'babysitting': 'Babysitting',
      'elderlyCare': 'Elderly Care',
      'cooking': 'Cooking',
      'laundry': 'Laundry',
    };
    return map[type] ?? type;
  }

  Future<void> _acceptJob(String offerId, String jobId) async {
    try {
      // Call Cloud Function
      final callable = FirebaseFunctions.instance.httpsCallable('acceptJob');
      final result = await callable.call({
        'jobId': jobId,
        'workerId': widget.workerId,
      });

      if (result.data['success'] == true) {
        Navigator.pop(context);
        _countdownTimer?.cancel();
        
        // Navigate to active job screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveJobPage(jobId: jobId),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Job was taken by another worker'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _declineOffer(String offerId) {
    FirebaseFirestore.instance.collection('job_offers').doc(offerId).update({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });
    _countdownTimer?.cancel();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _offerSubscription?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Jobs'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: _hasActiveOffer
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radio_button_checked, size: 60, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'You are online',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Waiting for job requests nearby...'),
                ],
              ),
      ),
    );
  }
}