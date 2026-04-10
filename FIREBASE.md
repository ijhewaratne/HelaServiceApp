# Firebase Deployment Guide

Complete guide for deploying and managing HelaService Firebase backend.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Deployment](#deployment)
- [Emulators](#emulators)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

```bash
# Node.js 18+
node --version

# Firebase CLI
npm install -g firebase-tools
firebase --version

# FlutterFire CLI (optional)
dart pub global activate flutterfire_cli
```

### Firebase Project Setup

1. Create Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Upgrade to Blaze plan (pay-as-you-go) for Cloud Functions
3. Enable required services:
   - Authentication (Phone provider)
   - Firestore Database
   - Cloud Storage
   - Cloud Functions

## Initial Setup

### Automated Setup

Run the setup script:

```bash
./scripts/setup-firebase.sh
```

This will:
- Check prerequisites
- Login to Firebase
- Setup project
- Install dependencies
- Create .env file
- Configure Firebase files

### Manual Setup

#### 1. Login to Firebase

```bash
firebase login
```

#### 2. Set Project

```bash
firebase use helaservice-prod
```

#### 3. Install Function Dependencies

```bash
cd functions
npm install
npm run build
cd ..
```

#### 4. Configure Environment

Create `.env` file:

```bash
cp .env.example .env
# Edit with your credentials
```

#### 5. Download Config Files

From Firebase Console → Project Settings:

- **Android**: Download `google-services.json` → `android/app/`
- **iOS**: Download `GoogleService-Info.plist` → `ios/Runner/`
- **Web/Flutter**: Run `flutterfire configure`

## Deployment

### Quick Deploy

Deploy everything to current project:

```bash
./scripts/deploy-firebase.sh
```

### Deploy to Specific Environment

```bash
# Development
./scripts/deploy-firebase.sh dev

# Staging
./scripts/deploy-firebase.sh staging

# Production
./scripts/deploy-firebase.sh prod
```

### Deploy Individual Services

```bash
# Firestore Rules only
firebase deploy --only firestore:rules

# Firestore Indexes
firebase deploy --only firestore:indexes

# Cloud Functions
firebase deploy --only functions

# Storage Rules
firebase deploy --only storage

# Specific function
firebase deploy --only functions:dispatchJob
```

### Deploy with CI/CD

GitHub Actions automatically deploys on push to `main`:

```yaml
# .github/workflows/deploy-firebase.yml
- name: Deploy to Firebase
  run: |
    npm install -g firebase-tools
    firebase deploy --token "${{ secrets.FIREBASE_TOKEN }}"
```

## Emulators

### Start Emulators

```bash
./scripts/emulators.sh start
```

Services available:
- **Firebase UI**: http://localhost:4000
- **Auth**: http://localhost:9099
- **Firestore**: http://localhost:8080
- **Functions**: http://localhost:5001
- **Storage**: http://localhost:9199

### Export Emulator Data

```bash
# While emulators are running
./scripts/emulators.sh export
```

### Import Previous Data

```bash
./scripts/emulators.sh start  # Auto-imports if data exists
```

### Seed Test Data

```bash
./scripts/emulators.sh seed
```

### Using with Flutter

```bash
# Start emulators
./scripts/emulators.sh start

# In another terminal, run Flutter with emulator
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

Update `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Connect to emulators in debug mode
  if (kDebugMode && const String.fromEnvironment('USE_FIREBASE_EMULATOR') == 'true') {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
  }
  
  runApp(const HelaServiceApp());
}
```

## Monitoring

### Firebase Console

| Service | URL |
|---------|-----|
| Project Overview | https://console.firebase.google.com/project/helaservice-prod/overview |
| Authentication | https://console.firebase.google.com/project/helaservice-prod/authentication |
| Firestore | https://console.firebase.google.com/project/helaservice-prod/firestore |
| Functions | https://console.firebase.google.com/project/helaservice-prod/functions |
| Storage | https://console.firebase.google.com/project/helaservice-prod/storage |
| Crashlytics | https://console.firebase.google.com/project/helaservice-prod/crashlytics |

### Cloud Functions Logs

```bash
# View all function logs
firebase functions:log

# View specific function logs
firebase functions:log --only dispatchJob

# Follow logs in real-time
firebase functions:log --tail
```

### Firestore Monitoring

```bash
# Check Firestore usage
firebase firestore:documents:list --collection-group workers

# Export collection (requires billing)
# Use Firebase Console → Firestore → Import/Export
```

## Troubleshooting

### Common Issues

#### 1. Permission Denied

```bash
# Check Firestore rules
firebase deploy --only firestore:rules

# Verify user is authenticated
# Check rules in firestore.rules match your use case
```

#### 2. Function Deployment Fails

```bash
# Check function logs
firebase functions:log

# Rebuild and deploy
cd functions
npm run build
cd ..
firebase deploy --only functions

# Deploy single function
firebase deploy --only functions:payhereNotify
```

#### 3. Indexes Not Found

```bash
# Deploy indexes
firebase deploy --only firestore:indexes

# Note: Index creation can take several minutes
# Check Firebase Console → Firestore → Indexes for status
```

#### 4. CORS Errors

Update `functions/src/index.ts`:

```typescript
import * as cors from 'cors';
const corsHandler = cors({ origin: true });

export const apiFunction = functions.https.onRequest((req, res) => {
  corsHandler(req, res, async () => {
    // Your function logic
  });
});
```

#### 5. Environment Variables Missing

```bash
# Set function config
firebase functions:config:set payhere.secret="YOUR_SECRET"

# View config
firebase functions:config:get

# Redeploy functions
firebase deploy --only functions
```

### Useful Commands

```bash
# List all Firebase projects
firebase projects:list

# Switch project
firebase use helaservice-prod

# Get project info
firebase apps:list

# Delete function
firebase functions:delete functionName

# Shell for testing functions locally
firebase functions:shell

# List deployed functions
firebase functions:list
```

### PayHere Webhook Testing

```bash
# Test webhook locally using ngrok
ngrok http 5001

# Configure PayHere to use ngrok URL
# https://YOUR_NGROK_ID.ngrok.io/helaservice-prod/us-central1/payhereNotify
```

## Security

### Firestore Rules Deployment

Always test rules before deployment:

```bash
# Test rules with emulator suite
firebase emulators:start --only firestore

# Deploy rules
firebase deploy --only firestore:rules
```

### Function Secrets

```bash
# Set secret
firebase functions:config:set someservice.key="SECRET_KEY"

# Access in function
const config = functions.config();
const key = config.someservice.key;
```

## Cost Optimization

### Free Tier Limits

| Service | Free Tier |
|---------|-----------|
| Firestore | 50K reads/day, 20K writes/day |
| Functions | 2M invocations/month |
| Storage | 5GB |
| Auth | 10K users/month |

### Monitor Usage

- Set up budget alerts in Google Cloud Console
- Monitor Firebase Console → Usage
- Use Firebase Extensions for optimization

## Backup & Recovery

### Automated Backups

```bash
# Export Firestore (requires Cloud Storage bucket)
gcloud firestore export gs://helaservice-backups/2024-04-10

# Schedule backups with Cloud Scheduler
```

### Manual Export/Import

```bash
# Export
gcloud firestore export gs://helaservice-backups/manual-$(date +%Y%m%d)

# Import
gcloud firestore import gs://helaservice-backups/manual-20240410/
```

## Support

- Firebase Docs: https://firebase.google.com/docs
- Firebase CLI Reference: https://firebase.google.com/docs/cli
- HelaService Issues: https://github.com/ijhewaratne/HelaServiceApp/issues
