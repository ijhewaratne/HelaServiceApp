import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// IMPORTANT: Run `flutterfire configure` to generate the actual configuration.
/// This file is a placeholder until Firebase is properly configured.
///
/// Example:
/// ```bash
/// flutterfire configure --project=helaservice-prod
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
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Placeholder web configuration

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBas5TP-dLlitnApRgFgJTYUVgZNxWyH9E',
    appId: '1:919789688280:web:dad93a049bb0edb22dcead',
    messagingSenderId: '919789688280',
    projectId: 'helaservice-prod',
    authDomain: 'helaservice-prod.firebaseapp.com',
    storageBucket: 'helaservice-prod.firebasestorage.app',
    measurementId: 'G-8TZ0E1XXFR',
  );

  /// Replace with actual values from Firebase Console

  /// Placeholder Android configuration

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBYuHtxndpkFN6NkJER9dO1xjJXQnDE-uA',
    appId: '1:919789688280:android:c42bf2fa62a82c4d2dcead',
    messagingSenderId: '919789688280',
    projectId: 'helaservice-prod',
    storageBucket: 'helaservice-prod.firebasestorage.app',
  );

  /// Replace with actual values from Firebase Console

  /// Placeholder iOS configuration

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDtJojKAsB_zIsNrA6Qi0np9ZvovrjcVuE',
    appId: '1:919789688280:ios:bc0204e60430bf212dcead',
    messagingSenderId: '919789688280',
    projectId: 'helaservice-prod',
    storageBucket: 'helaservice-prod.firebasestorage.app',
    iosBundleId: 'com.example.homeServiceApp',
  );

  /// Replace with actual values from Firebase Console
}