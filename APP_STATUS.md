# HelaService App Status

## Current Status: Compilable — Architecture Complete ✅

All `lib/` compilation errors are resolved. The app compiles cleanly.
Remaining analyzer output is warnings/infos in test files (pre-existing mock infrastructure).

---

## Architecture Maturity

| Layer | Status | Notes |
|-------|--------|-------|
| Auth (Phone OTP) | ✅ Complete | Firebase Auth, custom User entity |
| Worker onboarding | ✅ Complete | NIC, photo, contract acceptance |
| Scheduling Engine | ✅ Complete | Recurring bookings, calendar availability |
| Verification Tiers | ✅ Complete | Green → Blue → Gold → Partner state machine |
| Service Catalog | ✅ Complete | 4-layer hierarchy, 3 pricing models |
| Real-time matching | ✅ Complete | Geohash + Haversine, PickMe scoring |
| Wallet & Payments | ✅ Complete | Hold/release/split (80/20), payouts |
| Trust & Safety | ✅ Complete | SOS, missed check-in/out detection |
| Chat | ✅ Complete | Firestore-backed messaging |
| Reviews & Feedback | ✅ Complete | Rating, photo, dispute flow |
| Promos & Referrals | ✅ Complete | Code redemption, reward credits |
| Cloud Functions | ✅ Complete | Dispatch, payouts, safety scans, reminders |
| Firestore indexes | ✅ Complete | All query patterns covered |
| DI container | ✅ Complete | All blocs/repos/use-cases registered |

---

## Features Implemented

### Core Platform
- Clean Architecture with BLoC pattern throughout
- Firebase integration: Auth, Firestore, Storage, Messaging, Analytics, Crashlytics
- Phone OTP authentication with custom User entity
- Role-based routing (customer / worker / admin)
- Offline-first connectivity handling

### Scheduling Engine (`features/scheduling/`)
- `BookingSchedule` — date, time window, duration, timezone
- `RecurrenceRule` — once/weekly/biweekly/monthly, end date, max occurrences
- `WorkerCalendar` — per-weekday availability slots + exception map
- `SchedulingRepository` — Firestore at `workers/{id}/calendar/availability`
- Use cases: `CheckWorkerAvailability`, `FindAvailableWorkers`, `GenerateRecurringBookings`
- `SchedulingBloc` — full event/state coverage

### Worker Verification Tiers (`features/worker/domain/entities/worker_verification.dart`)
- Green (baseline) → Blue (trained) → Gold (certified) → Partner (exclusive zone)
- Checklist per tier, `canPromote` computed getter
- Rate multipliers: 1.0x / 1.1x / 1.25x / 1.40x
- `VerificationBloc` — load, update checklist, promote (mirrors tier to worker doc)

### Service Catalog (`features/service/`)
- `ServiceCatalogItem` — 4-layer hierarchy, 3 pricing models, tier requirements
- Repository with category/children/popular/upsert/watch operations

### Payment Architecture (`features/payment/`, `features/wallet/`)
- `WalletEntity` updated with `heldBalance` and `availableBalance`
- `HoldWalletFunds` / `ReleaseWalletFunds` — atomic Firestore transactions
- `SplitPayment` — release hold + debit + log + create payout in one transaction
- `Payout` entity with `Payout.calculate()` factory (80/20 split)
- `PayoutRepository` + `generateWeeklyPayouts()` batch operation

### Trust & Safety (`features/safety/`)
- `SafetyAlert` — 5 types (missedCheckIn, missedCheckOut, sosPanic, customerReport, locationLost)
- `SafetyRepositoryImpl` — missed check-in/out detection scans
- `SafetyBloc` — SOS trigger, acknowledge, resolve, escalate, `watchOpenAlerts` stream

### Real-Time Matching (`features/matching/`)
- `LocationTrackingService` — geohash + `distanceFilter: 10m` updates
- `FindNearestWorker` — geohash neighbourhood query + Haversine scoring (40/40/20)
- `FindAvailableWorkers` — calendar-aware scheduling-based matching (Layer 1)
- Layer 1 scheduled services use `FindAvailableWorkers`; Layer 2 real-time uses `FindNearestWorker`

### Cloud Functions (`functions/src/`)
- `dispatchJob` — PickMe-style top-3 offer broadcast
- `acceptJob` — race-condition resolver
- `generateRecurringBookings` — triggered on booking confirmation
- `processWeeklyPayouts` — Monday 09:00 Colombo, 80/20 split
- `checkMissedCheckIns` / `checkMissedCheckOuts` — every 30 min safety scans
- `notifyUpcomingBookings` — 24h and 2h reminders
- `autoCompleteBookings` — stalled booking cleanup
- `escalateSafetyAlert` — critical alert to admin push notification
- `payhereWebhook`, `rateLimit`, `referral`, `securityScheduled`, `backup`, `health`

---

## Known Remaining Gaps

| Item | Priority | Notes |
|------|----------|-------|
| PayHere integration | P1 | `flutter_payhere` commented out; REST API wrapper needed |
| Admin dashboard UI | P2 | Safety alerts, payout approval screens not yet built |
| Scheduling UI | P2 | Calendar picker, recurrence selector not yet built |
| Unit tests | P2 | Use-case and BLoC tests for new features needed |
| Integration tests | P2 | End-to-end booking -> payment flow |
| Worker availability UI | P2 | Screen to set WorkerCalendar slots |
| Push notification deep links | P3 | Alert to screen navigation not wired |

---

## To Run The App

```bash
cd /path/to/home_service_app
flutter pub get
flutter run --flavor staging -t lib/main_staging.dart
# or
flutter run --flavor production -t lib/main_production.dart
```

Cloud Functions:
```bash
cd functions && npm install && npm run build
firebase deploy --only functions
```

Firestore indexes:
```bash
firebase deploy --only firestore:indexes
```
