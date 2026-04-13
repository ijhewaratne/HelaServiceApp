# HelaService - Launch Readiness Checklist

**Target Launch Date:** TBD  
**Current Status:** In Development  
**Last Updated:** April 2026

---

## Executive Summary

| Category | Status | Progress | Blockers |
|----------|--------|----------|----------|
| Security | 🟡 In Progress | 70% | API keys regeneration needed |
| Testing | 🟡 In Progress | 45% | BLoC testing, integration tests |
| Localization | 🟢 Complete | 100% | None |
| Features | 🟡 In Progress | 75% | PayHere integration, BLoC fixes |
| Performance | 🟡 In Progress | 60% | Build optimization needed |
| DevOps | 🟢 Complete | 95% | Secrets configuration |
| Compliance | 🟡 In Progress | 65% | Privacy policy, ToS |
| Beta Testing | 🔴 Not Started | 0% | Waiting for build stabilization |

**Overall Readiness: 65%**

---

## 1. Security Checklist

### 1.1 Authentication & Authorization
- [x] Firebase Authentication with phone OTP
- [x] Firestore security rules implemented
- [x] Storage security rules configured
- [x] Role-based access control (customer/worker/admin)
- [ ] **CRITICAL**: Regenerate exposed Firebase API keys (in git history)
- [ ] **CRITICAL**: Rotate PayHere merchant credentials
- [ ] Enable Firebase App Check in production
- [ ] Implement certificate pinning for API calls

### 1.2 Data Protection
- [x] AES-256 encryption service implemented
- [x] Sensitive data encryption (NIC, addresses)
- [x] Environment variables for secrets (.env)
- [x] Input validation on all user inputs
- [ ] Implement SQL injection protection ( parameterized queries)
- [ ] Add request signing for critical endpoints

### 1.3 Network Security
- [x] HTTPS-only communication enforced
- [x] Firebase SSL/TLS encryption
- [ ] Implement API rate limiting on client
- [ ] Add network security config (Android)
- [ ] Configure ATS (App Transport Security) for iOS

### 1.4 Code Security
- [x] ProGuard/R8 obfuscation rules configured
- [ ] Remove debug logs from production builds
- [ ] Implement anti-tampering measures
- [ ] Security audit by third party (recommended)

### 1.5 Incident Response
- [x] Emergency service for incidents
- [x] Incident reporting UI
- [ ] Automated security alerts
- [ ] Incident response runbook

**Security Status: 70%** 🟡  
**Action Items:**
1. Regenerate all Firebase API keys immediately
2. Complete security audit before public beta
3. Implement certificate pinning

---

## 2. Testing Checklist

### 2.1 Unit Tests
- [x] Encryption service tests (21 tests passing)
- [x] Entity model tests
- [ ] Wallet repository tests
- [ ] Promo code validation tests
- [ ] Referral logic tests
- [ ] BLoC state management tests
- [ ] Use case tests

**Current Coverage: ~25%**  
**Target: 80%+**

### 2.2 Integration Tests
- [x] Test helpers with Firebase mocking
- [x] Worker onboarding flow test
- [ ] Authentication flow E2E test
- [ ] Booking creation flow E2E test
- [ ] Payment flow E2E test
- [ ] Real-time tracking E2E test

### 2.3 UI Tests
- [ ] Critical user journeys automated
- [ ] Accessibility testing
- [ ] Device compatibility testing (10+ devices)

### 2.4 Performance Tests
- [ ] App launch time < 3 seconds
- [ ] Scroll performance 60fps
- [ ] Memory usage < 150MB
- [ ] Battery consumption acceptable

### 2.5 Beta Testing
- [ ] Internal QA (5 users, 1 week)
- [ ] Closed beta (20 users, 2 weeks)
- [ ] Open beta (100 users, 1 month)

