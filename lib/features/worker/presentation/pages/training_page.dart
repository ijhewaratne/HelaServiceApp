import 'package:flutter/material.dart';
import '../../domain/entities/worker_application.dart';
import 'online_toggle_page.dart';

class TrainingPage extends StatelessWidget {
  final WorkerApplication application;

  const TrainingPage({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_outline, size: 100, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Training Videos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Watch the required training videos to continue',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const OnlineTogglePage()),
                );
              },
              child: const Text('Complete Training'),
            ),
          ],
        ),
      ),
    );
  }
}
