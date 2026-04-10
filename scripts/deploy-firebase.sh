#!/bin/bash

# HelaService Firebase Deployment Script
# Usage: ./scripts/deploy-firebase.sh [environment]
# Environments: dev (default), staging, prod

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default environment
ENV=${1:-dev}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  HelaService Firebase Deployment      ${NC}"
echo -e "${BLUE}  Environment: $ENV                     ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Verify Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}Error: Firebase CLI not found${NC}"
    echo "Install with: npm install -g firebase-tools"
    exit 1
fi

# Verify user is logged in
if ! firebase projects:list &> /dev/null; then
    echo -e "${YELLOW}Not logged in to Firebase. Initiating login...${NC}"
    firebase login
fi

# Set project based on environment
case $ENV in
    dev|development)
        PROJECT="helaservice-dev"
        ;;
    staging)
        PROJECT="helaservice-staging"
        ;;
    prod|production)
        PROJECT="helaservice-prod"
        ;;
    *)
        echo -e "${RED}Error: Unknown environment '$ENV'${NC}"
        echo "Valid environments: dev, staging, prod"
        exit 1
        ;;
esac

echo -e "${BLUE}Using Firebase project: $PROJECT${NC}"
firebase use $PROJECT

echo ""
echo -e "${YELLOW}Step 1/5: Deploying Firestore Rules...${NC}"
firebase deploy --only firestore:rules --project=$PROJECT
echo -e "${GREEN}✓ Firestore Rules deployed${NC}"

echo ""
echo -e "${YELLOW}Step 2/5: Deploying Firestore Indexes...${NC}"
firebase deploy --only firestore:indexes --project=$PROJECT
echo -e "${GREEN}✓ Firestore Indexes deployed${NC}"

echo ""
echo -e "${YELLOW}Step 3/5: Deploying Cloud Functions...${NC}"
cd functions

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

echo "Building TypeScript..."
npm run build

cd ..
firebase deploy --only functions --project=$PROJECT
echo -e "${GREEN}✓ Cloud Functions deployed${NC}"

echo ""
echo -e "${YELLOW}Step 4/5: Deploying Storage Rules...${NC}"
firebase deploy --only storage --project=$PROJECT
echo -e "${GREEN}✓ Storage Rules deployed${NC}"

echo ""
echo -e "${YELLOW}Step 5/5: Deploying Security Rules (if any)...${NC}"
# Add any additional security rules deployment here
echo -e "${GREEN}✓ Security configuration complete${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Deployment Complete!                  ${NC}"
echo -e "${GREEN}  Project: $PROJECT                     ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Deployed Services:${NC}"
echo "  • Firestore Rules"
echo "  • Firestore Indexes"
echo "  • Cloud Functions"
echo "  • Storage Rules"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Verify functions in Firebase Console"
echo "  2. Test payment webhook endpoint"
echo "  3. Check Firestore rules in console"
echo ""
