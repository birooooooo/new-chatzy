// File generated manually from google-services.json
// This file is configured for Android platform
// For additional platforms, install Firebase CLI and run: flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCthQW9nFakUWC__8rlOqiyGou-_kJgM80',
    appId: '1:765033234298:android:553d10c9949f557d5020c3',
    messagingSenderId: '765033234298',
    projectId: 'chitzy-7ce77',
    storageBucket: 'chitzy-7ce77.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCthQW9nFakUWC__8rlOqiyGou-_kJgM80',
    appId: '1:765033234298:web:windows_debug_placeholder',
    messagingSenderId: '765033234298',
    projectId: 'chitzy-7ce77',
    storageBucket: 'chitzy-7ce77.firebasestorage.app',
    authDomain: 'chitzy-7ce77.firebaseapp.com',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCthQW9nFakUWC__8rlOqiyGou-_kJgM80',
    appId: '1:765033234298:web:553d10c9949f557d5020c3',
    messagingSenderId: '765033234298',
    projectId: 'chitzy-7ce77',
    authDomain: 'chitzy-7ce77.firebaseapp.com',
    storageBucket: 'chitzy-7ce77.firebasestorage.app',
  );
}
