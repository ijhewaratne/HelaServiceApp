# App Store & Play Store Preparation Guide

Complete guide for publishing HelaService to Google Play Store and Apple App Store.

## Table of Contents

1. [Pre-Launch Checklist](#pre-launch-checklist)
2. [Android - Google Play Store](#android---google-play-store)
3. [iOS - Apple App Store](#ios---apple-app-store)
4. [Web Deployment](#web-deployment)
5. [Store Assets](#store-assets)
6. [Post-Launch](#post-launch)

## Pre-Launch Checklist

### Technical Checklist

- [ ] App builds successfully in release mode
- [ ] All tests passing
- [ ] No debug logs or test code
- [ ] App icon generated for all sizes
- [ ] Splash screen configured
- [ ] Firebase configured for production
- [ ] PayHere credentials are production
- [ ] Analytics and Crashlytics enabled
- [ ] App size optimized (< 150MB for cellular download)
- [ ] ProGuard/R8 configured (Android)
- [ ] Bitcode disabled (iOS)

### Content Checklist

- [ ] App name finalized
- [ ] Short description (80 chars for Play Store)
- [ ] Full description (4000 chars)
- [ ] Screenshots for all device sizes
- [ ] Feature graphic (Play Store)
- [ ] App Preview video (optional)
- [ ] Privacy policy URL
- [ ] Terms of service URL
- [ ] Support email/website
- [ ] Content rating completed

### Legal Checklist

- [ ] Privacy policy compliant (GDPR, CCPA, PDPA)
- [ ] Terms of service drafted
- [ ] Copyright/trademark checks
- [ ] PayHere merchant agreement signed
- [ ] Worker contract terms reviewed

## Android - Google Play Store

### 1. App Signing Setup

```bash
# Generate upload keystore (if not exists)
keytool -genkey -v \
  -keystore android/app/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload \
  -storepass YOUR_STORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD \
  -dname "CN=HelaService, O=HelaService, L=Colombo, S=Western, C=LK"

# Create key.properties
cat > android/key.properties << EOF
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
EOF
```

### 2. Build Release AppBundle

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build AppBundle (recommended over APK)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### 3. Play Console Setup

1. **Create App**
   - Go to [Play Console](https://play.google.com/console)
   - Click "Create app"
   - App name: "HelaService"
   - Default language: English (US)
   - App type: App
   - Free or paid: Free

2. **Store Presence**
   - **App name**: HelaService (30 chars max)
   - **Short description**: Book trusted home services in Sri Lanka (80 chars)
   - **Full description**: See `store_assets/android/full_description.txt`

3. **Graphics**
   - **App icon**: 512 x 512 PNG
   - **Feature graphic**: 1024 x 500 PNG
   - **Phone screenshots**: 2-8 screenshots, 320px minimum
   - **7-inch tablet**: Optional
   - **10-inch tablet**: Optional

### 4. Content Rating

- Category: "Lifestyle" or "House & Home"
- Complete questionnaire honestly
- Expected rating: PEGI 3 / ESRB Everyone

### 5. Release Tracks

```
Internal Testing → Closed Testing → Open Testing → Production
```

Start with **Internal Testing** for team validation.

### 6. Automated Play Store Deployment

```bash
# Using fastlane
cd android
fastlane deploy_internal    # Deploy to internal testing
fastlane deploy_beta        # Deploy to beta
fastlane deploy_production  # Deploy to production
```

## iOS - Apple App Store

### 1. Certificates & Provisioning

```bash
# Using fastlane match (recommended)
cd ios
fastlane match development
fastlane match appstore

# Or manual setup in Apple Developer Portal
```

### 2. Build Release IPA

```bash
# Clean build
flutter clean
flutter pub get

# Build iOS
cd ios
pod install
flutter build ios --release

# Create archive in Xcode
# Product → Archive
# Or using fastlane:
fastlane build
```

### 3. App Store Connect Setup

1. **Create App**
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - My Apps → Click "+" → New App
   - Platforms: iOS
   - Name: HelaService
   - Primary Language: English (US)
   - Bundle ID: com.helaservice.app
   - SKU: helaservice-001
   - Full Access: Yes

2. **App Information**
   - **Name**: HelaService (30 chars max)
   - **Subtitle**: Trusted Home Services (30 chars max)
   - **Category**: Lifestyle (Primary), Productivity (Secondary)

3. **Pricing and Availability**
   - Price: Free
   - Availability: Sri Lanka initially

### 4. App Review Information

- **Sign-in required**: Yes (phone number)
- **User name**: Test Account
- **Password**: (Leave blank - uses OTP)
- **Contact Information**: Your details
- **Notes**: "This app uses phone number authentication. Use any Sri Lankan mobile number starting with 07 to test."

### 5. Screenshots Required

- **6.5" Display**: 1284 x 2778 pixels (iPhone 14 Pro Max)
- **5.5" Display**: 1242 x 2208 pixels (iPhone 8 Plus)
- **iPad Pro**: 2048 x 2732 pixels (optional but recommended)

### 6. Automated App Store Deployment

```bash
# Using fastlane
cd ios
fastlane deploy_beta        # Upload to TestFlight
fastlane deploy_production  # Submit for review
```

## Web Deployment

### Build Web App

```bash
# Build for web
flutter build web --release

# Output: build/web/
```

### Firebase Hosting Deployment

```bash
# Deploy to Firebase Hosting
firebase deploy --only hosting

# Or using GitHub Actions (automatic on push to main)
```

### Custom Domain

1. Add custom domain in Firebase Console
2. Update DNS records
3. Verify ownership
4. Configure SSL

## Store Assets

### Screenshot Guidelines

**Phone Screenshots (Required)**

1. **Welcome/Auth Screen**
   - Phone number input
   - Clean, inviting UI
   - Show Sri Lankan context

2. **Service Selection**
   - Grid of services
   - Icons visible
   - Clean layout

3. **Booking Form**
   - Date/time selection
   - Map view
   - Price estimate

4. **Worker Dashboard**
   - Online toggle
   - Stats visible
   - Job offers

5. **Payment Screen**
   - PayHere integration
   - Amount display
   - Security indicators

6. **Live Tracking**
   - Map with location
   - Worker details
   - Progress indicator

**Tablet Screenshots (Optional)**
- Similar screens in tablet layout
- Show responsive design

### Screenshot Tools

```bash
# Using Flutter's screenshot testing
flutter test --update-goldens

# Using iOS Simulator
# Device → Screenshot

# Using Android Emulator
# Extended Controls → Screenshot
```

### App Icon Requirements

**Android**
- 512 x 512 PNG (Play Store)
- Adaptive icons for app
- Different densities: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi

**iOS**
- 1024 x 1024 PNG (App Store)
- App icon: 180 x 180 @3x
- Settings icon: 87 x 87 @3x
- Spotlight icon: 120 x 120 @3x
- Notification icon: 60 x 60 @3x

### Feature Graphic (Play Store)

- Size: 1024 x 500 pixels
- Format: PNG or JPEG
- Content: App name, tagline, key visual
- Safe zone: Text in center 400 x 500 area

## Post-Launch

### Monitoring

**Day 1-7**
- Check crash reports hourly
- Monitor reviews
- Watch for critical bugs
- Respond to user feedback

**Week 1-4**
- Daily active users (DAU)
- Retention rates
- Conversion funnel analysis
- App store ratings

### Review Management

```
⭐⭐⭐⭐⭐ - Respond with thanks
⭐⭐⭐⭐ - Acknowledge feedback
⭐⭐⭐ - Address concerns
⭐⭐ - Investigate issues
⭐ - Immediate response & fix
```

### Update Strategy

**Hotfix** (Critical bugs)
- Deploy within 24 hours
- Minimal review process

**Patch** (Minor fixes)
- Weekly cadence
- Bug fixes, performance

**Minor** (Features)
- Monthly cadence
- New features, improvements

**Major** (Big releases)
- Quarterly
- Redesigns, major features

### Marketing Launch

- Social media announcement
- Press release to tech blogs
- Influencer partnerships
- Referral program launch

## Quick Reference

### Build Commands

```bash
# Android
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Deploy Commands

```bash
# Firebase
firebase deploy

# Fastlane Android
fastlane android deploy_production

# Fastlane iOS
fastlane ios deploy_production
```

### Store URLs

- Play Console: https://play.google.com/console
- App Store Connect: https://appstoreconnect.apple.com
- Firebase Console: https://console.firebase.google.com

---

## Support

For store submission issues:
- Play Store Support: https://support.google.com/googleplay
- App Store Support: https://developer.apple.com/support
- HelaService Team: support@helaservice.lk
