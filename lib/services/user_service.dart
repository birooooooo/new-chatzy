import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final String collection = 'users';

  /// Create or Update user in Firestore
  Future<void> saveUser(UserModel user) async {
    await _firestore
        .collection(collection)
        .doc(user.id)
        .set(user.toMap(), SetOptions(merge: true))
        .timeout(const Duration(seconds: 10));
  }

  /// Get user by ID
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore
        .collection(collection)
        .doc(uid)
        .get()
        .timeout(const Duration(seconds: 10));
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  /// Check if username is taken
  Future<bool> isUsernameTaken(String username) async {
    final query = await _firestore
        .collection(collection)
        .where('username', isEqualTo: username)
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 10));
    return query.docs.isNotEmpty;
  }

  /// Find user by username (for login)
  Future<UserModel?> getUserByUsername(String username) async {
    final query = await _firestore
        .collection(collection)
        .where('username', isEqualTo: username)
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 10));
    
    if (query.docs.isNotEmpty) {
      return UserModel.fromMap(query.docs.first.data());
    }
    return null;
  }

  /// Search users by name or username
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    // Simple search implementation
    // Ideally use Algolia or specialized search service for better results
    final result = await _firestore
        .collection(collection)
        .where('searchKeywords', arrayContains: query.toLowerCase())
        .limit(20)
        .get()
        .timeout(const Duration(seconds: 10));

    return result.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  /// Generate search keywords for a user
  List<String> generateKeywords(String name, String? username) {
    Set<String> keywords = {};
    
    // Split name
    final nameParts = name.toLowerCase().split(' ');
    for (var part in nameParts) {
      keywords.add(part);
      // Add prefixes for partial matches
      for (int i = 1; i <= part.length; i++) {
        keywords.add(part.substring(0, i));
      }
    }

    // Add username
    if (username != null) {
      final cleanUsername = username.toLowerCase();
      keywords.add(cleanUsername);
      for (int i = 1; i <= cleanUsername.length; i++) {
        keywords.add(cleanUsername.substring(0, i));
      }
    }

    return keywords.toList();
  }
}
