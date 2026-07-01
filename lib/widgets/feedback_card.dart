import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/feedback_model.dart';
import '../services/auth_service.dart';
import '../services/feedback_service.dart';
import '../screens/submit_feedback_screen.dart';

class FeedbackCard extends StatelessWidget {
  final FeedbackModel feedback;
  final VoidCallback? onTap;

  const FeedbackCard({
    super.key,
    required this.feedback,
    this.onTap,
  });

  Color _getCategoryColor(BuildContext context, String category) {
    switch (category.toLowerCase()) {
      case 'bug':
        return Colors.red.shade400;
      case 'feature':
        return Colors.blue.shade400;
      case 'praise':
        return Colors.green.shade400;
      case 'complaint':
        return Colors.orange.shade400;
      default:
        return Colors.grey.shade500;
    }
  }

  Future<void> _deleteFeedback(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feedback?'),
        content: const Text('Are you sure you want to delete this feedback? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await context.read<FeedbackService>().deleteFeedback(feedback.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feedback deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;
    final isOwner = currentUser != null && currentUser.uid == feedback.userId;

    String initials = feedback.userEmail.length >= 2 
        ? feedback.userEmail.substring(0, 2).toUpperCase() 
        : 'U';

    return Hero(
      tag: 'feedback_card_${feedback.id}',
      child: Material(
        type: MaterialType.transparency,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          initials,
                          style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    feedback.userEmail.split('@')[0],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(context, feedback.category),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    feedback.category.toUpperCase(),
                                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            RatingBarIndicator(
                              rating: feedback.rating,
                              itemBuilder: (context, index) => Icon(
                                Icons.star,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              itemCount: 5,
                              itemSize: 16.0,
                              direction: Axis.horizontal,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat.yMMMd().format(feedback.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                      if (isOwner)
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SubmitFeedbackScreen(existingFeedback: feedback),
                                ),
                              );
                            } else if (val == 'delete') {
                              _deleteFeedback(context);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          feedback.comment,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                      ),
                      if (feedback.photoUrl != null) ...[
                        const SizedBox(width: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: feedback.photoUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey[300]),
                            errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
