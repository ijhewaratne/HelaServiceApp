import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class ActiveJobPage extends StatefulWidget {
  final String jobId;
  const ActiveJobPage({Key? key, required this.jobId}) : super(key: key);

  @override
  _ActiveJobPageState createState() => _ActiveJobPageState();
}

class _ActiveJobPageState extends State<ActiveJobPage> {
  bool _hasArrived = false;
  bool _isWorking = false;
  bool _isCompleted = false;
  Timer? _locationTimer;
  
  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  void _startLocationTracking() {
    // Update location every 30 seconds during active job (battery save)
    _locationTimer = Timer.periodic(Duration(seconds: 30), (_) async {
      if (_isWorking && !_isCompleted) {
        // Get current location and update Firestore
        // This allows customer to see "Helper is working" status
      }
    });
  }

  Future<void> _checkIn() async {
    await FirebaseFirestore.instance.collection('job_requests').doc(widget.jobId).update({
      'status': 'arrived',
      'arrivedAt': FieldValue.serverTimestamp(),
      'actualArrivalLocation': GeoPoint(6.9, 79.8), // Get real location
    });
    
    setState(() => _hasArrived = true);
  }

  Future<void> _startWork() async {
    await FirebaseFirestore.instance.collection('job_requests').doc(widget.jobId).update({
      'status': 'in_progress',
      'startedAt': FieldValue.serverTimestamp(),
    });
    
    setState(() => _isWorking = true);
  }

  Future<void> _completeJob() async {
    await FirebaseFirestore.instance.collection('job_requests').doc(widget.jobId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
    
    setState(() => _isCompleted = true);
    
    // Navigate to earnings/rating screen
  }

  Future<void> _emergencySOS() async {
    // Send emergency alert to platform admin and customer
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Emergency Contact'),
        content: Text('Call emergency contact or report incident?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Call emergency number
              Navigator.pop(context);
            },
            child: Text('Call', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button during job
      child: Scaffold(
        appBar: AppBar(
          title: Text('Active Job'),
          backgroundColor: _isWorking ? Colors.green : Colors.orange,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Icon(Icons.emergency, color: Colors.red),
              onPressed: _emergencySOS,
            ),
          ],
        ),
        body: Column(
          children: [
            // Status bar
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: _getStatusColor(),
              child: Text(
                _getStatusText(),
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Job details card
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('job_requests')
                    .doc(widget.jobId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                  
                  final job = snapshot.data!.data() as Map<String, dynamic>;
                  return Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Location',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: Center(child: Text('Map to customer location')),
                        ),
                        SizedBox(height: 16),
                        Text('Service: ${job['serviceType']}'),
                        Text('Earnings: LKR ${job['estimatedEarnings']}'),
                        if (job['landmark'] != null) Text('Landmark: ${job['landmark']}'),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Action button
            Container(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getActionButtonColor(),
                  ),
                  onPressed: _isCompleted 
                      ? null 
                      : (_isWorking 
                          ? _completeJob 
                          : (_hasArrived 
                              ? _startWork 
                              : _checkIn)),
                  child: Text(
                    _isCompleted 
                        ? 'COMPLETED' 
                        : (_isWorking 
                            ? 'COMPLETE JOB' 
                            : (_hasArrived 
                                ? 'START WORK' 
                                : 'CHECK IN (ARRIVED)')),
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (_isCompleted) return Colors.grey;
    if (_isWorking) return Colors.green;
    if (_hasArrived) return Colors.orange;
    return Colors.blue;
  }

  String _getStatusText() {
    if (_isCompleted) return 'JOB COMPLETED';
    if (_isWorking) return 'WORK IN PROGRESS';
    if (_hasArrived) return 'ARRIVED AT LOCATION';
    return 'EN ROUTE TO CUSTOMER';
  }

  Color _getActionButtonColor() {
    if (_isWorking) return Colors.red; // Complete button
    return Colors.green; // Check-in/Start button
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }
}