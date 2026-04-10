# HelaService Monitoring & Analytics

This document describes the monitoring and analytics infrastructure for the HelaService app.

## Overview

The monitoring system consists of:
- **Firebase Analytics** - User behavior and business metrics
- **Firebase Crashlytics** - Error tracking and crash reporting
- **Performance Monitoring** - Custom performance tracking
- **Debug Dashboard** - Development debugging tools

## Firebase Analytics Events

### User Lifecycle Events

| Event | Description | Parameters |
|-------|-------------|------------|
| `sign_up` | New user registration | `method`, `userType` |
| `login` | User login | `method`, `userType` |
| `logout` | User logout | - |

### Booking Events

| Event | Description | Parameters |
|-------|-------------|------------|
| `booking_created` | New booking placed | `booking_id`, `service_type`, `estimated_price`, `zone`, `scheduled_date` |
| `booking_cancelled` | Booking cancelled | `booking_id`, `reason`, `hours_before_service` |
| `job_completed` | Service completed | `job_id`, `worker_id`, `service_type`, `duration_minutes`, `final_price`, `worker_rating` |

### Payment Events

| Event | Description | Parameters |
|-------|-------------|------------|
| `payment_success` | Payment completed | `payment_id`, `booking_id`, `amount`, `method`, `currency`, `coupon_code` |
| `payment_failed` | Payment failed | `booking_id`, `amount`, `reason`, `error_code` |
| `purchase` | E-commerce purchase | `transaction_id`, `value`, `currency`, `items` |
| `add_to_cart` | Service added | `items` |

### Worker Events

| Event | Description | Parameters |
|-------|-------------|------------|
| `worker_status_changed` | Online/offline toggle | `worker_id`, `is_online`, `zone` |
| `job_offer_received` | New job offer | `worker_id`, `job_id`, `service_type`, `estimated_earnings` |
| `job_offer_response` | Accept/reject job | `worker_id`, `job_id`, `accepted`, `response_time_seconds` |
| `worker_registration` | New worker signup | `worker_id`, `services_count`, `services`, `onboarding_time_minutes` |
| `worker_verification` | Verification status | `worker_id`, `status`, `rejection_reason` |

### User Actions

| Event | Description | Parameters |
|-------|-------------|------------|
| `service_selected` | Service chosen | `service_type`, `source` |
| `search` | Search performed | `query`, `results_count` |
| `chat_message_sent` | Message sent | `chat_id`, `sender_type`, `has_attachment` |
| `notification_received` | Push received | `type`, `user_id`, `opened` |

### Error Events

| Event | Description | Parameters |
|-------|-------------|------------|
| `app_error` | General app error | `error_message`, `context`, `is_fatal` |
| `api_error` | API failure | `endpoint`, `status_code`, `error_message` |

### Performance Events

| Event | Description | Parameters |
|-------|-------------|------------|
| `app_startup` | App launch time | `startup_time_ms`, `from_background` |
| `screen_load_time` | Screen rendering | `screen_name`, `load_time_ms` |

## User Properties

User properties are set for segmentation:
- `user_type` - 'customer' or 'worker'
- `zone` - Geographic zone (e.g., 'colombo', 'gampaha')
- `membership_level` - Premium tier
- `total_bookings` - Cumulative bookings

## Crash Reporting

Crashlytics captures:
- Fatal crashes with full stack traces
- Non-fatal errors from BLoCs
- Custom keys for context (user ID, current screen)

### Custom Keys Set
- `user_id` - Current user identifier
- `current_screen` - Active screen
- `booking_id` - Active booking (if applicable)

## BLoC Observer

The `AnalyticsBlocObserver` tracks:
- BLoC creation/destruction (debug only)
- State changes (debug only)
- Errors (analytics + crashlytics)

## Performance Monitoring

Custom performance tracking via `PerformanceMonitoring`:

```dart
// Measure operation duration
final duration = await PerformanceMonitoring().measure(
  'operation_name',
  () async => await someAsyncOperation(),
);

// Manual timing
PerformanceMonitoring().startTimer('task');
// ... do work
final ms = PerformanceMonitoring().endTimer('task');
```

## Debug Dashboard

Available in debug builds only, accessible via draggable sheet:

### Features
- **Analytics Testing** - Trigger test events
- **Performance Testing** - Measure operations
- **Service Testing** - Toggle location tracking, send test notifications

### Usage
```dart
// Wrap your app with debug overlay
DebugDashboardOverlay(
  child: MyApp(),
)
```

## Integration Guide

### Adding Analytics to a New BLoC

```dart
class MyBloc extends Bloc<MyEvent, MyState> {
  final AnalyticsService _analytics;

  MyBloc({AnalyticsService? analytics})
      : _analytics = analytics ?? AnalyticsService(),
        super(MyInitial()) {
    // ...
  }
}
```

### Register in Injection Container

```dart
sl.registerFactory(() => MyBloc(
  analytics: sl(),
));
```

### Tracking Custom Events

```dart
await AnalyticsService().logEvent(
  name: 'custom_event',
  parameters: {
    'param1': value1,
    'param2': value2,
  },
);
```

## Firebase Console Setup

### Analytics Dashboard
1. Go to Firebase Console → Analytics → Dashboard
2. Key metrics:
   - Active users
   - Revenue (from payment events)
   - User retention
   - Event counts

### Custom Reports
Create custom reports for:
- Booking conversion funnel
- Worker acceptance rate
- Payment success rate by method
- Service type popularity

### Crashlytics Dashboard
1. Go to Firebase Console → Crashlytics
2. Monitor:
   - Crash-free users percentage
   - Top crashes
   - Recent errors

## Privacy & Compliance

- No PII in analytics events (NIC masked)
- Opt-out supported via `setAnalyticsCollectionEnabled(false)`
- Data retention: 14 months (Firebase default)

## Debugging

Enable verbose logging:
```dart
// In main.dart before Firebase init
FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
```

View debug events:
```bash
# iOS
xcrun simctl spawn booted log stream --level debug --predicate 'eventMessage contains "FirebaseAnalytics"'

# Android
adb shell setprop log.tag.FA VERBOSE
adb logcat -s FA FA-SVC
```
