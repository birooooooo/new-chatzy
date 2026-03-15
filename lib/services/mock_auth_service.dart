import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../models/user_model.dart';
import 'user_service.dart';

/// A mock version of AuthService that doesn't require Firebase.
/// Useful for development and testing when Firebase is not configured.
class MockAuthService extends AuthService {
  bool _isLoggedIn = false;
  String? _name;
  String? _email;
  final UserService _userService = UserService();

  @override
  Stream<UserModel?> get userStream => Stream.value(_isLoggedIn ? currentUser : null);

  @override
  UserModel? get currentUser => _isLoggedIn 
    ? UserModel(
        id: 'mock-user-id',
        name: _name ?? 'Mock User',
        email: _email ?? 'test@example.com',
      )
    : null;

  @override
  Future<UserModel?> signUp({
    required String email,
    required String password,
    String? name,
    String? username,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _isLoggedIn = true;
    _email = email;
    _name = name;
    notifyListeners();
    return currentUser;
  }

  @override
  Future<UserModel?> signIn({
    required String loginInput,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _isLoggedIn = true;
    _email = loginInput.contains('@') ? loginInput : '$loginInput@example.com';
    _name = 'Mock User';
    notifyListeners();
    return currentUser;
  }

  @override
  Future<void> signOut() async {
    _isLoggedIn = false;
    notifyListeners();
  }

  @override
  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> updateProfile({String? name, String? avatar, String? bio}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (name != null) _name = name;
    // Avatar and bio mock update logic could be added here if needed
    notifyListeners();
  }

  @override
  Future<void> seedTestUsers() async {
    try {
      final testUserId = 'biro_test_id';
      // Use the actual UserService to save the test user to Firestore
      // so real devices can search and chat with this web test account.
      final existing = await _userService.getUser(testUserId);
      if (existing == null) {
        final testUser = UserModel(
          id: testUserId,
          name: 'Biro',
          email: 'biro@test.com',
          username: 'biro',
          searchKeywords: _userService.generateKeywords('Biro', 'biro'),
          isOnline: true,
          avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Biro',
        );
        await _userService.saveUser(testUser);
        debugPrint("MockAuthService: Seeded 'Biro' test user to Firestore.");
      }
    } catch (e) {
      debugPrint("MockAuthService: Could not seed test user to Firestore (likely Web with no Firebase config): $e");
    }
  }
}
