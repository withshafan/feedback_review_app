import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String userId;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String status; // "open" or "reviewed"

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.status,
  });

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FeedbackModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'open',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }
}
