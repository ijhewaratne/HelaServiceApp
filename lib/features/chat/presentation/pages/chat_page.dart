import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/chat_bloc.dart';

class ChatPage extends StatefulWidget {
  final String bookingId;

  const ChatPage({super.key, required this.bookingId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(LoadChat(widget.bookingId));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(ChatLoaded state) {
    final text = _messageController.text;
    if (text.trim().isEmpty || state.isSending) return;
    context.read<ChatBloc>().add(SendMessage(text));
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatLoaded && state.sendError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to send: ${state.sendError}')),
            );
          }
        },
        builder: (context, state) {
          if (state is ChatError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            );
          }

          if (state is! ChatLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: state.messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Say hello!',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final message =
                              state.messages[state.messages.length - 1 - index];
                          final isMine =
                              message['senderId'] == state.currentUserId;
                          return _MessageBubble(
                            text: message['message'] as String? ?? '',
                            isMine: isMine,
                            createdAt: message['createdAt'],
                          );
                        },
                      ),
              ),
              const Divider(height: 1),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Type a message…',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _send(state),
                        ),
                      ),
                      const SizedBox(width: 8),
                      state.isSending
                          ? const SizedBox(
                              width: 40,
                              height: 40,
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              onPressed: () => _send(state),
                              icon: const Icon(Icons.send),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final dynamic createdAt;

  const _MessageBubble({
    required this.text,
    required this.isMine,
    required this.createdAt,
  });

  String? get _timeLabel {
    if (createdAt is Timestamp) {
      return DateFormat.jm().format((createdAt as Timestamp).toDate());
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade200;
    final textColor = isMine ? Colors.white : Colors.black87;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: TextStyle(color: textColor)),
            if (_timeLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                _timeLabel!,
                style: TextStyle(
                  fontSize: 10,
                  color: isMine ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
