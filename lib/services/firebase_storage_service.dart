import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class FirebaseStorageService {
  FirebaseStorage get _storage => FirebaseStorage.instance;
  
  /// Upload a file to Firebase Storage and return the download URL
  /// [file] is the local file to upload
  /// [folder] is the storage folder (e.g., 'chat_images', 'avatars')
  Future<String?> uploadFile(File file, String folder) async {
    try {
      final fileName = path.basename(file.path);
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final ref = _storage.ref().child('$folder/$uniqueFileName');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file to Firebase Storage: $e');
      return null;
    }
  }

  /// Upload a chat image
  Future<String?> uploadChatImage(File file, String chatId) async {
    return await uploadFile(file, 'chats/$chatId/images');
  }

  /// Upload a chat audio
  Future<String?> uploadChatAudio(File file, String chatId) async {
    return await uploadFile(file, 'chats/$chatId/audio');
  }

  /// Upload a user avatar
  Future<String?> uploadUserAvatar(File file, String userId) async {
    return await uploadFile(file, 'users/$userId/avatars');
  }

  /// Upload raw bytes (for web where File paths don't exist)
  Future<String?> uploadChatImageBytes(Uint8List bytes, String chatId, String fileName) async {
    try {
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final ref = _storage.ref().child('chats/$chatId/images/$uniqueName');
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading bytes to Firebase Storage: $e');
      return null;
    }
  }
}
