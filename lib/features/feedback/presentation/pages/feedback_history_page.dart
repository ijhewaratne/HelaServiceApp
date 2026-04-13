import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/branded_widgets.dart';
import '../../domain/entities/feedback.dart';
import '../bloc/feedback_bloc.dart';

/// Page for viewing user's feedback history
class FeedbackHistoryPage extends StatelessWidget {
  final String userId;

  const FeedbackHistoryPage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HelaAppBar(title: 'My Feedback'),
      body: BlocBuilder<FeedbackBloc, FeedbackState>(
        builder: (context, state) {
          if (state is FeedbackLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is FeedbackError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<FeedbackBloc>().add(
                            LoadUserFeedback(userId: userId),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is FeedbackLoaded) {
            if (state.feedbackList.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildFeedbackList(context, state.feedbackList);
          }

          // Initial load
          context.read<FeedbackBloc>().add(LoadUserFeedback(userId: userId));
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/feedback/submit');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Feedback'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.feedback_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No feedback submitted yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your thoughts to help us improve',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/feedback/submit');
            },
            icon: const Icon(Icons.add),
            label: const Text('Submit Feedback'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackList(BuildContext context, List<Feedback> feedbackList) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<FeedbackBloc>().add(LoadUserFeedback(userId: userId));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: feedbackList.length,
        itemBuilder: (context, index) {
          final feedback = feedbackList[index];
          return _FeedbackCard(
            feedback: feedback,
            onTap: () {
              _showFeedbackDetail(context, feedback);
            },
          );
        },
      ),
    );
  }

  void _showFeedbackDetail(BuildContext context, Feedback feedback) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category and status
                  Row(
                    children: [
                      Text(
                        feedback.category.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feedback.category.displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (feedback.isResolved)
                        HelaStatusBadge(
                          text: 'Resolved',
                          type: StatusType.success,
                        )
                      else
                        HelaStatusBadge(
                          text: 'Pending',
                          type: StatusType.pending,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date
                  Text(
                    'Submitted on ${DateFormat('MMM d, yyyy • h:mm a').format(feedback.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rating if available
                  if (feedback.rating != null) ...[
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < feedback.rating!
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text('${feedback.rating}/5'),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Message
                  Text(
                    'Your Feedback',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(feedback.message),
                  const SizedBox(height: 24),

                  // Admin response if available
                  if (feedback.adminResponse != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.support_agent,
                                size: 18,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Response from Support',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(feedback.adminResponse!),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Close button
                  HelaButton(
                    text: 'Close',
                    type: ButtonType.secondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final Feedback feedback;
  final VoidCallback onTap;

  const _FeedbackCard({
    required this.feedback,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HelaCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                feedback.category.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  feedback.category.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (feedback.isResolved)
                const Icon(Icons.check_circle, color: Colors.green, size: 20)
              else
                Icon(Icons.pending, color: Colors.orange[400], size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feedback.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (feedback.rating != null) ...[
                ...List.generate(5, (index) {
                  return Icon(
                    index < feedback.rating! ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 14,
                  );
                }),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  DateFormat('MMM d, yyyy').format(feedback.createdAt),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
