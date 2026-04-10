import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  final String jobId;
  
  const ChatPage({super.key, required this.jobId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Center(
        child: Text('Chat for job: $jobId'),
      ),
    );
  }
}
