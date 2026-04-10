#!/bin/bash

# HelaService Firebase Setup Script
# Usage: ./scripts/setup-firebase.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  HelaService Firebase Setup           ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v node &> /dev/null; then
    echo -e "${RED}Node.js not found. Please install Node.js 18+${NC}"
    exit 1
fi

if ! command -v firebase &> /dev/null; then
    echo -e "${YELLOW}Firebase CLI not found. Installing...${NC}"
    npm install -g firebase-tools
fi

if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter not found. Please install Flutter${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites met${NC}"
echo ""

# Firebase Login
echo -e "${YELLOW}Step 1: Firebase Authentication${NC}"
if ! firebase projects:list &> /dev/null; then
    echo "Please login to Firebase:"
    firebase login
else
    echo -e "${GREEN}✓ Already logged in${NC}"
fi
echo ""

# Select or Create Project
echo -e "${YELLOW}Step 2: Firebase Project Setup${NC}"
echo "Available projects:"
firebase projects:list
echo ""
echo "Enter your Firebase project ID (or 'create' to create new):"
read PROJECT_ID

if [ "$PROJECT_ID" == "create" ]; then
    echo "Enter new project ID:"
    read NEW_PROJECT_ID
    echo "Enter project name:"
    read PROJECT_NAME
    firebase projects:create $NEW_PROJECT_ID --display-name "$PROJECT_NAME"
    PROJECT_ID=$NEW_PROJECT_ID
fi

firebase use $PROJECT_ID
echo -e "${GREEN}✓ Using project: $PROJECT_ID${NC}"
echo ""

# Setup Functions
echo -e "${YELLOW}Step 3: Setup Cloud Functions${NC}"
cd functions

if [ ! -d "node_modules" ]; then
    echo "Installing function dependencies..."
    npm install
fi

echo "Building functions..."
npm run build

cd ..
echo -e "${GREEN}✓ Functions ready${NC}"
echo ""

# Create .env file if not exists
echo -e "${YELLOW}Step 4: Environment Configuration${NC}"
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo -e "${YELLOW}Created .env file. Please edit with your credentials.${NC}"
else
    echo -e "${GREEN}✓ .env file exists${NC}"
fi
echo ""

# Firebase configuration files
echo -e "${YELLOW}Step 5: Firebase Configuration Files${NC}"

# Check for google-services.json
if [ ! -f "android/app/google-services.json" ]; then
    echo -e "${YELLOW}⚠ android/app/google-services.json not found${NC}"
    echo "Download from Firebase Console → Project Settings → Your Apps → Android"
fi

# Check for GoogleService-Info.plist
if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${YELLOW}⚠ ios/Runner/GoogleService-Info.plist not found${NC}"
    echo "Download from Firebase Console → Project Settings → Your Apps → iOS"
fi

# Generate firebase_options.dart
if [ ! -f "lib/firebase_options.dart" ]; then
    echo "Generating firebase_options.dart..."
    flutterfire configure --project=$PROJECT_ID --platforms=android,ios,web || true
    echo -e "${YELLOW}If flutterfire configure failed, run manually:${NC}"
    echo "  flutterfire configure --project=$PROJECT_ID"
fi

echo -e "${GREEN}✓ Firebase configuration complete${NC}"
echo ""

# Firestore setup
echo -e "${YELLOW}Step 6: Firestore Database Setup${NC}"
echo "Make sure Firestore database is created in Firebase Console"
echo "URL: https://console.firebase.google.com/project/$PROJECT_ID/firestore"
echo ""

# Run initial deployment
echo -e "${YELLOW}Step 7: Initial Firebase Deployment${NC}"
echo "Deploy Firebase rules and functions? (y/n)"
read DEPLOY

if [ "$DEPLOY" == "y" ]; then
    ./scripts/deploy-firebase.sh dev
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Firebase Setup Complete!             ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Edit .env file with your credentials"
echo "  2. Download Firebase config files for Android/iOS"
echo "  3. Run: flutter pub get"
echo "  4. Run: flutter run"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo "  ./scripts/deploy-firebase.sh dev    # Deploy to dev"
echo "  firebase emulators:start            # Start local emulators"
echo "  flutter run                         # Run app"
echo ""
