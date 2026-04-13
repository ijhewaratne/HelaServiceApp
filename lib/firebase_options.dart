import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Secure Firebase Configuration
/// 
/// Phase 1: Security Fix - API keys moved to environment variables
/// 
/// IMPORTANT: 
/// - Never commit .env file to git
/// - For CI/CD, use environment secrets
/// - Regenerate API keys if they were ever exposed
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Load environment variables
    final apiKeyAndroid = dotenv.env['FIREBASE_API_KEY_ANDROID'];
    final apiKeyIos = dotenv.env['FIREBASE_API_KEY_IOS'];
    final apiKeyWeb = dotenv.env['FIREBASE_API_KEY_WEB'];
    final appIdAndroid = dotenv.env['FIREBASE_APP_ID_ANDROID'];
    final appIdIos = dotenv.env['FIREBASE_APP_ID_IOS'];
    final appIdWeb = dotenv.env['FIREBASE_APP_ID_WEB'];
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'];
    final authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'];
    final measurementId = dotenv.env['FIREBASE_MEASUREMENT_ID'];
    final iosBundleId = dotenv.env['FIREBASE_IOS_BUNDLE_ID'];

    // Validate required environment variables
    if (projectId == null || projectId.isEmpty) {
      throw StateError(
        'FIREBASE_PROJECT_ID not found in environment. '
        'Please check your .env file and ensure it\'s properly loaded.',
      );
    }

    if (kIsWeb) {
      _validateConfig('web', apiKeyWeb, appIdWeb);
      return FirebaseOptions(
        apiKey: apiKeyWeb!,
        appId: appIdWeb!,
        messagingSenderId: messagingSenderId ?? '',
        projectId: projectId,
        authDomain: authDomain ?? '$projectId.firebaseapp.com',
        storageBucket: storageBucket ?? '$projectId.firebasestorage.app',
        measurementId: measurementId,
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        _validateConfig('android', apiKeyAndroid, appIdAndroid);
        return FirebaseOptions(
          apiKey: apiKeyAndroid!,
          appId: appIdAndroid!,
          messagingSenderId: messagingSenderId ?? '',
          projectId: projectId,
          storageBucket: storageBucket ?? '$projectId.firebasestorage.app',
        );
      case TargetPlatform.iOS:
        _validateConfig('ios', apiKeyIos, appIdIos);
        return FirebaseOptions(
          apiKey: apiKeyIos!,
          appId: appIdIos!,
          messagingSenderId: messagingSenderId ?? '',
          projectId: projectId,
          storageBucket: storageBucket ?? '$projectId.firebasestorage.app',
          iosBundleId: iosBundleId ?? 'com.example.homeServiceApp',
        );
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

  static void _validateConfig(String platform, String? apiKey, String? appId) {
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError(
        'FIREBASE_API_KEY_${platform.toUpperCase()} not found in environment. '
        'Please check your .env file.',
      );
    }
    if (appId == null || appId.isEmpty) {
      throw StateError(
        'FIREBASE_APP_ID_${platform.toUpperCase()} not found in environment. '
        'Please check your .env file.',
      );
    }
  }

  // Legacy getters for backward compatibility (deprecated)
  @Deprecated('Use currentPlatform instead')
  static FirebaseOptions get web => currentPlatform;
  
  @Deprecated('Use currentPlatform instead')
  static FirebaseOptions get android => currentPlatform;
  
  @Deprecated('Use currentPlatform instead')
  static FirebaseOptions get ios => currentPlatform;
}

/// Development-only Firebase Options (for testing without .env)
/// 
/// WARNING: Do not use in production!
/// These are empty placeholders that will fail validation.
class DevFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'DEV_WEB_API_KEY',
    appId: 'DEV_WEB_APP_ID',
    messagingSenderId: 'DEV',
    projectId: 'helaservice-dev',
    authDomain: 'helaservice-dev.firebaseapp.com',
    storageBucket: 'helaservice-dev.firebasestorage.app',
  );
  
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'DEV_ANDROID_API_KEY',
    appId: 'DEV_ANDROID_APP_ID',
    messagingSenderId: 'DEV',
    projectId: 'helaservice-dev',
    storageBucket: 'helaservice-dev.firebasestorage.app',
  );
  
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'DEV_IOS_API_KEY',
    appId: 'DEV_IOS_APP_ID',
    messagingSenderId: 'DEV',
    projectId: 'helaservice-dev',
    storageBucket: 'helaservice-dev.firebasestorage.app',
    iosBundleId: 'com.example.homeServiceApp.dev',
  );
}
