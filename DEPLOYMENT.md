# Deployment Guide

Complete guide for deploying HelaService to production.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Building for Production](#building-for-production)
4. [Deploying to Stores](#deploying-to-stores)
5. [CI/CD Automation](#cicd-automation)
6. [Monitoring & Rollback](#monitoring--rollback)

## Prerequisites

### Required Accounts

- [ ] Google Play Console account ($25 one-time fee)
- [ ] Apple Developer Program ($99/year)
- [ ] Firebase project with Blaze plan (for Cloud Functions)
- [ ] PayHere merchant account (for production payments)

### Required Files

#### Android
- `android/app/keystore.jks` - Signing keystore
- `android/key.properties` - Keystore configuration
- `android/app/google-services.json` - Firebase config

#### iOS
- `ios/Runner/GoogleService-Info.plist` - Firebase config
- `ios/ExportOptions.plist` - Export configuration
- Certificates and provisioning profiles (via fastlane match)

## Environment Setup

### 1. Configure GitHub Secrets

Go to Settings → Secrets and variables → Actions, add:

#### Required Secrets

```bash
# Firebase Configuration
GOOGLE_SERVICES_JSON          # Content of google-services.json
GOOGLE_SERVICE_INFO_PLIST     # Content of GoogleService-Info.plist
FIREBASE_OPTIONS_DART         # Content of firebase_options.dart
FIREBASE_ANDROID_APP_ID       # e.g., 1:919789688280:android:xxx
FIREBASE_TOKEN                # Firebase CLI token

# Android Signing
KEYSTORE_BASE64               # Base64 encoded keystore.jks
KEY_PROPERTIES                # Content of key.properties

# iOS Signing (for fastlane match)
MATCH_PASSWORD                # Password for fastlane match
MATCH_GIT_URL                 # Private repo for certificates

# App Store Connect
APPLE_ID                      # Apple Developer email
APP_STORE_CONNECT_API_KEY     # API key JSON

# Google Play
PLAY_STORE_SERVICE_ACCOUNT_JSON  # Service account JSON

# PayHere
PAYHERE_MERCHANT_ID           # Production merchant ID
PAYHERE_MERCHANT_SECRET       # Production merchant secret
```

### 2. Generate Firebase Token

```bash
firebase login:ci
# Copy the token and add as FIREBASE_TOKEN secret
```

### 3. Setup Android Keystore

```bash
cd android/app

# Generate keystore
keytool -genkey -v \
  -keystore keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias helaservice

# Base64 encode for GitHub secret
base64 -i keystore.jks | pbcopy
# Paste into KEYSTORE_BASE64 secret
```

Create `android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=helaservice
storeFile=keystore.jks
```

## Building for Production

### Manual Build

#### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### Android AppBundle (Recommended)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

#### iOS IPA
```bash
flutter build ipa --release
# Output: build/ios/ipa/*.ipa
```

### Using Fastlane

#### Android
```bash
cd android

# Build release
fastlane build_release

# Build bundle
fastlane build_bundle

# Deploy to Firebase Beta
fastlane deploy_beta

# Deploy to Play Store Internal
fastlane deploy_internal
```

#### iOS
```bash
cd ios

# Sync certificates
fastlane sync_certs

# Build
fastlane build

# Deploy to TestFlight
fastlane deploy_beta

# Deploy to App Store
fastlane deploy_production
```

## Deploying to Stores

### Google Play Store

1. **Create App**
   - Go to [Play Console](https://play.google.com/console)
   - Create new app with package name: `com.helaservice.app`

2. **Setup Store Listing**
   - Add app title: "HelaService"
   - Add short description
   - Add full description
   - Upload screenshots (phone, tablet)
   - Upload feature graphic
   - Upload app icon

3. **Content Rating**
   - Complete content rating questionnaire
   - Category: Utilities/Productivity

4. **Pricing & Distribution**
   - Free app
   - Available in: Sri Lanka (initially)

5. **Upload Release**
   - Upload AAB file
   - Add release notes
   - Start internal testing → closed testing → production

### Apple App Store

1. **Create App**
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Create new app with bundle ID: `com.helaservice.app`

2. **Setup App Information**
   - Name: "HelaService"
   - Subtitle: "Trusted Home Services"
   - Primary category: Lifestyle
   - Secondary category: Productivity

3. **Upload Build**
   - Use Xcode or Transporter to upload IPA
   - Or use fastlane: `fastlane ios deploy_beta`

4. **App Review Information**
   - Contact information
   - Demo account credentials
   - Notes for reviewer

5. **Submit for Review**
   - Complete all required fields
   - Submit for App Review (1-2 days)

## CI/CD Automation

### Automatic Deployment Triggers

| Trigger | Action |
|---------|--------|
| Push to `develop` | Run tests, build debug |
| Push to `main` | Run tests, build release, deploy to internal testing |
| Tag `v*-beta` | Deploy to Firebase/TestFlight beta |
| Tag `v*.*.*` | Deploy to production stores |

### GitHub Actions Workflows

#### 1. Flutter CI (`flutter-ci.yml`)
- Runs on: PRs, pushes to main/develop
- Actions: Analyze, test, build

#### 2. Integration Tests (`integration-tests.yml`)
- Runs on: Schedule (nightly), PRs
- Actions: Run on Android/iOS emulators

#### 3. Deploy Beta (`deploy-beta.yml`)
- Runs on: Beta tags, manual
- Actions: Build and deploy to beta channels

#### 4. Deploy Production (`deploy-production.yml`)
- Runs on: Production tags, manual approval
- Actions: Build, deploy to stores, create GitHub release

### Deployment Checklist

Before deploying to production:

- [ ] All tests passing
- [ ] Version bumped in `pubspec.yaml`
- [ ] Changelog updated
- [ ] Firebase config files in place
- [ ] PayHere credentials are production
- [ ] Analytics enabled
- [ ] Crashlytics enabled
- [ ] App icons generated for all sizes
- [ ] Screenshots updated
- [ ] Store descriptions updated
- [ ] Privacy policy URL set
- [ ] Terms of service URL set
- [ ] Support email set

## Monitoring & Rollback

### Post-Deployment Monitoring

1. **Firebase Console**
   - Check Crashlytics for crashes
   - Monitor Analytics for usage
   - Check Performance metrics

2. **Google Play Console**
   - Review crash reports
   - Monitor ANR rates
   - Check user reviews

3. **App Store Connect**
   - Review crash logs
   - Monitor app units
   - Check ratings

### Rollback Strategy

#### Android
1. Go to Play Console → Release
2. Select previous release
3. Click "Promote to production"
4. Or halt current release

#### iOS
1. Go to App Store Connect
2. Remove current version from sale
3. Submit expedited review for fix
4. Or release new version

### Hotfix Process

1. Create hotfix branch from `main`:
   ```bash
   git checkout -b hotfix/critical-bug main
   ```

2. Fix the issue

3. Bump version (patch):
   ```yaml
   # pubspec.yaml
   version: 1.0.1+2
   ```

4. Commit and tag:
   ```bash
   git commit -m "hotfix: Fix critical bug"
   git tag v1.0.1
   git push origin main --tags
   ```

5. CI/CD automatically deploys

## Environment Variables

### Production Checklist

Ensure these are set to production values:

```bash
# Firebase
FIREBASE_PROJECT=helaservice-prod

# PayHere
PAYHERE_SANDBOX=false
PAYHERE_MERCHANT_ID=your_production_merchant_id

# App
APP_ENV=production
ENABLE_ANALYTICS=true
ENABLE_CRASHLYTICS=true
```

## Support

For deployment issues:
- Check GitHub Actions logs
- Review fastlane output
- Check Firebase/Store console for errors
- Contact: devops@helaservice.lk
