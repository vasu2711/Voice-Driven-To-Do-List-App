import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAqH-oe4w9CkDJOVSN8VuQgBraR7vV6FEc',
    appId: '1:231523701585:web:bc734ea6fdd405b292f970',
    messagingSenderId: '231523701585',
    projectId: 'chat-89942',
    authDomain: 'chat-89942.firebaseapp.com',
    storageBucket: 'chat-89942.firebasestorage.app',
    measurementId: 'G-NW5K26QW7V',
  );
} 