import 'dart:io';
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
}
