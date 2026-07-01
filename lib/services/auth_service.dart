import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get userStream => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (credential.user != null) {
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['role'] ?? 'user';
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }
    return 'user';
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
