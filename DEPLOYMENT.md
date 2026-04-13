# Phase 6: DevOps & Monitoring - Deployment Guide

This document describes the deployment infrastructure, CI/CD pipelines, monitoring, and backup procedures for HelaService.

## Table of Contents
- [Environments](#environments)
- [CI/CD Pipelines](#cicd-pipelines)
- [Deployment Procedures](#deployment-procedures)
- [Monitoring & Alerting](#monitoring--alerting)
- [Backup & Recovery](#backup--recovery)
- [Required Secrets](#required-secrets)

## Environments

### Production
- **Firebase Project**: `helaservice-prod`
- **Branch**: `main` or `master`
- **URL**: https://helaservice.lk
- **API**: https://asia-south1-helaservice-prod.cloudfunctions.net

### Staging
- **Firebase Project**: `helaservice-staging`
- **Branch**: `develop`
- **URL**: https://staging.helaservice.lk
- **API**: https://asia-south1-helaservice-staging.cloudfunctions.net

### Local Development
- **Firebase Emulator Suite**: http://localhost:4000
- **Firestore**: localhost:8080
- **Auth**: localhost:9099

## CI/CD Pipelines

### Staging Deployment
Trigger: Push to `develop` branch

```yaml
# .github/workflows/deploy-staging.yml
Jobs:
  1. analyze - Code quality checks
  2. test - Run unit tests with coverage
  3. build-android - Build APK and upload to Firebase App Distribution
  4. deploy-firebase - Deploy Firestore rules, indexes, functions
  5. notify - Slack notifications
```

### Production Deployment
Trigger: GitHub Release published

```yaml
# .github/workflows/deploy-production.yml
Jobs:
  1. pre-check - Verify release tag format, branch protection
  2. test - Full test suite including integration tests
  3. build-android - Build AAB and upload to Play Store (Internal)
  4. build-ios - Build IPA and upload to App Store Connect
  5. deploy-firebase - Deploy production Firebase resources
  6. verify-deployment - Health checks
  7. notify - Slack and Sentry notifications
```

## Deployment Procedures

### Staging Deployment

1. **Create feature branch**:
   ```bash
   git checkout -b feature/your-feature
   ```

2. **Make changes and commit**:
   ```bash
   git add .
   git commit -m "feat: your feature description"
   ```

3. **Push to origin**:
   ```bash
   git push origin feature/your-feature
   ```

4. **Create Pull Request** to `develop` branch

5. **Merge PR** - Deployment starts automatically

6. **Monitor deployment** in GitHub Actions and Slack

### Production Deployment

1. **Ensure staging is stable**:
   - All tests passing
   - QA sign-off
   - Feature flags verified

2. **Create release**:
   ```bash
   git checkout main
   git pull origin main
   git tag -a v1.2.3 -m "Release v1.2.3"
   git push origin v1.2.3
   ```

3. **Create GitHub Release** with release notes

4. **Monitor deployment**:
   - GitHub Actions progress
   - Slack notifications
   - Health check endpoints

5. **Promote in Play Store**:
   - Internal → Closed → Open → Production

## Monitoring & Alerting

### Health Check Endpoints

| Endpoint | URL | Purpose |
|----------|-----|---------|
| Health | `/healthCheck` | Comprehensive system health |
| Ping | `/ping` | Basic uptime check |
| Ready | `/ready` | Kubernetes readiness probe |
| Live | `/live` | Kubernetes liveness probe |

### Uptime Monitoring

**UptimeRobot Configuration**:
- API Health: Every 5 minutes
- Ping: Every 1 minute
- Firestore: Every 10 minutes
- Website: Every 5 minutes

**Alert Thresholds**:
- API Latency > 2s → Warning
- Error Rate > 5% → Critical
- Uptime < 99.9% → SLA Alert

### Cloud Monitoring Alerts

| Metric | Threshold | Severity |
|--------|-----------|----------|
| Function Error Rate | > 5% | ERROR |
| Function Latency P99 | > 2s | WARNING |
| Firestore Read Latency | > 500ms | WARNING |
| Firestore Write Errors | > 10/min | CRITICAL |
| Auth Failed Logins | > 100/min | CRITICAL |
| Daily Spend | > $100 | WARNING |

## Backup & Recovery

### Automated Backups

**Schedule**: Daily at 2:00 AM Asia/Colombo time

**Collections Backed Up**:
- Critical: users, bookings, worker_profiles, payments, job_requests, job_offers
- Secondary: notifications, chat_messages, reviews, incidents, feedback

**Retention**: 30 days

**Storage**: `helaservice-prod-backups` bucket

### Manual Backup

```bash
# Trigger manual backup via Firebase CLI
firebase functions:shell
callManualBackup({ collections: ['users', 'bookings'] })
```

Or use the admin dashboard in the app.

### Restore Procedure

1. **Access admin dashboard** (admin role required)

2. **Navigate to Backup & Restore** section

3. **Select backup date** from available backups

4. **Choose collections** to restore

5. **Run in DRY RUN mode** first to verify:
   ```typescript
   restoreFromBackup({
     backupDate: '2024-01-15',
     collections: ['users'],
     dryRun: true
   })
   ```

6. **Execute restore** (if dry run successful):
   ```typescript
   restoreFromBackup({
     backupDate: '2024-01-15',
     collections: ['users'],
     dryRun: false
   })
   ```

7. **Verify restored data**

### Disaster Recovery

**RPO (Recovery Point Objective)**: 24 hours

**RTO (Recovery Time Objective)**: 4 hours

**Steps**:
1. Identify affected collections
2. Locate most recent backup
3. Restore to new Firestore instance (if needed)
4. Verify data integrity
5. Switch app to recovered instance
6. Post-incident review

## Required Secrets

Configure these in GitHub Repository Settings → Secrets and Variables → Actions:

### Firebase
```
FIREBASE_SERVICE_ACCOUNT_STAGING    # GCP Service Account JSON (staging)
FIREBASE_SERVICE_ACCOUNT_PRODUCTION # GCP Service Account JSON (production)
FIREBASE_PROJECT_STAGING            # helaservice-staging
FIREBASE_PROJECT_PRODUCTION         # helaservice-prod
FIREBASE_APP_ID_STAGING             # Staging App ID
FIREBASE_API_KEY_STAGING            # Staging API Key
```

### Android Signing
```
STAGING_KEYSTORE_BASE64             # Base64 encoded keystore
STAGING_KEYSTORE_PASSWORD
STAGING_KEY_PASSWORD
STAGING_KEY_ALIAS
PRODUCTION_KEYSTORE_BASE64
PRODUCTION_KEYSTORE_PASSWORD
PRODUCTION_KEY_PASSWORD
PRODUCTION_KEY_ALIAS
```

### iOS Signing
```
IOS_DISTRIBUTION_CERTIFICATE        # Base64 encoded .p12
IOS_CERTIFICATE_PASSWORD
APPSTORE_ISSUER_ID
APPSTORE_API_KEY_ID
APPSTORE_API_PRIVATE_KEY
```

### Google Play Store
```
PLAY_STORE_SERVICE_ACCOUNT          # JSON service account key
```

### Notifications
```
SLACK_WEBHOOK_URL                   # Staging deployments
SLACK_WEBHOOK_URL_PRODUCTION        # Production deployments
PAGERDUTY_KEY                       # Critical alerts
```

### Monitoring
```
SENTRY_AUTH_TOKEN                   # Error tracking
UPTIMEROBOT_API_KEY                 # Uptime monitoring
```

### Code Quality
```
CODECOV_TOKEN                       # Test coverage reporting
```

## Environment Files

Create these files in project root:

### .env.staging
```
FIREBASE_API_KEY_STAGING=your_staging_api_key
FIREBASE_APP_ID_STAGING=your_staging_app_id
FIREBASE_MESSAGING_SENDER_ID_STAGING=123456789
FIREBASE_PROJECT_ID_STAGING=helaservice-staging
FIREBASE_STORAGE_BUCKET_STAGING=helaservice-staging.appspot.com
ENCRYPTION_KEY=your_staging_encryption_key
```

### .env.production
```
FIREBASE_API_KEY_PRODUCTION=your_production_api_key
FIREBASE_APP_ID_PRODUCTION=your_production_app_id
FIREBASE_MESSAGING_SENDER_ID_PRODUCTION=123456789
FIREBASE_PROJECT_ID_PRODUCTION=helaservice-prod
FIREBASE_STORAGE_BUCKET_PRODUCTION=helaservice-prod.appspot.com
ENCRYPTION_KEY=your_production_encryption_key
```

**Note**: Never commit `.env` files to git. Add them to `.gitignore`.

## Rollback Procedures

### Firebase Functions Rollback
```bash
firebase functions:rollback --project helaservice-prod
```

### Firestore Rules Rollback
Rules are versioned in Git. Revert commit and redeploy:
```bash
git revert <commit-hash>
git push origin main
```

### App Rollback

**Android**:
1. Go to Play Store Console
2. Select previous release
3. Promote to production

**iOS**:
1. Go to App Store Connect
2. Expire current build
3. Select previous build

## Support & Contacts

- **DevOps Team**: devops@helaservice.lk
- **On-Call Engineer**: +94 77 123 4567
- **Emergency Escalation**: pagerduty escalation policy

## Useful Commands

```bash
# Deploy to staging manually
firebase deploy --only functions --project helaservice-staging

# View function logs
firebase functions:log --project helaservice-prod

# Check Firestore indexes
firebase firestore:indexes --project helaservice-prod

# Run local emulator
firebase emulators:start

# Test health endpoint
curl https://asia-south1-helaservice-prod.cloudfunctions.net/healthCheck
```
