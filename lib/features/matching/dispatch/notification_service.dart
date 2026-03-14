import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Request permission (important for iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted notification permission');
      }

      // Get the token
      String? token = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
        // TODO: Save this token to the user's Firestore document
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Got a message whilst in the foreground!');
          print('Message data: ${message.data}');
          if (message.notification != null) {
            print('Message also contained a notification: ${message.notification}');
          }
        }
        // TODO: Show local notification or snackbar
      });

      // Handle background/terminated message taps
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('A new onMessageOpenedApp event was published!');
        }
        // TODO: Navigate based on message.data
      });
    } else {
      if (kDebugMode) {
        print('User declined or has not accepted notification permissions');
      }
    }
  }

  // Simulate triggering a notification to backend
  Future<void> sendMockNotification(String userId, String title, String body) async {
    // In a real app, this would trigger a Callable Cloud Function
    // Example: sendNotification(userId, title, body)
    if (kDebugMode) {
      print('Mock Notification sent to user $userId: $title - $body');
    }
  }
}
