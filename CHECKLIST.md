# HelaService Production Readiness Checklist

Sprint 6: Final QA & Deployment

## CODE QUALITY ✅

- [ ] `flutter analyze` passes with 0 issues
- [ ] All code formatted with `dart format`
- [ ] No TODOs left in production code
- [ ] No debug print statements in release builds
- [ ] All imports use package: style (no relative imports)
- [ ] No unused imports or variables

## TESTING ✅

- [ ] Unit tests: 60%+ coverage
- [ ] Widget tests: 15%+ coverage
- [ ] Integration tests: 5%+ coverage
- [ ] All tests passing
- [ ] Tests run on CI/CD pipeline
- [ ] Manual QA completed on 5+ devices
- [ ] Beta testing with 20+ users completed

## BUILD VERIFICATION ✅

- [ ] `flutter build apk --release` successful
- [ ] `flutter build appbundle --release` successful
- [ ] `flutter build ios --release` successful (macOS)
- [ ] Build size < 50MB
- [ ] ProGuard/R8 enabled for Android
- [ ] iOS bitcode disabled (for Flutter)

## FIREBASE DEPLOYMENT ✅

- [ ] Firestore security rules deployed
- [ ] Firestore indexes deployed
- [ ] Storage security rules deployed
- [ ] Cloud Functions deployed and tested
- [ ] App Check enabled (production)
- [ ] Firebase Analytics configured
- [ ] Crashlytics configured
- [ ] Performance Monitoring enabled

## SECURITY ✅

- [ ] Firebase App Check enabled
- [ ] Input validation on all forms
- [ ] NIC validation implemented
- [ ] Phone validation implemented
- [ ] Password validation implemented
- [ ] XSS sanitization on user input
- [ ] Rate limiting on Cloud Functions
- [ ] Security rules tested
- [ ] PDPA compliance verified
- [ ] Security audit passed

## PERFORMANCE ✅

- [ ] App cold start < 3 seconds
- [ ] Screen transitions < 300ms
- [ ] List scrolling 60fps
- [ ] Cached network images implemented
- [ ] Pagination on all list queries
- [ ] Memory usage < 150MB
- [ ] Image cache sizes optimized
- [ ] No memory leaks detected

## MONITORING & ANALYTICS ✅

- [ ] Crashlytics reporting enabled
- [ ] Analytics events implemented
- [ ] Performance monitoring active
- [ ] BLoC observer for state tracking
- [ ] User feedback system working
- [ ] Admin dashboard accessible
- [ ] Debug dashboard removed (release)

## STORE PREPARATION ✅

### Android (Play Store)
- [ ] App icon (512x512 + all densities)
- [ ] Feature graphic (1024x500)
- [ ] Screenshots (phone: 1080x1920)
- [ ] Screenshots (tablet: optional)
- [ ] Short description (80 chars)
- [ ] Full description
- [ ] Privacy policy URL
- [ ] Terms of service URL

### iOS (App Store)
- [ ] App icon (1024x1024)
- [ ] Screenshots (required sizes)
- [ ] App preview video (optional)
- [ ] App description
- [ ] Keywords
- [ ] Privacy policy URL
- [ ] Support URL

### Content
- [ ] App description (English)
- [ ] App description (Sinhala)
- [ ] Privacy policy document
- [ ] Terms of service document
- [ ] Support contact information

## DOCUMENTATION ✅

- [ ] README.md updated
- [ ] ARCHITECTURE.md complete
- [ ] API documentation
- [ ] User guide (EN + SI)
- [ ] Admin guide
- [ ] Deployment guide
- [ ] Troubleshooting guide
- [ ] Store preparation guide

## PRE-LAUNCH ✅

- [ ] Production environment configured
- [ ] SSL certificates valid
- [ ] Domain names configured
- [ ] Email service working
- [ ] SMS service configured
- [ ] Payment gateway tested
- [ ] Push notifications working
- [ ] Location services tested

## POST-LAUNCH ✅

- [ ] Monitor Crashlytics for crashes
- [ ] Monitor Analytics for engagement
- [ ] Monitor Performance for bottlenecks
- [ ] Respond to user feedback
- [ ] Track support tickets
- [ ] Plan first update

## SIGN-OFF

- [ ] Product Manager approval
- [ ] Tech Lead approval
- [ ] QA Lead approval
- [ ] Security review passed
- [ ] Legal review passed (privacy/terms)

---

## Deployment Command

```bash
# Run complete deployment
./scripts/deploy.sh production

# Or step by step:
flutter analyze
flutter test
./scripts/qa_check.sh
firebase deploy
flutter build appbundle --release
```

## Release Version

- Version: 1.0.0
- Build Number: [AUTO]
- Git Tag: v1.0.0
- Date: 2026-04-09

## Emergency Contacts

- DevOps: devops@helaservice.lk
- On-call: +94 11 234 5678
- Slack: #helaservice-deployments
