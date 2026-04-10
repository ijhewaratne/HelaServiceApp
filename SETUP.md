# HelaService Setup Guide

## ⚠️ CRITICAL: API Key Security

**DO NOT COMMIT API KEYS TO GIT!**

The following files contain sensitive API keys and are now excluded from version control:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`
- `.env`

### Getting Your Firebase Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `helaservice-prod`
3. Click the gear icon ⚙️ > **Project settings**
4. Under **Your apps**, download the config files:
   - **Android**: `google-services.json` → place in `android/app/`
   - **iOS**: `GoogleService-Info.plist` → place in `ios/Runner/`

5. For Flutter native (`firebase_options.dart`), run:
   ```bash
   flutterfire configure --project=helaservice-prod
   ```
   Or manually create `lib/firebase_options.dart` using the template below.

### Manual Configuration (Alternative)

If you don't have FlutterFire CLI installed:

1. Copy the example files:
   ```bash
   cp android/app/google-services.json.example android/app/google-services.json
   cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
   cp lib/firebase_options.dart.example lib/firebase_options.dart
   ```

2. Replace all `YOUR_*` placeholders with actual values from Firebase Console

### Verifying Setup

After adding your config files, run:
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

---

## PayHere Configuration

1. Copy the environment template:
   ```bash
   cp .env.example .env
   ```

2. Fill in your PayHere credentials:
   ```
   PAYHERE_MERCHANT_ID=your_merchant_id
   PAYHERE_MERCHANT_SECRET=your_merchant_secret
   PAYHERE_SANDBOX=true
   ```

3. Get credentials from [PayHere Merchant Portal](https://payhere.lk/)

---

## Git Security Check

Before committing, verify no secrets are staged:
```bash
# Check what files are staged
git status

# Verify no API keys in staged files
git diff --cached | grep -i "api.*key\|AIzaSy"

# If firebase_options.dart shows as modified but untracked, good!
git ls-files | grep firebase_options  # Should return nothing
```

---

## 🚨 If Keys Were Already Committed

Since API keys are already in git history, you should:

### Option 1: Rotate Keys (Recommended)
1. Go to Firebase Console > Project Settings > General
2. For each API key, click **"Delete"** and create new ones
3. Update your local config files with new keys
4. Never commit the new files

### Option 2: Use git-filter-repo (Advanced)
Remove files from entire git history:
```bash
# Install git-filter-repo
pip install git-filter-repo

# Remove files from history
git filter-repo --path android/app/google-services.json --path ios/Runner/GoogleService-Info.plist --path lib/firebase_options.dart --invert-paths

# Force push (DANGEROUS - affects all collaborators)
git push origin --force --all
```

**⚠️ Warning**: Force pushing rewrites history. All team members must re-clone the repo.

---

## Team Collaboration

Each developer should:
1. Get their own Firebase config (or share securely via password manager)
2. Never commit config files
3. Use `.env` for all secrets
4. Run `git status` before every commit to verify

---

## CI/CD Configuration

For GitHub Actions or other CI:
1. Store secrets in repository secrets
2. Generate config files during build:
   ```yaml
   - name: Create Firebase Config
     run: |
       echo '${{ secrets.GOOGLE_SERVICES_JSON }}' > android/app/google-services.json
       echo '${{ secrets.GOOGLE_SERVICE_INFO_PLIST }}' > ios/Runner/GoogleService-Info.plist
   ```
