# Troubleshooting Guide

Common issues and solutions for HelaService.

## Build Issues

### Flutter Build Fails

**Problem:** `flutter build` fails with dependency errors
```
Error: Could not resolve all dependencies
```

**Solution:**
```bash
flutter clean
flutter pub get
cd ios && pod install --repo-update && cd ..  # macOS only
```

### Android Build Issues

**Problem:** Keystore not found
```
Error: Keystore file not found
```

**Solution:**
1. Ensure `android/key.properties` exists
2. Verify keystore file path is correct
3. Check keystore password

### iOS Build Issues

**Problem:** Code signing error
```
Error: Code signing failed
```

**Solution:**
1. Open Xcode
2. Select correct team in Signing & Capabilities
3. Ensure certificates are valid

## Firebase Issues

### Firestore Permission Denied

**Problem:**
```
FirebaseException: [cloud_firestore/permission-denied]
```

**Solution:**
1. Check `firestore.rules` are deployed
2. Verify user is authenticated
3. Check App Check token is valid

### Cloud Functions Timeout

**Problem:** Function execution timeout

**Solution:**
1. Increase timeout in function config
2. Optimize function code
3. Use background functions for long tasks

### App Check Failed

**Problem:**
```
Firebase App Check token is invalid
```

**Solution:**
1. Check App Check is initialized in main.dart
2. Verify debug token for development
3. For production, ensure Play Integrity/App Attest configured

## Runtime Issues

### App Crashes on Startup

**Problem:** White screen or crash on launch

**Solution:**
1. Check Crashlytics for stack trace
2. Verify Firebase initialization
3. Check for missing environment variables

### Location Not Working

**Problem:** Cannot get user location

**Solution:**
1. Check location permissions in AndroidManifest/iOS Info.plist
2. Verify GPS is enabled on device
3. Check geolocator configuration

### Push Notifications Not Received

**Problem:** No push notifications

**Solution:**
1. Check FCM token is registered
2. Verify notification permissions
3. Check Firebase Cloud Messaging is enabled
4. Test with Firebase Console

## Payment Issues

### PayHere Integration Fails

**Problem:** Payment not processing

**Solution:**
1. Verify PayHere merchant ID
2. Check MD5 signature calculation
3. Ensure return URLs are correct
4. Test with sandbox first

## Performance Issues

### Slow App Startup

**Problem:** App takes > 3 seconds to start

**Solution:**
1. Reduce initial dependencies
2. Use lazy loading for heavy widgets
3. Optimize images
4. Check for blocking operations in main()

### List Scrolling is Janky

**Problem:** List scrolling not smooth

**Solution:**
1. Use ListView.builder
2. Implement pagination
3. Optimize image loading
4. Use const constructors

### High Memory Usage

**Problem:** App uses > 150MB RAM

**Solution:**
1. Reduce image cache sizes
2. Dispose controllers properly
3. Check for memory leaks
4. Use CachedNetworkImage with memCacheWidth

## Authentication Issues

### OTP Not Received

**Problem:** SMS OTP not delivered

**Solution:**
1. Check phone number format (07XXXXXXXX)
2. Verify SMS gateway is working
3. Check rate limits (max 3 per minute)
4. Try resend after 60 seconds

### Cannot Login

**Problem:** Login fails

**Solution:**
1. Check internet connection
2. Verify phone number is correct
3. Check OTP is entered correctly
4. Clear app data and retry

## Data Issues

### Jobs Not Loading

**Problem:** Job list empty or fails to load

**Solution:**
1. Check Firestore connection
2. Verify user permissions
3. Check query filters
4. Review Firestore indexes

### Images Not Loading

**Problem:** Profile/service images not showing

**Solution:**
1. Check image URLs are valid
2. Verify storage permissions
3. Check network connectivity
4. Clear image cache

## Contact Support

If issues persist:

- Email: support@helaservice.lk
- Phone: +94 11 234 5678
- Slack: #helaservice-support

Include:
- App version
- Device model
- OS version
- Error screenshots
- Steps to reproduce
