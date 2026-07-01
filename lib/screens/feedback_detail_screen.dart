import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/feedback_model.dart';
import '../services/auth_service.dart';
import '../services/feedback_service.dart';
import 'submit_feedback_screen.dart';

class FeedbackDetailScreen extends StatefulWidget {
  final FeedbackModel feedback;

  const FeedbackDetailScreen({super.key, required this.feedback});

  @override
  State<FeedbackDetailScreen> createState() => _FeedbackDetailScreenState();
}

class _FeedbackDetailScreenState extends State<FeedbackDetailScreen> {
  String _userRole = 'user';
  bool _isLoading = true;
  final _replyController = TextEditingController();
  bool _isSubmittingReply = false;

  @override
  void initState() {
    super.initState();
    _fetchRole();
    _replyController.text = widget.feedback.adminReplyText ?? '';
  }

  Future<void> _fetchRole() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user != null) {
      final role = await authService.getUserRole(user.uid);
      if (mounted) {
        setState(() {
          _userRole = role;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleStatus(bool isReviewed) async {
    try {
      final newStatus = isReviewed ? 'reviewed' : 'open';
      await context.read<FeedbackService>().updateFeedbackStatus(widget.feedback.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteFeedback() async {
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

    if (confirm == true) {
      try {
        await context.read<FeedbackService>().deleteFeedback(widget.feedback.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feedback deleted successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete feedback: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) return;
    setState(() => _isSubmittingReply = true);
    try {
      await context.read<FeedbackService>().addAdminReply(
            widget.feedback.id,
            _replyController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin reply posted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post reply: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingReply = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;
    final isOwner = currentUser != null && currentUser.uid == widget.feedback.userId;
    final isReviewed = widget.feedback.status == 'reviewed';

    String initials = widget.feedback.userEmail.length >= 2 
        ? widget.feedback.userEmail.substring(0, 2).toUpperCase() 
        : 'U';
    String dateStr = DateFormat.yMMMd().add_jm().format(widget.feedback.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Details'),
        actions: [
          if (!_isLoading && (_userRole == 'admin' || isOwner))
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _deleteFeedback,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Hero(
            tag: 'feedback_card_${widget.feedback.id}',
            child: Material(
              type: MaterialType.transparency,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.feedback.userEmail,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(context, widget.feedback.category),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        widget.feedback.category.toUpperCase(),
                                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
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
                          if (isOwner)
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SubmitFeedbackScreen(
                                      existingFeedback: widget.feedback,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit),
                            ),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Rating:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          RatingBarIndicator(
                            rating: widget.feedback.rating,
                            itemBuilder: (context, index) => Icon(
                              Icons.star,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            itemCount: 5,
                            itemSize: 24.0,
                            direction: Axis.horizontal,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (widget.feedback.photoUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: widget.feedback.photoUrl!,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey[300], child: const Center(child: CircularProgressIndicator())),
                            errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      const Text(
                        'Comment:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.feedback.comment,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      if (widget.feedback.adminReplyText != null) ...[
                        const Divider(height: 40),
                        const Text(
                          'Response from Admin:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.feedback.adminReplyText!,
                                style: const TextStyle(fontSize: 15, height: 1.4),
                              ),
                              if (widget.feedback.adminRepliedAt != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Replied at: ${DateFormat.yMMMd().add_jm().format(widget.feedback.adminRepliedAt!)}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (!_isLoading && _userRole == 'admin') ...[
                        const Divider(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Mark as Reviewed:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Switch(
                              value: isReviewed,
                              onChanged: _toggleStatus,
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Reply to Feedback:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _replyController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Type response text here...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSubmittingReply ? null : _submitReply,
                            child: _isSubmittingReply
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Post Reply'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
