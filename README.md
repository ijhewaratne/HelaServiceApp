# HelaService — Sri Lankan Home Services Platform

> A **PickMe-style dispatch app** for trusted home services in Sri Lanka. Connects customers with verified workers for cleaning, babysitting, elderly care, cooking, laundry, and more — starting in Colombo.

[![Flutter Version](https://img.shields.io/badge/Flutter-3.19+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud%20Functions%20%7C%20Firestore%20%7C%20Auth-DD2C00?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Proprietary-lightgrey)]()

---

## Table of Contents

1. [What is HelaService?](#what-is-helaservice)
2. [System Architecture](#system-architecture)
3. [Project Structure](#project-structure)
4. [Tech Stack](#tech-stack)
5. [Key Features](#key-features)
6. [Getting Started](#getting-started)
7. [Development Workflow](#development-workflow)
8. [Testing](#testing)
9. [Deployment](#deployment)
10. [Security & Compliance](#security--compliance)
11. [Monitoring & Observability](#monitoring--observability)
12. [Documentation](#documentation)
13. [Current Status & Roadmap](#current-status--roadmap)

---

## What is HelaService?

HelaService is a real-time, location-aware marketplace for home services built specifically for Sri Lanka. It brings together three user roles in one platform:

- **Customers** — book services, schedule recurring visits, track workers in real time, and pay securely.
- **Workers** — register, complete tiered verification (Green → Blue → Gold → Partner), go online inside designated service zones, and receive job offers.
- **Admins** — verify workers, manage bookings, handle incidents/disputes, and monitor platform health.

The platform is designed around Sri Lankan operational realities: local phone-number OTP login, NIC validation, Colombo-only geofenced launches, LKR pricing, and PDPA-first data handling.

---

## System Architecture

HelaService follows **Clean Architecture** with a **feature-first** folder layout. Business logic is isolated from framework code, making the codebase testable, scalable, and easy to navigate.

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Presentation Layer                              │
│  Pages / Screens  →  BLoCs / ViewModels  →  Widgets  →  Design System       │
├─────────────────────────────────────────────────────────────────────────────┤
│                               Domain Layer                                   │
│  Entities  →  Repository Contracts  →  Use Cases                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                Data Layer                                    │
│  Repository Implementations  →  Models  →  Remote/Firebase Data Sources      │
├─────────────────────────────────────────────────────────────────────────────┤
│                               Core Layer                                     │
│  DI, Routing, Theme, Constants, Services, Security, Monitoring, Utils        │
├─────────────────────────────────────────────────────────────────────────────┤
│                               Backend Layer                                  │
│  Firebase Auth  →  Firestore  →  Cloud Functions  →  FCM  →  Storage        │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Architecture Principles

| Principle | Implementation |
|-----------|----------------|
| **Separation of Concerns** | Each feature has independent `data`, `domain`, and `presentation` layers. |
| **Dependency Inversion** | Domain defines repository interfaces; data layer implements them. |
| **Single Responsibility** | Use cases encapsulate one business operation (e.g., `FindNearestWorker`). |
| **Reactive State** | BLoCs emit immutable states; UI reacts to state changes. |
| **Firebase-Centric Backend** | Backend communication goes through Firestore, Auth, Cloud Functions, and FCM. |

### State Management

The app uses a **hybrid approach**:

- **`flutter_bloc`** for core business flows with complex state machines: `AuthBloc`, `BookingBloc`, `WorkerBloc`, `PaymentBloc`, `SchedulingBloc`, `SafetyBloc`, `VerificationBloc`, `WorkerOnboardingBloc`, `ChatBloc`, `CustomerBloc`.
- **`provider`** for simpler view-level state and legacy/admin screens: `AdminViewModel`, `CustomerViewModel`, `BookingViewModel`, `WorkerViewModel`, `ThemeProvider`, `LocalizationService`.

### Dependency Injection

`get_it` powers the dependency graph via a global service locator `sl` in `lib/injection_container.dart`:

```dart
// External Firebase SDKs
sl.registerLazySingleton(() => FirebaseFirestore.instance);
sl.registerLazySingleton(() => FirebaseAuth.instance);

// Services
sl.registerLazySingleton(() => LocationService(sl()));
sl.registerLazySingleton(() => NotificationService(sl(), sl()));

// Repositories
sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl(), sl()));
sl.registerLazySingleton<WorkerRepository>(() => WorkerRepositoryImpl(...));

// BLoCs
sl.registerFactory(() => AuthBloc(signIn: sl(), verifyOtp: sl(), ...));
```

### Navigation

`go_router` handles declarative routing with auth guards and role-based redirects:

| Route | Destination |
|-------|-------------|
| `/` | Splash / role detection |
| `/auth` | Phone OTP login |
| `/auth/role-select` | Choose customer/worker/admin |
| `/customer/home` | Customer dashboard |
| `/customer/book` | Booking flow wizard |
| `/customer/track/:jobId` | Live worker tracking |
| `/worker/dashboard` | Worker home |
| `/worker/onboard/nic` | Worker onboarding |
| `/worker/job-offers` | Incoming job offers |
| `/admin/dashboard` | Admin operations center |

### Dispatch / Matching Algorithm

The PickMe-style matching engine scores available workers using three factors:

| Factor | Weight | Purpose |
|--------|--------|---------|
| Distance to customer | 50% | Closer workers rank higher. |
| Idle time | 30% | Workers who finished recently get priority for fair rotation. |
| Home-base proximity | 20% | Prevents stranding workers far from home at end of day. |

Implementation:
- **Client-side:** `FindNearestWorker` use case queries `worker_locations` by geohash neighborhood and scores with the Haversine formula.
- **Server-side:** `dispatchJob` Cloud Function triggers on `job_requests` creation, finds the top 3 workers, writes `job_offers`, and schedules a 30-second timeout.
- **Acceptance:** `acceptJob` callable uses a Firestore transaction — first acceptor wins, others are rejected.

---

## Project Structure

```
HelaServiceApp/
├── android/                    # Android runner, Fastlane, build config
├── ios/                        # iOS runner, Fastlane, build config
├── macos/                      # macOS runner (Firebase plugins registered; macOS unsupported)
├── web/                        # Web entry point, manifest, icons
├── functions/                  # Firebase Cloud Functions (TypeScript)
│   ├── src/                    # Function source code
│   └── package.json            # Node 18 runtime
├── lib/                        # Flutter application
│   ├── app.dart                # MaterialApp, providers, localizations
│   ├── main.dart               # Dev entry point
│   ├── main_staging.dart       # Staging entry point
│   ├── main_production.dart    # Production entry point
│   ├── firebase_options.dart   # Generated Firebase options
│   ├── injection_container.dart # get_it DI registrations
│   ├── core/                   # Cross-cutting concerns
│   │   ├── bloc/               # BLoC performance mixins, observers
│   │   ├── config/             # Theme + GoRouter
│   │   ├── constants/          # App constants, zones, API endpoints, roles
│   │   ├── errors/             # Exceptions, Failures, PaymentFailure
│   │   ├── extensions/         # String, BuildContext, Query extensions
│   │   ├── localization/       # Generated AppLocalizations + locale service
│   │   ├── monitoring/         # Crashlytics, performance, BLoC observer
│   │   ├── performance/        # Frame/scroll performance helpers
│   │   ├── providers/          # Theme provider
│   │   ├── security/           # Encryption service, security config
│   │   ├── services/           # Location, notification, connectivity, analytics
│   │   ├── usecases/           # Base UseCase classes
│   │   ├── utils/              # Validators, geohash, pagination, audit logger, PDPA
│   │   └── widgets/            # Branded widgets, loading, skeleton, error UI
│   ├── features/               # Feature modules
│   │   ├── admin/
│   │   ├── auth/
│   │   ├── booking/
│   │   ├── chat/
│   │   ├── customer/
│   │   ├── feedback/
│   │   ├── incident/
│   │   ├── job/
│   │   ├── matching/
│   │   ├── payment/
│   │   ├── promo/
│   │   ├── referral/
│   │   ├── safety/
│   │   ├── scheduling/
│   │   ├── service/
│   │   ├── splash/
│   │   ├── support/
│   │   └── worker/
│   ├── l10n/                   # ARB translation files (en, si, ta)
│   └── shared/                 # Shared dialogs / common UI
├── test/                       # Unit, BLoC, repository, widget tests
├── integration_test/           # End-to-end integration tests
├── scripts/                    # Build, deploy, QA, emulator helpers
├── docs/                       # Architecture, security, deployment, ops docs
├── monitoring/                 # Firebase monitoring + UptimeRobot config
├── store_assets/               # Privacy policy, terms, store graphics
├── firebase.json               # Firebase project config + emulators
├── firestore.rules             # Firestore security rules
├── storage.rules               # Cloud Storage security rules
├── firestore.indexes.json      # Firestore composite indexes
└── pubspec.yaml                # Flutter package manifest
```

### Feature Module Layout

Every feature follows the same internal structure:

```
lib/features/<feature>/
├── data/
│   ├── models/                 # DTOs / fromJson-toJson classes
│   └── repositories/           # Repository implementations
├── domain/
│   ├── entities/               # Pure business objects
│   ├── repositories/           # Abstract repository contracts
│   └── usecases/               # Business operations
└── presentation/
    ├── bloc/                   # BLoCs, states, events
    ├── viewmodels/             # Provider viewmodels (where used)
    ├── pages/                  # Full screens
    └── widgets/                # Feature-specific widgets
```

---

## Tech Stack

### Mobile / Frontend

| Concern | Package |
|---------|---------|
| Framework | Flutter (Dart SDK `^3.11.0`) |
| State | `flutter_bloc`, `provider`, `equatable` |
| Routing | `go_router` |
| DI | `get_it` |
| Functional types | `dartz` |
| Localization | `flutter_localizations`, `intl` |
| Fonts | `google_fonts` |
| Animations | `flutter_animate` |
| Images | `cached_network_image`, `shimmer`, `loading_indicator` |
| Chat UI | `flutter_chat_ui` |

### Firebase

| Service | Package |
|---------|---------|
| Core | `firebase_core` |
| Auth | `firebase_auth` (Phone OTP) |
| Database | `cloud_firestore` |
| Storage | `firebase_storage` |
| Functions | `cloud_functions` |
| Messaging | `firebase_messaging` |
| Analytics | `firebase_analytics` |
| Crashlytics | `firebase_crashlytics` |
| Performance | `firebase_performance` |
| App Check | `firebase_app_check` |

### Device / Platform

| Concern | Package |
|---------|---------|
| Location | `geolocator`, `geofence_service` |
| Maps | `google_maps_flutter` |
| Images | `image_picker` |
| Notifications | `flutter_local_notifications` |
| Biometrics | `local_auth` |
| Permissions | `permission_handler` |
| Storage | `shared_preferences`, `path_provider` |
| Connectivity | `connectivity_plus` |

### Backend / Cloud Functions

| Concern | Technology |
|---------|------------|
| Runtime | Node.js 18 |
| Language | TypeScript 5 |
| Firebase SDK | `firebase-admin` 11.11, `firebase-functions` 4.5 |
| Geohash | `geofire-common` 6.0 |
| Payments | PayHere (server-side signing + webhook) |
| SMS | Notify.lk |

### DevOps / Testing

| Concern | Tool |
|---------|------|
| CI/CD | GitHub Actions |
| Testing | `flutter_test`, `bloc_test`, `mockito`, `fake_cloud_firestore`, `firebase_auth_mocks` |
| Static analysis | `flutter analyze`, `flutter_lints`, `dart_code_metrics` |
| Secrets / env | `flutter_dotenv` |
| Distribution | Firebase App Distribution, Fastlane |

---

## Key Features

### Authentication
- Firebase Phone OTP using Sri Lankan mobile format (`07XXXXXXXX` / `+94XXXXXXXXX`).
- Role selection persisted to Firestore (`customer`, `worker`, `admin`, `superAdmin`).
- Splash screen routes authenticated users to the correct home based on `userType` and onboarding status.

### Worker Verification Tiers

| Tier | Requirements | Rate Multiplier |
|------|--------------|-----------------|
| **Green** | Basic NIC + selfie + documents | 1.0× |
| **Blue** | Reference checks + background verification | 1.1× |
| **Gold** | Training completion + high reliability score | 1.25× |
| **Partner** | Long-term contract + premium vetting | 1.40× |

### Booking Flow
- 7-step booking wizard: service selection → schedule → address → instructions → review → payment → confirmation.
- Support for one-time and recurring bookings.
- Real-time status machine: `pending` → `confirmed` → `workerAssigned` → `enRoute` → `arrived` → `inProgress` → `completed` / `cancelled`.

### Payments & Wallet
- In-app wallet with `availableBalance` and `heldBalance`.
- Atomic hold/release/split transactions implemented in Cloud Functions.
- Worker payout split: 80% worker, 20% platform fee.
- PayHere server-side URL signing so the merchant secret never reaches the client.

### Safety & Trust
- SOS button triggers FCM + Notify.lk SMS escalation to admins.
- Missed check-in/check-out detection via scheduled Cloud Functions.
- GPS check-in validation within 200 m of service address.
- Auto-suspend workers after two unresolved high/critical safety alerts in 30 days.
- Independent Contractor Agreement digital signature gate before first job.

### Admin Operations
- Worker verification queue.
- Active bookings and manual worker assignment.
- Incident/dispute review.
- Revenue dashboard and payout approval.
- Audit log viewer.

### Localization
- Generated ARB localization for **English**, **Sinhala**, and **Tamil**.
- Runtime locale switching persisted in `SharedPreferences`.

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.11.0` (recommended `3.19.0`)
- Dart SDK `^3.11.0`
- Firebase CLI (`npm install -g firebase-tools`)
- Node.js 18+ (for Cloud Functions)
- Android Studio / Xcode for mobile builds

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/ijhewaratne/HelaServiceApp.git
cd HelaServiceApp

# 2. Install Flutter dependencies
flutter pub get

# 3. Configure environment
cp .env.example .env
# Edit .env with your Firebase keys, PayHere credentials, encryption key, etc.

# 4. Generate localization
dart run intl_utils:generate   # or flutter gen-l10n
```

### Firebase Setup

```bash
# Login and select project
firebase login
firebase use helaservice-dev

# Download native config files and place them in:
#   android/app/google-services.json
#   ios/Runner/GoogleService-Info.plist

# Deploy security rules and indexes
firebase deploy --only firestore:rules,firestore:indexes,storage

# Build and deploy Cloud Functions
cd functions
npm install
npm run build
firebase deploy --only functions
cd ..
```

### Run the App

```bash
# Development with Firebase emulators
flutter run --dart-define=USE_FIREBASE_EMULATOR=true

# Staging
flutter run -t lib/main_staging.dart --flavor staging

# Production
flutter run -t lib/main_production.dart --flavor production
```

### Firebase Emulators (Local Development)

```bash
./scripts/emulators.sh start
```

Default emulator ports:
- Auth: `9099`
- Firestore: `8080`
- Functions: `5001`
- Storage: `9199`
- Emulator UI: `4000`

---

## Development Workflow

### Branch Strategy

| Branch | Environment | CI/CD |
|--------|-------------|-------|
| `feature/*` | Local / dev | Pull-request checks |
| `develop` | Staging | Auto-deploy to Firebase App Distribution |
| `main` | Production | Release-triggered production deploy |

### Code Quality

```bash
# Run static analysis
flutter analyze --fatal-infos

# Format code
dart format --set-exit-if-changed lib test

# Run tests
flutter test --coverage

# Quick QA pass
./scripts/qa_check.sh
```

### Common Commands

```bash
# Build debug APK
flutter build apk --debug

# Build release AAB
flutter build appbundle --release

# Build iOS archive
flutter build ios --release

# Build web
flutter build web --release
```

---

## Testing

The project follows a layered testing strategy:

| Test Type | Location | Tools |
|-----------|----------|-------|
| Unit tests | `test/` | `flutter_test`, `mockito` |
| BLoC tests | `test/features/*/` | `bloc_test`, `mockito` |
| Repository tests | `test/features/*/` | `fake_cloud_firestore`, `firebase_auth_mocks` |
| Widget tests | `test/` | `flutter_test` |
| Integration tests | `integration_test/` | `integration_test` |

### Run Tests

```bash
# All unit/widget tests
flutter test

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Integration tests
flutter test integration_test/app_test.dart

# Using Firebase emulators for integration tests
firebase emulators:exec --only firestore,auth "flutter test integration_test/"
```

### Coverage Targets

| Layer | Target |
|-------|--------|
| Domain | ≥ 90% |
| Data | ≥ 80% |
| Presentation | ≥ 70% |
| Overall | ≥ 75% |

---

## Deployment

### Environments

| Environment | Firebase Project | Branch | Entry Point |
|-------------|------------------|--------|-------------|
| Development | `helaservice-dev` | `feature/*` | `lib/main.dart` |
| Staging | `helaservice-staging` | `develop` | `lib/main_staging.dart` |
| Production | `helaservice-prod` | `main` | `lib/main_production.dart` |

### Deploy to Staging

```bash
./scripts/deploy.sh staging
```

This runs analyze, test, build, Firebase resource deploy, and uploads to Firebase App Distribution.

### Deploy to Production

```bash
./scripts/deploy.sh production
```

Production deploy builds AAB/IPA, uploads to Play Store Internal / App Store Connect, deploys Firebase resources, and creates a git tag.

### Manual Firebase Deploy

```bash
./scripts/deploy-firebase.sh dev|staging|prod
```

---

## Security & Compliance

### PDPA (Personal Data Protection Act)

- Sensitive fields (NIC, bank details, home location) encrypted with AES-256.
- Customer addresses stored as `houseNumber` + `landmark` only until dispatch.
- Worker private data isolated in subcollections with strict Firestore rules.
- Chat messages deleted after 30 days via GCP TTL.
- Medical data storage explicitly blocked.

### Firebase App Check

- Android production: Google Play Integrity API.
- iOS production: DeviceCheck / App Attest.
- Development: Debug providers.

### Rate Limiting (Cloud Functions)

| Operation | Limit | Window |
|-----------|-------|--------|
| OTP | 3 | 1 minute |
| Job creation | 10 | 1 minute |
| Search | 30 | 1 minute |
| Feedback | 5 | 1 hour |
| General API | 100 | 1 minute |

### Input Validation

Centralized validators cover NIC, phone, email, name, address, amount, OTP, password, with sanitization helpers to prevent XSS/injection.

---

## Monitoring & Observability

### Firebase Analytics

Tracked events: `sign_up`, `login`, `booking_created`, `booking_cancelled`, `job_completed`, `payment_success`, `payment_failed`, `worker_status_changed`, `job_offer_received`, `service_selected`, `chat_message_sent`, `app_error`.

### Crashlytics & Performance

- Fatal crashes and non-fatal BLoC errors reported to Crashlytics.
- Custom traces: `booking_flow`, `worker_dispatch`, `payment_processing`, `search_workers`, `chat_load`.

### Cloud Monitoring Alerts

Configured in `monitoring/firebase-monitoring.yaml`:
- Function error rate > 5% → ERROR
- Function P99 latency > 2s → WARNING
- Failed logins > 100/min → CRITICAL

### Uptime Monitoring

`monitoring/uptimerobot.yaml` configures health-check endpoints:
- `/healthCheck` — comprehensive system health
- `/ping` — uptime ping
- `/ready` — readiness probe
- `/live` — liveness probe

---

## Documentation

| Document | Description |
|----------|-------------|
| [APP_STATUS.md](APP_STATUS.md) | Current build/test/launch status |
| [CHECKLIST.md](CHECKLIST.md) | Pre-launch checklist |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Deployment overview |
| [FIREBASE.md](FIREBASE.md) | Firebase-specific setup |
| [LAUNCH_READINESS.md](LAUNCH_READINESS.md) | Launch readiness assessment |
| [docs/CLOUD_FUNCTIONS.md](docs/CLOUD_FUNCTIONS.md) | Cloud Functions reference |
| [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) | Detailed deployment guide |
| [docs/SECURITY_HARDENING.md](docs/SECURITY_HARDENING.md) | Security hardening steps |
| [docs/SECURITY_RULES.md](docs/SECURITY_RULES.md) | Firestore/Storage rules explained |
| [docs/PERFORMANCE_OPTIMIZATION.md](docs/PERFORMANCE_OPTIMIZATION.md) | Performance tuning |
| [docs/MONITORING.md](docs/MONITORING.md) | Monitoring setup |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common issues |
| [docs/STORE_PREPARATION.md](docs/STORE_PREPARATION.md) | Play Store / App Store prep |
| [docs/PRIVACY_POLICY.md](docs/PRIVACY_POLICY.md) | Privacy policy |
| [docs/TERMS_OF_SERVICE.md](docs/TERMS_OF_SERVICE.md) | Terms of service |

---

## Current Status & Roadmap

### Completed ✅
- Clean Architecture scaffold with feature-first layout
- Firebase integration (Auth, Firestore, Functions, Storage, Messaging, Analytics, Crashlytics, Performance, App Check)
- Phone OTP authentication and role selection
- Worker onboarding, verification tiers, and document upload
- Customer booking flow, live tracking, and reviews
- PickMe-style dispatch / matching algorithm
- Scheduling engine with recurring bookings
- Wallet/payment domain with hold/release/split logic
- Safety module with SOS and missed check-in detection
- Cloud Functions backend (49 functions)
- Firestore security rules, indexes, and storage rules
- DI container, localization, theming, and core widgets
- Comprehensive test suite and CI/CD pipelines

### In Progress / Remaining Before Launch ⚠️

| Item | Priority | Notes |
|------|----------|-------|
| PayHere integration | P1 | `flutter_payhere` is commented out; REST API wrapper or re-enablement needed. |
| Firebase API key rotation | P1 | Old API keys are in git history; regenerate before production. |
| Bundle ID alignment | P1 | Align `com.example.home_service_app` with Fastlane's `com.helaservice.app` / `lk.helaservice.app`. |
| Android release signing | P1 | Production keystore needed in `android/app/build.gradle.kts`. |
| Admin dashboard UI | P2 | Safety alerts, payout approval, verification screens incomplete. |
| Scheduling/availability UI | P2 | Calendar picker, recurrence selector, worker slot editor not built. |
| Test failures | P2 | 42 tests still failing; coverage ~25% vs 80% target. |
| Push notification deep links | P3 | Alert-to-screen navigation not wired. |
| macOS Firebase support | P3 | `firebase_options.dart` throws `UnsupportedError` for macOS. |

### Quality Metrics

| Metric | Status |
|--------|--------|
| Compilation | ✅ Clean (0 errors) |
| Static analysis | ~460 warnings/infos |
| Tests | 210 passing / 42 failing |
| Coverage | ~25% (target 80%) |
| Launch readiness | ~65% |

---

## License

Proprietary — All rights reserved.

---

<p align="center">Built for Sri Lanka. 🏠🇱🇰</p>
