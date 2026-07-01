import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../models/feedback_model.dart';

class FeedbackCard extends StatelessWidget {
  final FeedbackModel feedback;
  final VoidCallback? onTap;

  const FeedbackCard({
    super.key,
    required this.feedback,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Generate initials from user ID
    String initials = feedback.userId.length >= 2 
        ? feedback.userId.substring(0, 2).toUpperCase() 
        : 'U';

    String dateStr = DateFormat.yMMMd().add_jm().format(feedback.createdAt);

    return Hero(
      tag: 'feedback_card_${feedback.id}',
      child: Material(
        type: MaterialType.transparency,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          initials,
                          style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RatingBarIndicator(
                              rating: feedback.rating,
                              itemBuilder: (context, index) => Icon(
                                Icons.star,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              itemCount: 5,
                              itemSize: 18.0,
                              direction: Axis.horizontal,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateStr,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (feedback.status == 'reviewed')
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    feedback.comment,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15),
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
