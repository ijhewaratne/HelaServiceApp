# Quick Start Guide

Get HelaService running in 5 minutes.

## Prerequisites

- Flutter SDK ^3.11.0
- Dart SDK ^3.0.0
- Firebase CLI
- Android Studio / Xcode

## Installation

### 1. Clone Repository

```bash
git clone https://github.com/ijhewaratne/HelaServiceApp.git
cd HelaServiceApp
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

```bash
# Login to Firebase
firebase login

# Select project
firebase use helaservice-prod

# Copy Firebase config (if needed)
cp lib/firebase_options.dart.example lib/firebase_options.dart
```

### 4. Setup Environment

```bash
# Create .env file
cp .env.example .env

# Edit .env with your keys
nano .env
```

Required environment variables:
```
PAYHERE_MERCHANT_ID=your_merchant_id
PAYHERE_SECRET=your_secret
```

### 5. Run App

```bash
# Development mode
flutter run

# With hot reload
flutter run --hot

# Profile mode (performance testing)
flutter run --profile
```

## Development Workflow

### Code Quality

```bash
# Check code
flutter analyze

# Format code
flutter format lib test

# Run tests
flutter test
```

### Building

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release
```

### Testing

```bash
# All tests
flutter test

# With coverage
flutter test --coverage

# Specific test
flutter test test/unit/auth_test.dart
```

## Firebase Deployment

### Deploy Rules

```bash
# Firestore rules
firebase deploy --only firestore:rules

# Storage rules
firebase deploy --only storage

# Functions
firebase deploy --only functions

# Everything
firebase deploy
```

### Functions Development

```bash
cd functions

# Install dependencies
npm install

# Run locally
npm run serve

# Deploy
npm run deploy
```

## Common Tasks

### Add New Feature

1. Create feature folder in `lib/features/`
2. Add data layer (models, repository)
3. Add domain layer (entities, repository interface)
4. Add presentation layer (BLoC, UI)
5. Register in dependency injection
6. Add tests

### Update Icons

```bash
# Update icon in pubspec.yaml, then:
flutter pub run flutter_launcher_icons:main
```

### Generate Mocks

```bash
flutter pub run build_runner build
```

### Clean Build

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..  # macOS
```

## Troubleshooting

### Build Failures

```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### Firebase Issues

```bash
firebase logout
firebase login
firebase use helaservice-prod
```

### iOS Issues (macOS)

```bash
cd ios
pod deintegrate
pod install
cd ..
```

## Project Structure

```
lib/
├── core/          # Shared code
├── features/      # Feature modules
│   ├── auth/
│   ├── booking/
│   ├── payment/
│   └── ...
└── main.dart

test/
├── unit/          # Unit tests
├── widget/        # Widget tests
└── integration/   # Integration tests
```

## Resources

- [Architecture Guide](docs/ARCHITECTURE.md)
- [Deployment Guide](docs/DEPLOYMENT_GUIDE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## Support

- Email: dev@helaservice.lk
- Slack: #helaservice-dev
