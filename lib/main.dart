import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'providers/character_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/story_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';
import 'services/mock_auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';

import 'services/storage_service.dart';
import 'services/database_service.dart';
import 'firebase_options.dart';
import 'models/user_model.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Services
  await StorageService.init();
  if (!kIsWeb) {
    await DatabaseService.database; // Trigger init
  }
  
  bool firebaseInitialized = false;
  // Firebase Desktop (Windows) support requires a registered Windows app in Firebase Console.
  // On Windows and Web, we use MockAuthService for local development/testing.
  final isDesktopOrWeb = kIsWeb || defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

  if (!isDesktopOrWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseInitialized = true;
      debugPrint("Firebase initialized successfully");
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
      debugPrint("Falling back to MockAuthService for development.");
    }
  } else {
    debugPrint("Desktop/Web platform detected — using MockAuthService.");
  }

  MediaKit.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) {
            final service = firebaseInitialized ? AuthService() : MockAuthService();
            if (firebaseInitialized) {
              service.seedTestUsers();
            }
            return service;
          },
        ),
        ChangeNotifierProvider(create: (_) => CharacterProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const ChatzyApp(),
    ),
  );
}

class ChatzyApp extends StatelessWidget {
  const ChatzyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isLight = themeProvider.isLightTheme;
        return MaterialApp(
          title: 'CHATZY',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isLight ? ThemeMode.light : ThemeMode.dark,
          builder: (context, child) {
            ScreenSize.init(context);
            return child!;
          },
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthWrapper(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
          },
        );
      },
    );
  }
}


class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Guarantee that the new beautiful 3D Splash Screen shows for at least 3.5s
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder<UserModel?>( // Specify type
      stream: authService.userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          // Initialize ChatProvider and seed demo stories
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<ChatProvider>(context, listen: false).initialize(user.id);
          });
          return const HomeScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}
