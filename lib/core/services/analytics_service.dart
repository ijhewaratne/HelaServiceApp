import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive analytics service for HelaService
/// Tracks user behavior, business metrics, and performance
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  bool _initialized = false;

  /// Initialize analytics
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _analytics = FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);
      _initialized = true;
      debugPrint('✓ Firebase Analytics initialized');
    } catch (e) {
      debugPrint('✗ Analytics initialization failed: $e');
    }
  }

  // ==================== USER LIFECYCLE ====================

  /// Log user signup
  Future<void> logSignUp({
    required String method,
    String? userType,
  }) async {
    await _logEvent(
      name: 'sign_up',
      parameters: {
        'method': method,
        if (userType != null) 'user_type': userType,
      },
    );
  }

  /// Log login
  Future<void> logLogin({
    required String method,
    String? userType,
  }) async {
    await _logEvent(
      name: 'login',
      parameters: {
        'method': method,
        if (userType != null) 'user_type': userType,
      },
    );
  }

  /// Log logout
  Future<void> logLogout() async {
    await _logEvent(name: 'logout');
  }

  /// Set user properties for segmentation
  Future<void> setUserProperties({
    required String userId,
    String? userType,
    String? zone,
    String? membershipLevel,
    int? totalBookings,
  }) async {
    if (!_initialized) return;

    try {
      await _analytics!.setUserId(id: userId);
      
      if (userType != null) {
        await _analytics!.setUserProperty(
          name: 'user_type',
          value: userType,
        );
      }
      
      if (zone != null) {
        await _analytics!.setUserProperty(
          name: 'zone',
          value: zone,
        );
      }
      
      if (membershipLevel != null) {
        await _analytics!.setUserProperty(
          name: 'membership_level',
          value: membershipLevel,
        );
      }
      
      if (totalBookings != null) {
        await _analytics!.setUserProperty(
          name: 'total_bookings',
          value: totalBookings.toString(),
        );
      }
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  // ==================== SCREEN VIEWS ====================

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_initialized) return;

    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      debugPrint('Screen view error: $e');
    }
  }

  // ==================== BOOKING EVENTS ====================

  /// Log booking created
  Future<void> logBookingCreated({
    required String bookingId,
    required String serviceType,
    required double estimatedPrice,
    String? zone,
    DateTime? scheduledDate,
  }) async {
    await _logEvent(
      name: 'booking_created',
      parameters: {
        'booking_id': bookingId,
        'service_type': serviceType,
        'estimated_price': estimatedPrice,
        if (zone != null) 'zone': zone,
        if (scheduledDate != null)
          'scheduled_date': scheduledDate.toIso8601String(),
      },
    );
  }

  /// Log booking cancelled
  Future<void> logBookingCancelled({
    required String bookingId,
    String? reason,
    int? hoursBeforeService,
  }) async {
    await _logEvent(
      name: 'booking_cancelled',
      parameters: {
        'booking_id': bookingId,
        if (reason != null) 'reason': reason,
        if (hoursBeforeService != null)
          'hours_before_service': hoursBeforeService,
      },
    );
  }

  /// Log job completed
  Future<void> logJobCompleted({
    required String jobId,
    required String workerId,
    required String serviceType,
    required int durationMinutes,
    required double finalPrice,
    double? workerRating,
  }) async {
    await _logEvent(
      name: 'job_completed',
      parameters: {
        'job_id': jobId,
        'worker_id': workerId,
        'service_type': serviceType,
        'duration_minutes': durationMinutes,
        'final_price': finalPrice,
        if (workerRating != null) 'worker_rating': workerRating,
      },
    );
  }

  /// Log payment success
  Future<void> logPaymentSuccess({
    required String paymentId,
    required String bookingId,
    required double amount,
    required String method,
    String? couponCode,
  }) async {
    await _logEvent(
      name: 'payment_success',
      parameters: {
        'payment_id': paymentId,
        'booking_id': bookingId,
        'amount': amount,
        'method': method,
        'currency': 'LKR',
        if (couponCode != null) 'coupon_code': couponCode,
      },
    );
  }

  /// Log payment failure
  Future<void> logPaymentFailed({
    required String bookingId,
    required double amount,
    required String reason,
    String? errorCode,
  }) async {
    await _logEvent(
      name: 'payment_failed',
      parameters: {
        'booking_id': bookingId,
        'amount': amount,
        'reason': reason,
        if (errorCode != null) 'error_code': errorCode,
      },
    );
  }

  // ==================== WORKER EVENTS ====================

  /// Log worker online status change
  Future<void> logWorkerOnline({
    required String workerId,
    required bool isOnline,
    String? zone,
  }) async {
    await _logEvent(
      name: 'worker_status_changed',
      parameters: {
        'worker_id': workerId,
        'is_online': isOnline,
        if (zone != null) 'zone': zone,
      },
    );
  }

  /// Log job offer received
  Future<void> logJobOfferReceived({
    required String workerId,
    required String jobId,
    required String serviceType,
    required double estimatedEarnings,
  }) async {
    await _logEvent(
      name: 'job_offer_received',
      parameters: {
        'worker_id': workerId,
        'job_id': jobId,
        'service_type': serviceType,
        'estimated_earnings': estimatedEarnings,
      },
    );
  }

  /// Log job offer response
  Future<void> logJobOfferResponse({
    required String workerId,
    required String jobId,
    required bool accepted,
    int? responseTimeSeconds,
  }) async {
    await _logEvent(
      name: 'job_offer_response',
      parameters: {
        'worker_id': workerId,
        'job_id': jobId,
        'accepted': accepted,
        if (responseTimeSeconds != null)
          'response_time_seconds': responseTimeSeconds,
      },
    );
  }

  /// Log worker registration
  Future<void> logWorkerRegistration({
    required String workerId,
    required String nic,
    required List<String> services,
    int? onboardingTimeMinutes,
  }) async {
    await _logEvent(
      name: 'worker_registration',
      parameters: {
        'worker_id': workerId,
        'nic_last_4': nic.substring(nic.length - 4),
        'services_count': services.length,
        'services': services.join(','),
        if (onboardingTimeMinutes != null)
          'onboarding_time_minutes': onboardingTimeMinutes,
      },
    );
  }

  /// Log worker verification
  Future<void> logWorkerVerification({
    required String workerId,
    required String status, // 'approved', 'rejected', 'pending'
    String? rejectionReason,
  }) async {
    await _logEvent(
      name: 'worker_verification',
      parameters: {
        'worker_id': workerId,
        'status': status,
        if (rejectionReason != null) 'rejection_reason': rejectionReason,
      },
    );
  }

  // ==================== USER ACTIONS ====================

  /// Log service selection
  Future<void> logServiceSelected({
    required String serviceType,
    String? source, // 'home', 'search', 'recommendation'
  }) async {
    await _logEvent(
      name: 'service_selected',
      parameters: {
        'service_type': serviceType,
        if (source != null) 'source': source,
      },
    );
  }

  /// Log search
  Future<void> logSearch({
    required String query,
    int? resultsCount,
  }) async {
    await _logEvent(
      name: 'search',
      parameters: {
        'query': query,
        if (resultsCount != null) 'results_count': resultsCount,
      },
    );
  }

  /// Log chat message
  Future<void> logChatMessage({
    required String chatId,
    required String senderType, // 'customer' or 'worker'
    required bool hasAttachment,
  }) async {
    await _logEvent(
      name: 'chat_message_sent',
      parameters: {
        'chat_id': chatId,
        'sender_type': senderType,
        'has_attachment': hasAttachment,
      },
    );
  }

  /// Log notification received
  Future<void> logNotificationReceived({
    required String type,
    required String userId,
    bool? opened,
  }) async {
    await _logEvent(
      name: 'notification_received',
      parameters: {
        'type': type,
        'user_id': userId,
        if (opened != null) 'opened': opened,
      },
    );
  }

  // ==================== ERROR TRACKING ====================

  /// Log error
  Future<void> logError({
    required String error,
    String? context,
    String? stackTrace,
    bool? isFatal,
  }) async {
    await _logEvent(
      name: 'app_error',
      parameters: {
        'error_message': error,
        if (context != null) 'context': context,
        if (isFatal != null) 'is_fatal': isFatal,
      },
    );
  }

  /// Log API error
  Future<void> logApiError({
    required String endpoint,
    required int statusCode,
    String? errorMessage,
  }) async {
    await _logEvent(
      name: 'api_error',
      parameters: {
        'endpoint': endpoint,
        'status_code': statusCode,
        if (errorMessage != null) 'error_message': errorMessage,
      },
    );
  }

  // ==================== PERFORMANCE ====================

  /// Log app startup time
  Future<void> logAppStartup({
    required int startupTimeMs,
    bool? fromBackground,
  }) async {
    await _logEvent(
      name: 'app_startup',
      parameters: {
        'startup_time_ms': startupTimeMs,
        if (fromBackground != null) 'from_background': fromBackground,
      },
    );
  }

  /// Log screen load time
  Future<void> logScreenLoadTime({
    required String screenName,
    required int loadTimeMs,
  }) async {
    await _logEvent(
      name: 'screen_load_time',
      parameters: {
        'screen_name': screenName,
        'load_time_ms': loadTimeMs,
      },
    );
  }

  // ==================== E-COMMERCE ====================

  /// Log add to cart (service selection)
  Future<void> logAddToCart({
    required String serviceType,
    required double price,
  }) async {
    if (!_initialized) return;

    try {
      await _analytics!.logAddToCart(
        items: [
          AnalyticsEventItem(
            itemName: serviceType,
            itemCategory: 'home_services',
            price: price,
            currency: 'LKR',
          ),
        ],
        currency: 'LKR',
        value: price,
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Log purchase (booking completion)
  Future<void> logPurchase({
    required String bookingId,
    required double value,
    required String serviceType,
    String? coupon,
  }) async {
    if (!_initialized) return;

    try {
      await _analytics!.logPurchase(
        transactionId: bookingId,
        value: value,
        currency: 'LKR',
        coupon: coupon,
        items: [
          AnalyticsEventItem(
            itemName: serviceType,
            itemCategory: 'home_services',
            price: value,
            currency: 'LKR',
          ),
        ],
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  Future<void> _logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_initialized) {
      debugPrint('Analytics: $name, params: $parameters');
      return;
    }

    try {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }
}
