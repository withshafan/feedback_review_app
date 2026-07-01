import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_model.dart';
import 'auth_service.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  FeedbackService(this._authService);

  Stream<List<FeedbackModel>> getFeedbackStream() {
    return _firestore
        .collection('feedback')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FeedbackModel.fromFirestore(doc)).toList();
    });
  }

  Stream<List<FeedbackModel>> getMyFeedbackStream() async* {
    final user = _authService.currentUser;
    if (user == null) {
      yield [];
      return;
    }

    yield* _firestore
        .collection('feedback')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FeedbackModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> addFeedback({
    required double rating,
    required String comment,
    required String category,
    String? photoUrl,
  }) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('Must be logged in to submit feedback');

    await _firestore.collection('feedback').add({
      'userId': user.uid,
      'userEmail': user.email ?? '',
      'rating': rating,
      'comment': comment,
      'category': category,
      'photoUrl': photoUrl,
      'status': 'open',
      'adminReply': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFeedback({
    required String id,
    required double rating,
    required String comment,
    required String category,
    String? photoUrl,
  }) async {
    await _firestore.collection('feedback').doc(id).update({
      'rating': rating,
      'comment': comment,
      'category': category,
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addAdminReply(String id, String replyText) async {
    await _firestore.collection('feedback').doc(id).update({
      'adminReply': {
        'text': replyText,
        'repliedAt': FieldValue.serverTimestamp(),
      },
      'status': 'reviewed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFeedbackStatus(String id, String status) async {
    await _firestore.collection('feedback').doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteFeedback(String id) async {
    await _firestore.collection('feedback').doc(id).delete();
  }
}
