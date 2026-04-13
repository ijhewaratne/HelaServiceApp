# Store Preparation Guide

Sprint 6: Final QA & Deployment

## App Icons

### Android Icon Sizes

| Size | Purpose |
|------|---------|
| 512x512 | Play Store listing |
| 192x192 | xxxhdpi launcher |
| 144x144 | xxhdpi launcher |
| 96x96 | xhdpi launcher |
| 72x72 | hdpi launcher |
| 48x48 | mdpi launcher |

### iOS Icon Sizes

| Size | Purpose |
|------|---------|
| 1024x1024 | App Store |
| 180x180 | iPhone 60pt @3x |
| 120x120 | iPhone 60pt @2x |
| 167x167 | iPad 83.5pt @2x |
| 152x152 | iPad 76pt @2x |

### Generate Icons

```bash
flutter pub add flutter_launcher_icons --dev
flutter pub run flutter_launcher_icons:main
```

## Screenshots

### Required Dimensions

**Phone:** 1080x1920 (portrait)
**Tablet:** 2048x2732 (iPad)

### Screenshot Content

1. Home/Dashboard - Service categories
2. Service Booking - Easy booking flow
3. Worker Profile - Trust indicators
4. Real-time Tracking - Map view
5. Payment - Secure checkout
6. Support - Customer service

## App Description

### Short Description (80 chars)
Professional home services in Sri Lanka. Book trusted cleaners, plumbers & more.

### Full Description

HelaService - Sri Lankas Trusted Home Services Platform

Get professional home services delivered to your doorstep in Colombo and surrounding areas. From cleaning to repairs, find verified experts at transparent prices.

KEY FEATURES:

- Wide Range of Services: House Cleaning, Plumbing, Electrical, AC Repair, Gardening
- Verified Professionals: Background checked, ID verified, certified skills
- Real-time Tracking: Live location, accurate ETAs, status updates
- Secure Payments: Multiple options, transparent pricing, digital receipts
- Trust & Safety: Insurance coverage, satisfaction guarantee, 24/7 support

SERVICE AREAS:
Currently serving Colombo 03, 04, 07 and Rajagiriya.

Download HelaService today!

## Privacy Policy

See: docs/PRIVACY_POLICY.md

## Terms of Service

See: docs/TERMS_OF_SERVICE.md
