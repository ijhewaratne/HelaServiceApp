import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  NotificationService(this._messaging, this._firestore);

  Future<void> initialize() async {
    // Request permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Local notifications setup
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);
    
    // FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }
    
    // Token refresh
    _messaging.onTokenRefresh.listen(_saveToken);
    
    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Background/terminated messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  
  Future<void> _saveToken(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
  
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      await _showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? 'HelaService',
        body: notification.body ?? '',
        payload: message.data['jobId'],
      );
    }
  }
  
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'helaservice_channel',
      'HelaService Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(id, title, body, details, payload: payload);
  }
  
  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Get FCM token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    await _messaging.deleteToken();
  }
}

// Background message handler (must be top-level)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message
}
