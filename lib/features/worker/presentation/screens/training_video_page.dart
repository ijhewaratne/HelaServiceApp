import 'package:flutter/material.dart';
import '../../../../core/widgets/branded_widgets.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // Add to pubspec when ready

class TrainingVideoPage extends StatefulWidget {
  const TrainingVideoPage({super.key});

  @override
  State<TrainingVideoPage> createState() => _TrainingVideoPageState();
}

class _TrainingVideoPageState extends State<TrainingVideoPage> {
  bool _hasWatchedVideo = false;
  // late YoutubePlayerController _controller; // Uncomment when package added

  @override
  void initState() {
    super.initState();
    // Stubbing the controller setup
    // _controller = YoutubePlayerController(
    //   initialVideoId: 'iLnmTe5Q2qw', // Dummy Video
    //   flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    // );
  }

  void _simulateVideoComplete() {
    setState(() {
      _hasWatchedVideo = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mandatory Training')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Code of Conduct',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please watch this brief safety and conduct video before interacting with customers.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            
            // Video Player Stub Container
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
                      onPressed: _simulateVideoComplete, // Simulates user watching the video
                    ),
                    const SizedBox(height: 8),
                    const Text('Tap to simulate watching', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  _hasWatchedVideo ? Icons.check_circle : Icons.radio_button_unchecked, 
                  color: _hasWatchedVideo ? Colors.green : Colors.grey
                ),
                const SizedBox(width: 8),
                const Text('Video Completed', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),

            const Spacer(),
            BrandedButton(
              label: 'Mark Complete',
              onPressed: _hasWatchedVideo 
                ? () {
                    // Navigate to final step or Dashboard
                    // context.go('/worker/home');
                  } 
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please watch the video completely to proceed.')),
                    );
                  },
              backgroundColor: _hasWatchedVideo ? Colors.indigo : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
