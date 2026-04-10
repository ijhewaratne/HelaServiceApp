import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/worker_onboarding_bloc.dart';
import 'online_toggle_page.dart';
import 'training_page.dart';

class VerificationPendingPage extends StatefulWidget {
  final String workerId;

  const VerificationPendingPage({Key? key, required this.workerId}) : super(key: key);

  @override
  _VerificationPendingPageState createState() => _VerificationPendingPageState();
}

class _VerificationPendingPageState extends State<VerificationPendingPage> {
  @override
  void initState() {
    super.initState();
    // Check status periodically
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    await Future.delayed(Duration(seconds: 2));
    if (mounted) {
      context.read<WorkerOnboardingBloc>().add(CheckApplicationStatus(widget.workerId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<WorkerOnboardingBloc, WorkerOnboardingState>(
        listener: (context, state) {
          if (state is TrainingRequired) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => TrainingPage(application: state.application)),
            );
          } else if (state is ApplicationApproved) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => OnlineTogglePage()),
            );
          } else if (state is ApplicationRejected) {
            _showRejectionDialog(state.reason);
          }
        },
        builder: (context, state) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pending_actions,
                    size: 80,
                    color: Colors.orange,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Verification in Progress',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'We are reviewing your documents. This usually takes 24-48 hours.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  LinearProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Reference: ${widget.workerId.substring(0, 8).toUpperCase()}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: _checkStatus,
                    icon: Icon(Icons.refresh),
                    label: Text('Check Status'),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRejectionDialog(String? reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Application Rejected'),
        content: Text(reason ?? 'Your application did not meet our criteria. Please contact support.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}