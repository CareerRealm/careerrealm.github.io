// File generated from your google-services.json
// Project: harmonitimer
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAnQ62mCGDS5lq3a64vxemVMW7f9L6_KJo',
    appId: '1:1028280226620:android:e6d236ceab6ca96b3e8439',
    messagingSenderId: '1028280226620',
    projectId: 'career-realm',
    storageBucket: 'career-realm.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDM8bMY73QHu0WNNcGuC7C44rn5koSocbc',
    appId: '1:1028280226620:ios:c385877c50f1a3253e8439',
    messagingSenderId: '1028280226620',
    projectId: 'career-realm',
    storageBucket: 'career-realm.firebasestorage.app',
    iosBundleId: 'com.zworlddev.careerrealm',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCQZgrgNksGuOYRj-P_zVEkrDFgktUhBCQ',
    appId: '1:1028280226620:web:c961da8aacc581a63e8439',
    messagingSenderId: '1028280226620',
    projectId: 'career-realm',
    authDomain: 'career-realm.firebaseapp.com',
    storageBucket: 'career-realm.firebasestorage.app',
    measurementId: 'G-989XX2B6KY',
  );

  // Desktop platforms use the same Firebase project via REST API.
  // The web config works because FlutterFire desktop plugins communicate
  // through the Firebase C++ SDK and REST endpoints — no platform-specific

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCQZgrgNksGuOYRj-P_zVEkrDFgktUhBCQ',
    appId: '1:1028280226620:web:f3dc680011a94f963e8439',
    messagingSenderId: '1028280226620',
    projectId: 'career-realm',
    authDomain: 'career-realm.firebaseapp.com',
    storageBucket: 'career-realm.firebasestorage.app',
    measurementId: 'G-7XRP07Y6Y8',
  );

  // app registration is needed beyond the project credentials.

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDM8bMY73QHu0WNNcGuC7C44rn5koSocbc',
    appId: '1:1028280226620:ios:887a61d51be3e8473e8439',
    messagingSenderId: '1028280226620',
    projectId: 'career-realm',
    storageBucket: 'career-realm.firebasestorage.app',
    iosBundleId: 'com.zworlddev.harmonitimer',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyCnS3Mdf_dr3OKyuxPDhYkTQjalshpceQQ',
    appId: '1:831934255945:web:40243ce90d2f272923c098',
    messagingSenderId: '831934255945',
    projectId: 'harmonitimer',
    storageBucket: 'harmonitimer.firebasestorage.app',
    authDomain: 'harmonitimer.firebaseapp.com',
  );
}