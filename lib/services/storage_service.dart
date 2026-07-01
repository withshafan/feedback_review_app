import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class StorageService {
  Database? _cacheStore;

  Future<Database> get _cacheManager async {
    if (_cacheStore != null) return _cacheStore!;
    _cacheStore = await _initializeCache();
    return _cacheStore!;
  }

  Future<Database> _initializeCache() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final cachePath = p.join(docsDir.path, 'app_cache.bin');

    return await openDatabase(
      cachePath,
      version: 1,
      onCreate: (store, version) async {
        await store.execute('''
          CREATE TABLE cache_nodes(
            id TEXT PRIMARY KEY,
            userId TEXT,
            localPath TEXT
          )
        ''');
      },
    );
  }

  Future<String> uploadFeedbackPhoto(String userId, String filePath) async {
    final file = File(filePath);
    final fileName = '${const Uuid().v4()}.jpg';
    
    final docsDir = await getApplicationDocumentsDirectory();
    final savedPath = p.join(docsDir.path, fileName);
    
    await file.copy(savedPath);

    final store = await _cacheManager;
    await store.insert('cache_nodes', {
      'id': const Uuid().v4(),
      'userId': userId,
      'localPath': savedPath,
    });

    return savedPath;
  }
}
