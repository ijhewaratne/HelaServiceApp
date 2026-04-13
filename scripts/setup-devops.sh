#!/bin/bash

# Phase 6: DevOps & Monitoring Setup Script
# Usage: ./scripts/setup-devops.sh [staging|production]

set -e

ENVIRONMENT=${1:-staging}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔵 HelaService DevOps Setup"
echo "Environment: $ENVIRONMENT"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check Firebase CLI
if ! command -v firebase &> /dev/null; then
    print_error "Firebase CLI not found. Installing..."
    npm install -g firebase-tools
fi
print_status "Firebase CLI installed"

# Check Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js not found. Please install Node.js 20+"
    exit 1
fi
print_status "Node.js installed"

# Check gcloud CLI
if ! command -v gcloud &> /dev/null; then
    print_warning "gcloud CLI not found. Some features may not work."
fi

# Verify Firebase login
echo ""
echo "🔐 Verifying Firebase authentication..."
if ! firebase projects:list > /dev/null 2>&1; then
    print_error "Not authenticated with Firebase"
    echo "Please run: firebase login"
    exit 1
fi
print_status "Firebase authenticated"

# Setup Functions
echo ""
echo "⚙️  Setting up Cloud Functions..."
cd "$PROJECT_ROOT/functions"

if [ ! -d "node_modules" ]; then
    echo "Installing function dependencies..."
    npm ci
fi
print_status "Function dependencies installed"

# Build functions
echo "Building functions..."
npm run build
print_status "Functions built"

# Create backup bucket
echo ""
echo "☁️  Setting up Cloud Storage..."
PROJECT_ID="helaservice-$ENVIRONMENT"
BUCKET_NAME="${PROJECT_ID}-backups"

echo "Creating backup bucket: $BUCKET_NAME"
if gcloud storage buckets describe "gs://$BUCKET_NAME" > /dev/null 2>&1; then
    print_warning "Bucket $BUCKET_NAME already exists"
else
    gcloud storage buckets create "gs://$BUCKET_NAME" \
        --location=ASIA-SOUTH1 \
        --storage-class=STANDARD \
        --enable-versioning
    print_status "Backup bucket created"
fi

# Set bucket lifecycle (30 days retention)
echo "Setting lifecycle policy..."
cat > /tmp/lifecycle.json <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "age": 30,
          "matchesPrefix": ["backups/"]
        }
      }
    ]
  }
}
EOF

gcloud storage buckets update "gs://$BUCKET_NAME" \
    --lifecycle-file=/tmp/lifecycle.json
print_status "Lifecycle policy set (30 days retention)"

# Setup Firebase project
echo ""
echo "🔥 Configuring Firebase project..."
cd "$PROJECT_ROOT"

# Check if project exists
if firebase projects:list | grep -q "$PROJECT_ID"; then
    print_status "Firebase project exists: $PROJECT_ID"
else
    print_error "Firebase project not found: $PROJECT_ID"
    echo "Please create the project first:"
    echo "  firebase projects:create $PROJECT_ID"
    exit 1
fi

# Set default project
firebase use "$PROJECT_ID"
print_status "Default project set to: $PROJECT_ID"

# Deploy Firestore rules and indexes
echo ""
echo "📦 Deploying Firestore configuration..."
firebase deploy --only firestore:rules,firestore:indexes
print_status "Firestore rules and indexes deployed"

# Deploy Storage rules
echo ""
echo "📦 Deploying Storage rules..."
firebase deploy --only storage
print_status "Storage rules deployed"

# Deploy Functions
echo ""
echo "📦 Deploying Cloud Functions..."
firebase deploy --only functions
print_status "Cloud Functions deployed"

# Setup GitHub Actions secrets
echo ""
echo "🔑 GitHub Actions Setup"
echo "------------------------"
echo "Please configure the following secrets in GitHub Repository Settings:"
echo ""
echo "Repository: Settings > Secrets and Variables > Actions"
echo ""

if [ "$ENVIRONMENT" == "staging" ]; then
    echo "Required secrets for STAGING:"
    echo "  - FIREBASE_SERVICE_ACCOUNT_STAGING"
    echo "  - FIREBASE_PROJECT_STAGING"
    echo "  - FIREBASE_APP_ID_STAGING"
    echo "  - FIREBASE_API_KEY_STAGING"
    echo "  - STAGING_KEYSTORE_BASE64"
    echo "  - STAGING_KEYSTORE_PASSWORD"
    echo "  - STAGING_KEY_PASSWORD"
    echo "  - STAGING_KEY_ALIAS"
    echo "  - SLACK_WEBHOOK_URL"
    echo "  - CODECOV_TOKEN"
