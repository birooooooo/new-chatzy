import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'user_service.dart';

class AuthService extends ChangeNotifier {
  FirebaseAuth? _authInstance;
  final UserService _userService = UserService();
  
  FirebaseAuth get _auth {
    try {
      return _authInstance ??= FirebaseAuth.instance;
    } catch (e) {
      debugPrint("Firebase not initialized: $e");
      rethrow;
    }
  }

  // Stream to track auth state changes
  Stream<UserModel?> get userStream => _auth.authStateChanges().map(_userFromFirebase);

  // Get current user
  UserModel? get currentUser => _userFromFirebase(_auth.currentUser);

  // Helper to convert Firebase User to UserModel
  UserModel? _userFromFirebase(User? user) {
    if (user == null) return null;
    return UserModel(
      id: user.uid,
      name: user.displayName ?? 'User',
      email: user.email ?? '',
      avatar: user.photoURL,
    );
  }

  // Sign Up with Email and Password
  Future<UserModel?> signUp({
    required String email,
    required String password,
    String? name,
    String? username,
  }) async {
    try {
      // check if username is taken
      if (username != null) {
        final isTaken = await _userService.isUsernameTaken(username);
        if (isTaken) {
          throw FirebaseAuthException(
            code: 'username-taken', 
            message: 'The username is already taken.'
          );
        }
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (name != null) {
        await userCredential.user?.updateDisplayName(name);
      }

      // Create UserModel and save to Firestore
      if (userCredential.user != null) {
        final newUser = UserModel(
          id: userCredential.user!.uid,
          name: name ?? 'User',
          email: email,
          avatar: userCredential.user!.photoURL,
          username: username,
          searchKeywords: _userService.generateKeywords(name ?? 'User', username),
        );
        try {
          await _userService.saveUser(newUser);
        } catch (e) {
          // If Firestore save fails (e.g., due to timeout/App Check), clean up Auth user
          debugPrint("Failed to save user to Firestore, deleting Auth user to avoid dangling account: $e");
          await userCredential.user?.delete();
          throw Exception("Failed to setup user profile: $e");
        }
      }

      return _userFromFirebase(userCredential.user);
    } catch (e) {
      debugPrint("Sign Up error: $e");
      rethrow;
    }
  }

  // Sign In with Email OR Username
  Future<UserModel?> signIn({
    required String loginInput, // Can be email or username
    required String password,
  }) async {
    try {
      String emailToUse = loginInput.trim();

      // If input isn't an email, assume it's a username and try to find the email
      if (!loginInput.contains('@')) {
        final user = await _userService.getUserByUsername(loginInput.trim());
        if (user == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No account found with this username.'
          );
        }
        emailToUse = user.email;
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );
      
      // Sync latest data from Firestore to local if needed, 
      // but _userFromFirebase mainly uses Auth object data. 
      // We could fetch full profile here if we wanted custom fields in memory immediately.
      
      return _userFromFirebase(userCredential.user);
    } on FirebaseAuthException catch (e) {
      debugPrint("Sign In error: ${e.message}");
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateProfile({String? name, String? avatar, String? bio}) async {
    final user = _auth.currentUser;
    if (user != null) {
      if (name != null) await user.updateDisplayName(name);
      if (avatar != null) await user.updatePhotoURL(avatar);
      
      // Sync with Firestore
      final existingUser = await _userService.getUser(user.uid);
      if (existingUser != null) {
        final updatedUser = existingUser.copyWith(
          name: name, 
          avatar: avatar,
          bio: bio,
          // Regenerate keywords if name changed
          searchKeywords: name != null 
              ? _userService.generateKeywords(name, existingUser.username) 
              : null,
        );
        await _userService.saveUser(updatedUser);
      }
    }
    notifyListeners();
  }
  Future<void> seedTestUsers() async {
    final testUsers = [
      {
        'id': 'user1_id',
        'name': 'User One',
        'email': 'user1@test.com',
        'username': 'user1',
        'avatar': 'https://api.dicebear.com/7.x/avataaars/svg?seed=User1',
      },
      {
        'id': 'user2_id',
        'name': 'User Two',
        'email': 'user2@test.com',
        'username': 'user2',
        'avatar': 'https://api.dicebear.com/7.x/avataaars/svg?seed=User2',
      },
      {
        'id': 'user3_id',
        'name': 'User Three',
        'email': 'user3@test.com',
        'username': 'user3',
        'avatar': 'https://api.dicebear.com/7.x/avataaars/svg?seed=User3',
      },
    ];

    for (var u in testUsers) {
      try {
        final existing = await _userService.getUser(u['id'] as String);
        if (existing == null) {
          final testUser = UserModel(
            id: u['id'] as String,
            name: u['name'] as String,
            email: u['email'] as String,
            username: u['username'] as String,
            searchKeywords: _userService.generateKeywords(u['name'] as String, u['username'] as String),
            isOnline: true,
            avatar: u['avatar'] as String,
          );
          await _userService.saveUser(testUser);
          debugPrint("AuthService: Seeded '${u['username']}' test user.");
        }
      } catch (e) {
        debugPrint("AuthService: Error seeding user ${u['username']}: $e");
      }
    }
  }
}
