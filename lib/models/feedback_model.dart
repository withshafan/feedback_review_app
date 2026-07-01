import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String userId;
  final String userEmail;
  final double rating;
  final String comment;
  final String category; // "bug"|"feature"|"praise"|"complaint"|"general"
  final String? photoUrl;
  final String status; // "open"|"reviewed"
  final String? adminReplyText;
  final DateTime? adminRepliedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.rating,
    required this.comment,
    required this.category,
    this.photoUrl,
    required this.status,
    this.adminReplyText,
    this.adminRepliedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    Map<String, dynamic>? adminReply = data['adminReply'] != null 
        ? Map<String, dynamic>.from(data['adminReply']) 
        : null;

    return FeedbackModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      category: data['category'] ?? 'general',
      photoUrl: data['photoUrl'],
      status: data['status'] ?? 'open',
      adminReplyText: adminReply?['text'],
      adminRepliedAt: (adminReply?['repliedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'rating': rating,
      'comment': comment,
      'category': category,
      'photoUrl': photoUrl,
      'status': status,
      'adminReply': adminReplyText != null
          ? {
              'text': adminReplyText,
              'repliedAt': adminRepliedAt != null ? Timestamp.fromDate(adminRepliedAt!) : FieldValue.serverTimestamp(),
            }
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