**Testing Status: 45%** 🟡  
**Action Items:**
1. Write comprehensive BLoC tests
2. Create E2E test suite for critical paths
3. Achieve 80% coverage before beta

---

## 3. Localization Checklist

### 3.1 Sinhala Support
- [x] 75+ Sinhala translations in app_si.arb
- [x] Unicode Sinhala script support
- [x] RTL text support (if needed)
- [x] Date/time localization
- [x] Number/currency formatting (LKR)

### 3.2 String Management
- [x] All UI strings externalized
- [x] No hardcoded strings in widgets
- [x] Context-aware translations
- [ ] Review translations with native speakers
- [ ] Add Tamil support (Phase 2)

### 3.3 Regional Settings
- [x] Sri Lanka timezone support (Asia/Colombo)
- [x] Local phone number formatting (+94)
- [x] Local address format support

**Localization Status: 100%** 🟢  
**Ready for launch** ✅

---

## 4. Feature Completeness

### 4.1 Authentication
- [x] Phone OTP login
- [x] User role selection
- [x] Onboarding flows
- [x] Profile management

### 4.2 Booking System
- [x] Service selection
- [x] Address management
- [x] Booking creation
- [x] Real-time worker tracking
- [x] Job dispatch algorithm
- [ ] **BLOCKER**: Worker acceptance flow needs BLoC fixes

### 4.3 Payment System
- [x] Wallet implementation
- [x] Transaction history
- [ ] **BLOCKER**: PayHere package unavailable (using stubs)
- [ ] Alternative: Direct PayHere web integration
- [ ] Refund processing

### 4.4 Wallet & Promo
- [x] Wallet domain layer
- [x] Top-up flow
- [x] Promo code validation
- [ ] **TODO**: Promo code UI integration

### 4.5 Referral System
- [x] Referral code generation
- [x] Cloud Functions for processing
- [x] Reward distribution
- [ ] **TODO**: Referral UI screens

### 4.6 Chat & Notifications
- [x] Push notification infrastructure
- [ ] In-app chat (partial - UI only)
- [ ] Real-time messaging

**Features Status: 75%** 🟡  
**Critical Blockers:**
1. PayHere payment integration
2. BLoC layer compilation errors

---

## 5. Performance Checklist

### 5.1 Launch Performance
- [ ] Cold start < 3 seconds
- [ ] Warm start < 1.5 seconds
- [ ] First contentful paint < 2 seconds

### 5.2 Runtime Performance
- [x] Image caching (cached_network_image)
- [x] List pagination
- [x] BLoC performance mixin
- [ ] Scroll performance 60fps
- [ ] Memory leak testing

### 5.3 Network Performance
- [x] Firestore query optimization
- [x] Pagination for large lists
- [ ] GraphQL/DataLoader (optional)
- [ ] Request batching

### 5.4 Build Optimization
- [ ] Split APK by ABI
- [ ] Code shrinking
- [ ] Resource shrinking
- [ ] App bundle size < 50MB

**Performance Status: 60%** 🟡  
**Action Items:**
1. Profile app startup time
2. Optimize BLoC rebuilds
3. Reduce bundle size

---

## 6. DevOps Checklist

### 6.1 CI/CD
- [x] GitHub Actions workflows
- [x] Staging deployment pipeline
- [x] Production deployment pipeline
- [x] Automated testing on PR
- [ ] **TODO**: Configure secrets in GitHub

### 6.2 Monitoring
- [x] UptimeRobot configuration
- [x] Cloud Monitoring alerts
- [x] Health check endpoints
- [x] Performance monitoring
- [ ] **TODO**: Configure alert channels (Slack, PagerDuty)

### 6.3 Backup & Recovery
- [x] Automated daily backups
- [x] 30-day retention policy
- [x] Manual backup/restore functions
- [ ] **TODO**: Test restore procedure

### 6.4 Environment Setup
- [x] Staging Firebase project
- [x] Production Firebase project
- [x] Environment-specific builds
- [ ] **TODO**: Production Firebase configuration

