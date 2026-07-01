import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_model.dart';
import 'auth_service.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  FeedbackService(this._authService);

  Stream<List<FeedbackModel>> getFeedbackStream() async* {
    final user = _authService.currentUser;
    if (user == null) {
      yield [];
      return;
    }

    final role = await _authService.getUserRole(user.uid);
    Query query = _firestore.collection('feedback').orderBy('createdAt', descending: true);

    if (role != 'admin') {
      // Normal users only see their own feedback
      query = query.where('userId', isEqualTo: user.uid);
    }

    yield* query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => FeedbackModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> addFeedback(double rating, String comment) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('Must be logged in to submit feedback');

    await _firestore.collection('feedback').add({
      'userId': user.uid,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'open',
    });
  }

  Future<void> updateFeedbackComment(String id, double rating, String comment) async {
    await _firestore.collection('feedback').doc(id).update({
      'rating': rating,
      'comment': comment,
    });
  }

  Future<void> addAdminReply(String id, String reply) async {
    await _firestore.collection('feedback').doc(id).update({
      'adminReply': reply,
      'adminRepliedAt': FieldValue.serverTimestamp(),
      'status': 'reviewed', // Automatically mark as reviewed when replying
    });
  }

  Future<void> updateFeedbackStatus(String id, String newStatus) async {
    await _firestore.collection('feedback').doc(id).update({
      'status': newStatus,
    });
  }

  Future<void> deleteFeedback(String id) async {
    await _firestore.collection('feedback').doc(id).delete();
  }
}
