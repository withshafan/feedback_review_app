import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFeedbackPhoto(String userId, String filePath) async {
    final file = File(filePath);
    final fileName = '${const Uuid().v4()}.jpg';
    final ref = _storage.ref().child('users/$userId/feedback_photos/$fileName');
    
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}
