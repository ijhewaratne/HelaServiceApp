# Deployment Guide

Sprint 6: Final QA & Deployment

## Pre-Deployment Checklist

### Code Quality
- [ ] `flutter analyze` - 0 issues
- [ ] `flutter test` - 80%+ coverage, all tests pass
- [ ] `flutter build apk` - successful
- [ ] `flutter build appbundle` - successful
- [ ] `flutter build ios` - successful (if Mac available)

### Firebase
- [ ] Firestore rules deployed
- [ ] Storage rules deployed
- [ ] Cloud Functions deployed
- [ ] App Check enabled
- [ ] Security rules tested

### Documentation
- [ ] API documentation complete
- [ ] User guide created
- [ ] Admin guide created
- [ ] Troubleshooting guide created

### Store Preparation
- [ ] App icon (all sizes)
- [ ] Feature graphics
- [ ] Screenshots (phone + tablet)
- [ ] App description (EN + SI)
- [ ] Privacy policy
- [ ] Terms of service

## Deployment Commands

### Deploy to Firebase

```bash
# Deploy all Firebase resources
firebase deploy

# Or deploy specific resources
firebase deploy --only firestore:rules
firebase deploy --only storage
firebase deploy --only functions
firebase deploy --only firestore:indexes

# Deploy with token (CI/CD)
firebase deploy --token "$FIREBASE_TOKEN"
```

### Build Release

```bash
# Clean build
flutter clean
flutter pub get

# Build Android App Bundle (for Play Store)
flutter build appbundle --release

# Build Android APK (for testing)
flutter build apk --release

# Build iOS (macOS only)
flutter build ios --release
```

### Run QA Checks

```bash
# Run all QA checks
./scripts/qa_check.sh

# Run deployment script
./scripts/deploy.sh production
```

## Hero Level Checklist

### Performance
- [ ] App cold start < 3 seconds
- [ ] Screen transitions < 300ms
- [ ] List scrolling 60fps
- [ ] Image loading optimized
- [ ] Memory usage < 150MB

### Security
- [ ] Firebase App Check enabled
- [ ] Input validation on all forms
- [ ] Rate limiting on Cloud Functions
- [ ] PDPA compliance verified
- [ ] Security audit passed

### Testing
- [ ] Unit test coverage 60%
- [ ] Widget test coverage 15%
- [ ] Integration test coverage 5%
- [ ] Manual QA on 5+ devices
- [ ] Beta testing with 20+ users

### Monitoring
- [ ] Crashlytics reporting
- [ ] Analytics events tracking
- [ ] Performance monitoring
- [ ] User feedback system
- [ ] Admin dashboard operational

### Documentation
- [ ] Complete API docs
- [ ] User guide (EN + SI)
- [ ] Admin guide
- [ ] Deployment guide
- [ ] Troubleshooting guide

## Environment Setup

### Development
```bash
flutter run --debug --dart-define=ENVIRONMENT=development
```

### Staging
```bash
flutter run --profile --dart-define=ENVIRONMENT=staging
```

### Production
```bash
flutter run --release --dart-define=ENVIRONMENT=production
```

## Troubleshooting

### Build Issues

**Problem:** Build fails with dependency errors
**Solution:**
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

**Problem:** Android build fails with keystore error
**Solution:**
Ensure `android/key.properties` exists and points to valid keystore.

### Firebase Issues

**Problem:** Firestore rules deployment fails
**Solution:**
```bash
firebase login
firebase use helaservice-prod
firebase deploy --only firestore:rules
```

**Problem:** Cloud Functions deployment fails
**Solution:**
```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

## Rollback Procedure

If critical issues are found after deployment:

1. **Immediate:** Disable problematic feature via remote config
2. **Short-term:** Deploy hotfix using previous git tag
3. **Long-term:** Full rollback to previous version

```bash
# Rollback to previous version
git checkout v1.0.0
./scripts/deploy.sh production
```

## Post-Deployment Monitoring

Monitor these metrics after deployment:

1. **Crashlytics:** Check for new crashes
2. **Analytics:** Monitor user engagement
3. **Performance:** Track app startup time
4. **Feedback:** Review user feedback
5. **Support:** Watch for increased tickets

## Contact

For deployment support:
- DevOps: devops@helaservice.lk
- On-call: +94 11 234 5678
