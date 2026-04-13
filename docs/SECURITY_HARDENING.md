# Sprint 5: Security Hardening

Comprehensive security hardening for the HelaService platform.

## Table of Contents

1. [Firebase App Check](#firebase-app-check)
2. [Input Validation](#input-validation)
3. [Rate Limiting](#rate-limiting)
4. [Data Cleanup & Retention](#data-cleanup--retention)
5. [Security Monitoring](#security-monitoring)

---

## Firebase App Check

### Overview
Firebase App Check protects your backend resources from abuse by ensuring that only your authentic app can access your Firebase services.

### Implementation

**Android:**
- Production: Uses Google Play Integrity API
- Development: Uses Debug provider

**iOS:**
- Production: Uses DeviceCheck/App Attest
- Development: Uses Debug provider

### Configuration

```dart
// lib/main.dart
Future<void> _initializeAppCheck() async {
  final appCheck = FirebaseAppCheck.instance;
  
  if (kDebugMode) {
    await appCheck.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  } else {
    await appCheck.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
    );
  }
}
```

### Enforcing App Check

Update Firestore Security Rules to require App Check:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Require App Check for all access
    match /{document=**} {
      allow read, write: if request.app != null 
        && request.app.appId == 'your.app.id';
    }
  }
}
```

---

## Input Validation

### InputValidators Class

All user input must be validated using `InputValidators`:

```dart
import 'core/utils/input_validators.dart';

// NIC validation
String? nicError = InputValidators.validateNIC('853202937V');

// Phone validation  
String? phoneError = InputValidators.validatePhone('0771234567');

// Name validation
String? nameError = InputValidators.validateName('John Doe');

// Email validation
String? emailError = InputValidators.validateEmail('user@example.com');
```

### Validation Categories

| Validator | Purpose | Security Protection |
|-----------|---------|---------------------|
| `validateNIC()` | Sri Lankan NIC format | Format injection |
| `validatePhone()` | SL mobile numbers | Invalid data |
| `validateName()` | User full names | XSS, injection |
| `validateEmail()` | Email format | XSS, injection |
| `validateAddress()` | Address text | XSS, injection |
| `validateDescription()` | Service descriptions | XSS, injection |
| `validateFeedback()` | User feedback | XSS, injection |
| `validatePassword()` | Password strength | Weak passwords |
| `validateAmount()` | Payment amounts | Financial manipulation |
| `validateOTP()` | OTP codes | Brute force |

### Sanitization

```dart
// Sanitize user input for display
String safeText = InputValidators.sanitizeText(userInput);

// Remove dangerous characters
String displayText = InputValidators.sanitizeForDisplay(userInput);
```

### Extension Methods

```dart
// Quick validation with extension methods
String? error = userInput.asNIC;
String? error = userInput.asPhone;
String? error = userInput.asEmail(required: true);

// Quick sanitization
String safe = userInput.sanitized ?? '';
```

---

## Rate Limiting

### Rate Limits

| Operation | Max Requests | Window |
|-----------|--------------|--------|
| OTP Requests | 3 | 1 minute |
| Job Creation | 10 | 1 minute |
| Search | 30 | 1 minute |
| Feedback | 5 | 1 hour |
| General API | 100 | 1 minute |

### Using Rate-Limited Functions

```typescript
// functions/src/yourFunction.ts
import { withRateLimit } from './rateLimit';

export const yourFunction = withRateLimit(
  'operationType',
  async (data, context) => {
    // Your function logic here
    return { success: true };
  }
);
```

### Custom Rate Limits

```typescript
export const customFunction = withRateLimit(
  'custom',
  async (data, context) => {
    // Function logic
  },
  {
    maxRequests: 50,
    windowMs: 60000, // 1 minute
    keyPrefix: 'custom'
  }
);
```

### Rate Limit Response

When rate limit is exceeded, the function returns:

```json
{
  "error": {
    "code": "resource-exhausted",
    "message": "Rate limit exceeded. Try again in 45 seconds.",
    "details": {
      "retryAfter": 45,
      "resetTime": 1234567890000
    }
  }
}
```

---

## Data Cleanup & Retention

### Scheduled Cleanup Jobs

| Job | Schedule | Purpose |
|-----|----------|---------|
| `cleanupRateLimitsDaily` | Daily 2:00 AM | Remove old rate limit docs |
| `cleanupExpiredOTPs` | Hourly | Delete expired OTP codes |
| `cleanupOldJobOffers` | Daily 3:00 AM | Remove old job offers |
| `cleanupOldMessages` | Daily 4:00 AM | PDPA compliance (30-day retention) |
| `archiveOldJobs` | Weekly Sun 5:00 AM | Archive 90+ day old jobs |

### PDPA Compliance

The app enforces PDPA data retention policies:

- **Chat Messages:** 30 days
- **Job Requests:** 90 days (then archived)
- **Rate Limits:** 24 hours
- **OTP Codes:** Until expired + 1 hour
- **Audit Logs:** 7 years (immutable)

### Firestore TTL Policy

Enable Cloud Firestore TTL for automatic cleanup:

```bash
# Set TTL policy for messages collection
gcloud firestore fields composite indexes composite-config \
  --collection-group=messages \
  --field-config field-path=createdAt,order=ascending,ttl=true
```

---

## Security Monitoring

### Suspicious Activity Detection

The `detectSuspiciousActivity` function runs every 15 minutes and alerts on:

- Multiple failed OTP attempts (5+ failures in 15 minutes)
- High job creation rates (20+ jobs in 1 minute)
- Unusual API usage patterns

### Security Alerts Collection

Suspicious activities are logged to `security_alerts`:

```javascript
{
  type: 'multiple_failed_otp',
  phoneNumber: '+94771234567',
  attempts: 7,
  detectedAt: Timestamp,
  severity: 'high'
}
```

### Integration with Crashlytics

Security events are reported to Crashlytics:

```dart
// App Check failure
FirebaseCrashlytics.instance.recordError(
  error,
  StackTrace.current,
  reason: 'App Check initialization failed',
);
```

---

## Security Checklist

### Development

- [ ] All user inputs validated with `InputValidators`
- [ ] App Check configured in `main.dart`
- [ ] Rate limiting applied to sensitive Cloud Functions
- [ ] Data sanitization before display
- [ ] Strong password requirements enforced

### Deployment

- [ ] App Check enforced in Firestore Security Rules
- [ ] Scheduled cleanup functions deployed
- [ ] Rate limit collection indexes created
- [ ] TTL policies configured for message cleanup
- [ ] Security alerts monitored

### Production

- [ ] Debug App Check providers disabled
- [ ] Play Integrity/App Attest providers active
- [ ] Suspicious activity alerts configured
- [ ] Security audit logs regularly reviewed
- [ ] Penetration testing completed

---

## Emergency Procedures

### Rate Limit Bypass (Emergency)

If legitimate users are being rate-limited:

```typescript
// Temporarily increase limits
const emergencyConfig = {
  maxRequests: 1000,
  windowMs: 60000,
  keyPrefix: 'emergency'
};
```

### App Check Bypass (Emergency)

In Firestore Rules, temporarily allow without App Check:

```javascript
// Emergency bypass (remove after issue resolved)
match /{document=**} {
  allow read, write: if request.auth != null;
}
```

### Security Incident Response

1. **Immediate:** Enable emergency rate limits
2. **Assessment:** Review `security_alerts` collection
3. **Containment:** Block suspicious IPs/users
4. **Recovery:** Restore normal operation
5. **Post-Incident:** Update security measures

---

## References

- [Firebase App Check Documentation](https://firebase.google.com/docs/app-check)
- [Cloud Functions Rate Limiting](https://cloud.google.com/functions/docs/concepts/exec#concurrency)
- [OWASP Input Validation Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html)
- [PDPA Sri Lanka Guidelines](https://www.privacy.gov.lk/)
