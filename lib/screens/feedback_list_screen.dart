import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/feedback_model.dart';
import '../services/feedback_service.dart';
import '../widgets/feedback_card.dart';
import 'submit_feedback_screen.dart';

class FeedbackListScreen extends StatefulWidget {
  const FeedbackListScreen({super.key});

  @override
  State<FeedbackListScreen> createState() => _FeedbackListScreenState();
}

class _FeedbackListScreenState extends State<FeedbackListScreen> {
  Future<void> _refreshData() async {
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {});
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Shimmer.fromColors(
              baseColor: Theme.of(context).brightness == Brightness.light ? Colors.grey[300]! : Colors.grey[800]!,
              highlightColor: Theme.of(context).brightness == Brightness.light ? Colors.grey[100]! : Colors.grey[700]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 100, height: 16, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(width: 60, height: 12, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(width: double.infinity, height: 14, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 200, height: 14, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No feedback yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to share your thoughts.',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedbackService = context.read<FeedbackService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Feedback'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: StreamBuilder<List<FeedbackModel>>(
          stream: feedbackService.getFeedbackStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmerLoading();
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error loading feedback: ${snapshot.error}'));
            }

            final feedbackList = snapshot.data ?? [];

            if (feedbackList.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: feedbackList.length,
              itemBuilder: (context, index) {
                final item = feedbackList[index];
                return FeedbackCard(
                  feedback: item,
                  onTap: () {
                    // Navigate to details in Phase 7
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SubmitFeedbackScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