**DevOps Status: 95%** 🟢  
**Action Items:**
1. Add GitHub secrets for deployment
2. Test disaster recovery
3. Set up log aggregation

---

## 7. Compliance Checklist

### 7.1 PDPA Compliance (Sri Lanka)
- [x] Encryption for sensitive data (AES-256)
- [x] 30-day message TTL
- [x] Address masking
- [x] Secure data transmission
- [ ] **CRITICAL**: Privacy policy document
- [ ] **CRITICAL**: Terms of service
- [ ] User consent management
- [ ] Data retention policy
- [ ] Right to deletion implementation

### 7.2 App Store Requirements
- [ ] Privacy policy URL
- [ ] Terms of service URL
- [ ] Support contact information
- [ ] App screenshots (all sizes)
- [ ] App description (English + Sinhala)
- [ ] Content rating questionnaire

### 7.3 Accessibility
- [ ] WCAG 2.1 Level AA compliance
- [ ] Screen reader support
- [ ] High contrast mode
- [ ] Font size scalability

**Compliance Status: 65%** 🟡  
**Critical Blockers:**
1. Privacy policy document
2. Terms of service

---

## 8. Launch Preparation

### 8.1 Marketing
- [ ] App store listing optimization
- [ ] Website landing page
- [ ] Social media accounts
- [ ] Press kit
- [ ] Launch announcement content

### 8.2 Support
- [ ] Support email/phone setup
- [ ] FAQ documentation
- [ ] User guide/tutorial
- [ ] In-app help center

### 8.3 Operations
- [ ] Worker onboarding process
- [ ] Customer support workflow
- [ ] Escalation procedures
- [ ] Payment reconciliation process

---

## Critical Path to Launch

### Phase 1: Critical Fixes (Week 1-2)
- [ ] Fix BLoC compilation errors (~350 remaining)
- [ ] Regenerate Firebase API keys
- [ ] Complete payment integration (PayHere alternative)
- [ ] Write privacy policy & ToS

### Phase 2: Testing (Week 3-4)
- [ ] Achieve 80% test coverage
- [ ] Fix all critical bugs
- [ ] Performance optimization
- [ ] Security audit

### Phase 3: Beta (Week 5-6)
- [ ] Internal QA
- [ ] Closed beta (20 users)
- [ ] Bug fixes
- [ ] Final adjustments

### Phase 4: Launch (Week 7)
- [ ] Submit to Play Store
- [ ] Submit to App Store
- [ ] Marketing launch
- [ ] Monitor & support

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Payment integration delays | High | Critical | Implement PayHere web fallback |
| BLoC refactoring takes longer | Medium | High | Prioritize critical paths only |
| Security audit findings | Medium | High | Fix critical, schedule non-critical for v1.1 |
| App store rejection | Low | High | Review guidelines, prepare appeal |
| Worker supply shortage | Medium | Medium | Pre-launch worker recruitment |

---

## Sign-off Requirements

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Tech Lead | | | |
| Product Manager | | | |
| QA Lead | | | |
| Security Officer | | | |
| Legal/Compliance | | | |

---

## Quick Reference

### Essential Commands
```bash
# Run tests
flutter test --coverage

# Build release
flutter build appbundle --release

# Deploy to staging
firebase deploy --only functions --project helaservice-staging

# Check health
curl https://asia-south1-helaservice-prod.cloudfunctions.net/healthCheck
```

### Emergency Contacts
- **DevOps:** devops@helaservice.lk
- **On-call:** +94 77 XXX XXXX
- **Firebase Support:** https://firebase.google.com/support

### Key Metrics Targets
- **Crash-free rate:** > 99%
- **Daily active users:** 100+ (Month 1)
- **Booking completion rate:** > 70%
- **Average app rating:** > 4.0

---

*This document should be reviewed and updated weekly until launch.*