else
    echo "Required secrets for PRODUCTION:"
    echo "  - FIREBASE_SERVICE_ACCOUNT_PRODUCTION"
    echo "  - FIREBASE_PROJECT_PRODUCTION"
    echo "  - FIREBASE_APP_ID_PRODUCTION"
    echo "  - FIREBASE_API_KEY_PRODUCTION"
    echo "  - PRODUCTION_KEYSTORE_BASE64"
    echo "  - PRODUCTION_KEYSTORE_PASSWORD"
    echo "  - PRODUCTION_KEY_PASSWORD"
    echo "  - PRODUCTION_KEY_ALIAS"
    echo "  - IOS_DISTRIBUTION_CERTIFICATE"
    echo "  - IOS_CERTIFICATE_PASSWORD"
    echo "  - APPSTORE_ISSUER_ID"
    echo "  - APPSTORE_API_KEY_ID"
    echo "  - APPSTORE_API_PRIVATE_KEY"
    echo "  - PLAY_STORE_SERVICE_ACCOUNT"
    echo "  - SLACK_WEBHOOK_URL_PRODUCTION"
    echo "  - PAGERDUTY_KEY"
    echo "  - SENTRY_AUTH_TOKEN"
fi

echo ""
echo "To generate Firebase service account:"
echo "  firebase projects:iamgrant $PROJECT_ID --email firebase-adminsdk@$PROJECT_ID.iam.gserviceaccount.com"
echo ""

# Generate service account key
echo "Generating service account key..."
SERVICE_ACCOUNT="firebase-adminsdk-$(date +%s)@$PROJECT_ID.iam.gserviceaccount.com"

echo "Create service account:"
echo "  gcloud iam service-accounts create $(echo $SERVICE_ACCOUNT | cut -d@ -f1) \\"
echo "    --display-name='GitHub Actions' \\"
echo "    --project=$PROJECT_ID"
echo ""
echo "Grant roles:"
echo "  gcloud projects add-iam-policy-binding $PROJECT_ID \\"
echo "    --member=\"serviceAccount:$SERVICE_ACCOUNT\" \\"
echo "    --role=roles/editor"
echo ""
echo "Create key:"
echo "  gcloud iam service-accounts keys create firebase-key.json \\"
echo "    --iam-account=$SERVICE_ACCOUNT \\"
echo "    --project=$PROJECT_ID"
echo ""
echo "Add to GitHub secrets:"
echo "  cat firebase-key.json | base64 | pbcopy"
if [ "$ENVIRONMENT" == "staging" ]; then
    echo "  # Paste as FIREBASE_SERVICE_ACCOUNT_STAGING"
else
    echo "  # Paste as FIREBASE_SERVICE_ACCOUNT_PRODUCTION"
fi

# Health check
echo ""
echo "🏥 Testing health endpoints..."
sleep 5  # Wait for functions to propagate

HEALTH_URL="https://asia-south1-$PROJECT_ID.cloudfunctions.net/healthCheck"
if curl -sf "$HEALTH_URL" > /dev/null; then
    print_status "Health check endpoint responding"
else
    print_warning "Health check endpoint not yet available"
    echo "  URL: $HEALTH_URL"
fi

PING_URL="https://asia-south1-$PROJECT_ID.cloudfunctions.net/ping"
if curl -sf "$PING_URL" > /dev/null; then
    print_status "Ping endpoint responding"
else
    print_warning "Ping endpoint not yet available"
    echo "  URL: $PING_URL"
fi

# Summary
echo ""
echo "====================================="
echo "✅ DevOps Setup Complete!"
echo "====================================="
echo ""
echo "Next steps:"
echo "  1. Configure GitHub Actions secrets"
echo "  2. Test deployment with a small change"
echo "  3. Set up UptimeRobot monitoring"
echo "  4. Configure Cloud Monitoring alerts"
echo ""
echo "Useful commands:"
echo "  firebase functions:log              # View function logs"
echo "  firebase firestore:indexes          # View Firestore indexes"
echo "  firebase deploy --only functions    # Deploy functions only"
echo ""
echo "Documentation: DEPLOYMENT.md"
echo ""
