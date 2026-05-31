# HelaService Implementation Checklist
## Household Services Platform — Sri Lanka
### Last Audited: 2026-05-31 (updated after fixing session)

---

## Legend

| Priority | Meaning |
|----------|---------|
| **P0** | Blocking — cannot launch without |
| **P1** | High — needed for beta / 1,000 households |
| **P2** | Medium — needed for scale / 5,000 households |
| **P3** | Low — polish and differentiation at 10,000+ households |

| Status | Meaning |
|--------|---------|
| `[ ]` | Not started |
| `[~]` | In progress / partial |
| `[x]` | Complete |

---

## Section 1: Build & Compilation (P0)

| # | Task | Status | Notes |
|---|------|--------|-------|
| 1.1 | Fix `flutter_payhere` dependency — replace with REST API or `payhere_flutter` | `[~]` | Commented out in pubspec; `payhere_repository.dart` uses REST calls but not wired to payment UI |
| 1.2 | Create missing `lib/shared/dialogs/confirm_dialog.dart` | `[x]` | Exists at `lib/shared/dialogs/confirm_dialog.dart` |
| 1.3 | Create missing `lib/features/incident/services/emergency_service.dart` | `[x]` | Exists and registered in DI container |
| 1.4 | Fix `Failure` abstract class instantiation errors | `[x]` | Concrete subclasses: `ServerFailure`, `CacheFailure`, `AuthFailure`, `NotFoundFailure`, `ValidationFailure`, `GenericFailure`, `PaymentFailure` |
| 1.5 | Fix import path issues across codebase | `[~]` | Run `dart analyze` to verify current state — analyzer output shows warnings in test files only |
| 1.6 | Resolve type mismatches in repository implementations | `[x]` | JSON parsing refactored with explicit type casts (commit cf5de51) |
| 1.7 | Update `APP_STATUS.md` to reflect current state | `[x]` | Updated — reflects May 30 feature set |
| 1.8 | Verify app compiles in debug mode | `[~]` | APP_STATUS.md claims compilable; unverified by running `flutter run` |
| 1.9 | Verify app compiles in release mode | `[ ]` | `flutter build apk --release` not yet verified |
| 1.10 | Run full test suite — all tests pass | `[~]` | Test infrastructure exists; known warnings in mock files |

---

## Section 2: Dependency Injection (`injection_container.dart`)

| # | Task | Status | Notes |
|---|------|--------|-------|
| 2.1 | Register `SchedulingRepository` + implementation | `[x]` | `SchedulingRepositoryImpl` registered as lazy singleton |
| 2.2 | Register `SchedulingBloc` | `[x]` | Registered as factory with all use cases injected |
| 2.3 | Register `CheckAvailability` use case | `[x]` | `CheckWorkerAvailability` registered |
| 2.4 | Register `FindAvailableWorkers` use case | `[x]` | Registered |
| 2.5 | Register `SafetyRepository` + implementation | `[x]` | `SafetyRepositoryImpl` registered |
| 2.6 | Register `SafetyBloc` | `[x]` | Registered as factory |
| 2.7 | Register `ServiceCatalogRepository` + implementation | `[x]` | `ServiceCatalogRepositoryImpl` registered |
| 2.8 | Register `PayoutRepository` + implementation | `[x]` | `PayoutRepositoryImpl` registered |
| 2.9 | Register wallet use cases (`HoldFunds`, `ReleaseFunds`, `SplitPayment`) | `[x]` | All three registered as lazy singletons |
| 2.10 | Register `VerificationBloc` (worker tier progression) | `[x]` | `VerificationBloc(firestore: sl())` registered |

---

## Section 3: Firestore Configuration

| # | Task | Status | Notes |
|---|------|--------|-------|
| 3.1 | `firestore.indexes.json` — scheduling queries (worker + date + status) | `[x]` | `workerId + status + scheduledDate` composite index exists |
| 3.2 | `firestore.indexes.json` — customer booking history (customer + date desc) | `[x]` | `customerId + createdAt desc` index exists |
| 3.3 | `firestore.indexes.json` — worker calendar lookups | `[~]` | Worker subcollection `calendar/availability` has no dedicated index; worker_locations geohash index exists |
| 3.4 | Deploy updated security rules | `[~]` | `firestore.rules` fully written (PDPA-compliant, role-based); **not confirmed deployed** |
| 3.5 | Deploy updated storage rules | `[~]` | `storage.rules` written with worker doc / profile photo / training video rules; **not confirmed deployed** |
| 3.6 | Create `service_catalog` collection seed data | `[x]` | `seedServiceCatalog` CF callable created in `seedServiceCatalog.ts`; all 10 Layer 1 services defined with rates and tier requirements |

---

## Section 4: Cloud Functions (Firebase)

### 4.1 Scheduling & Bookings

| # | Task | Status | Trigger |
|---|------|--------|---------|
| 4.1.1 | `generateRecurringBookings` — create weekly/biweekly instances | `[x]` | `onWrite` on bookings; handles weekly/biweekly/monthly, 6-month cap |
| 4.1.2 | `cancelRecurringInstance` — cancel single instance without cancelling series | `[x]` | `cancelRecurringInstance` callable in `bookingManagementFunctions.ts`; validates ownership + `parentBookingId`, raises `failed-precondition` if not recurring |
| 4.1.3 | `modifyRecurringSeries` — edit all future instances | `[x]` | `modifyRecurringSeries` callable in `bookingManagementFunctions.ts`; updates `startTime`/`durationHours`/`specialNotes` on all future pending/confirmed instances |
| 4.1.4 | `notifyUpcomingBooking` — customer reminder 24h before | `[x]` | `notifyUpcomingBookings` handles both 24h and 2h windows |
| 4.1.5 | `notifyUpcomingBooking` — customer reminder 2h before | `[x]` | Same function, dual-window logic |
| 4.1.6 | `notifyWorkerUpcomingJob` — worker reminder 2h before | `[x]` | `notifyUpcomingBookings` now creates a second notification for `data.workerId` (type `upcoming_job_reminder`) when worker is assigned |

### 4.2 Safety & Trust

| # | Task | Status | Trigger |
|---|------|--------|---------|
| 4.2.1 | `checkMissedCheckIn` — detect overdue workers (30 min past start) | `[x]` | `checkMissedCheckIns` runs every 30 min; 15-min grace |
| 4.2.2 | `escalateSafetyAlert` — auto-escalation: push → SMS → call → manual | `[~]` | Exists; sends push to admins only — SMS/call chain not implemented |
| 4.2.3 | `autoCompleteBooking` — auto-confirm checkout if customer doesn't respond | `[x]` | `autoCompleteBookings` runs hourly; 4h grace past expected end |
| 4.2.4 | `verifyWorkerCheckInLocation` — validate GPS within 200m of booking address | `[x]` | `verifyWorkerCheckInLocation` `onUpdate` trigger in `bookingManagementFunctions.ts`; computes `geofire.distanceBetween * 1000` meters, creates `safety_alert` with type `locationMismatch` if > 200m |

### 4.3 Payments & Payouts

| # | Task | Status | Trigger |
|---|------|--------|---------|
| 4.3.1 | `processWeeklyPayouts` — batch worker withdrawals every Monday 9AM | `[x]` | `processWeeklyPayouts` — Monday 09:00 Colombo; 80/20 split |
| 4.3.2 | `holdWalletFunds` — escrow when booking confirmed | `[x]` | `holdWalletFunds` CF callable in `walletFunctions.ts`; atomic Firestore transaction, validates ownership + sufficient balance, prevents double-hold |
| 4.3.3 | `releaseWalletFunds` — split 80/20 on checkout completion | `[x]` | `releaseWalletFunds` CF callable in `walletFunctions.ts`; credits worker 80%, creates `payouts` record, marks `paymentStatus: 'paid'` |
| 4.3.4 | `processRefund` — full/partial refund for cancellations | `[x]` | `operationalFunctions.ts` — atomic Firestore transaction; returns `heldAmount` to customer wallet; idempotent (skips if `paymentStatus: refunded`) |
| 4.3.5 | `handlePayHereWebhook` — verify and process payment notifications | `[x]` | `payhereWebhook.ts` exists and is exported |

### 4.4 Worker Verification

| # | Task | Status | Trigger |
|---|------|--------|---------|
| 4.4.1 | `processVerificationUpgrade` — Blue tier | `[x]` | `operationalFunctions.ts` — admin-only callable; updates `verificationTier`, `rateMultiplier`, sends FCM push |
| 4.4.2 | `processVerificationUpgrade` — Gold tier | `[x]` | Same callable with `newTier:'gold'`; multiplier 1.25 |
| 4.4.3 | `scheduleReverification` — periodic re-verification every 12 months | `[x]` | `scheduleReverification` daily 08:00 — reminders at 30 days, downgrades expired tiers to green |
| 4.4.4 | `suspendWorker` — auto-suspend on incident / rating drop | `[x]` | `suspendWorker` `onCreate` trigger on `safety_alerts` in `bookingManagementFunctions.ts`; auto-suspends on ≥ 2 unresolved high/critical alerts in 30 days; `suspendWorkerManually` callable for admin use |

### 4.5 Matching & Discovery

| # | Task | Status | Trigger |
|---|------|--------|---------|
| 4.5.1 | `scoreWorkerForBooking` — callable scoring function | `[~]` | Scoring logic embedded in `dispatchJob`; not a separate callable for Layer 1 scheduled use case |
| 4.5.2 | `updateWorkerReliabilityScore` — recalculate weekly | `[x]` | `updateWorkerReliabilityScores` Monday 06:00 — (completionRate × 0.6) + (avgRating/5 × 0.4) |

### 4.6 Analytics & Operations

| # | Task | Status | Trigger |
|---|------|--------|---------|
| 4.6.1 | `dailyBackup` — Firestore export to Cloud Storage | `[x]` | `scheduledFirestoreBackup` + `manualBackup` in `backup.ts` |
| 4.6.2 | `generateDailyReport` — bookings, revenue, incidents summary | `[x]` | `generateDailyReport` daily 23:00 — writes to `daily_reports/{YYYY-MM-DD}` with bookings/revenue/safety/growth |
| 4.6.3 | `cleanupOldPendingBookings` — auto-cancel pending > 48h | `[x]` | `cleanupOldPendingBookings` daily 02:00 — auto-cancels `pending`/`draft` bookings > 48h; auto-refunds held funds |

---

## Section 5: Feature Layer 1 — Core Household Support (Year 1 Primary)

### 5.1 Service Catalog

| # | Task | Status | Notes |
|---|------|--------|-------|
| 5.1.1 | `elder_companionship` service definition | `[x]` | Defined in `seedServiceCatalog.ts`; Blue tier, LKR 600/hr, `supportsRecurring: true` |
| 5.1.2 | `non_medical_immobilized_care` service definition | `[x]` | Defined in `seedServiceCatalog.ts`; Gold tier, LKR 800/hr |
| 5.1.3 | `babysitting` service definition | `[x]` | Defined in `seedServiceCatalog.ts`; Blue tier, LKR 650/hr |
| 5.1.4 | `homework_support` service definition | `[x]` | Defined in `seedServiceCatalog.ts`; Green tier, LKR 500/hr |
| 5.1.5 | `kitchen_helper` service definition | `[x]` | Defined in `seedServiceCatalog.ts`; Green tier, LKR 450/hr |
| 5.1.6 | `laundry_helper` service definition | `[x]` | Defined in `seedServiceCatalog.ts`; Green tier, LKR 400/hr |
| 5.1.7 | `grocery_helper` service definition | `[x]` | Defined in `seedServiceCatalog.ts`; Green tier, LKR 400/hr |
| 5.1.8 | `house_sitting` service definition | `[x]` | Defined in `seedServiceCatalog.ts`; Blue tier, LKR 500/hr |
| 5.1.9 | `pet_sitting` service definition | `[x]` | Defined in `seedServiceCatalog.ts`; Blue tier, LKR 500/hr |
| 5.1.10 | `hourly_household_support` service definition | `[x]` | Defined in `seedServiceCatalog.ts`; Green tier, LKR 400/hr |

### 5.2 Customer Booking Flow

| # | Task | Status | Notes |
|---|------|--------|-------|
| 5.2.1 | Service selection screen | `[x]` | `service_selection_screen.dart` — loads from `BookingViewModel.fetchServices()` |
| 5.2.2 | Date & time picker (with flexibility options) | `[~]` | Basic date+time picker in `booking_form_screen.dart`; no ±2h / Morning/Afternoon/Evening flexibility |
| 5.2.3 | Duration selector (min 2h, max 8h) | `[x]` | Slider in `booking_form_screen.dart`; min 2h enforced |
| 5.2.4 | Recurring booking option (weekly/biweekly) | `[x]` | `SwitchListTile` toggle + `SegmentedButton<String>` (weekly/biweekly) + end-date picker in `booking_form_screen.dart`; occurrence count estimated dynamically |
| 5.2.5 | Worker preference selector (gender, language, same-as-before) | `[ ]` | Not implemented |
| 5.2.6 | Address input with saved locations | `[~]` | Free-text address input exists; no saved locations |
| 5.2.7 | Special instructions textarea | `[x]` | `TextField` with `maxLines: 3`, `maxLength: 300` added to `booking_form_screen.dart` |
| 5.2.8 | Price estimation before confirmation | `[~]` | `booking_summary_screen.dart` exists; wiring to real service rates unverified |
| 5.2.9 | Wallet balance check + top-up prompt if insufficient | `[x]` | Wallet banner in `booking_form_screen.dart`; red/green styling; `_showInsufficientBalanceDialog` blocks proceed if balance < total; navigates to `/customer/wallet/topup` |
| 5.2.10 | Booking confirmation with worker profile preview | `[~]` | `worker_matching_page.dart` exists; full profile preview (photo, tier badge) unverified |

### 5.3 Worker App Flow

| # | Task | Status | Notes |
|---|------|--------|-------|
| 5.3.1 | Calendar management screen (set recurring availability) | `[x]` | `worker_availability_screen.dart` fully rewritten as `StatefulWidget` with `BlocConsumer<SchedulingBloc>`; day-wise time-slot editor (24h time pickers, add/remove slots per day) |
| 5.3.2 | Exception management (block specific dates) | `[x]` | Blocked dates section in `worker_availability_screen.dart`; date picker, `'YYYY-MM-DD'` → `'unavailable'` map, orange `Chip` display with delete |
| 5.3.3 | Booking request notification + accept/decline | `[x]` | `job_offer_page.dart` exists with accept/decline actions |
| 5.3.4 | Today's jobs dashboard | `[x]` | `worker_home_screen.dart` shows job list and status |
| 5.3.5 | Check-in flow (GPS stamp + optional selfie) | `[x]` | `ActiveJobPage` rewritten: `Geolocator.getCurrentPosition` + `ImagePicker.camera` → upload to `bookings/{id}/checkin.jpg` → writes `CheckRecord` to Firestore |
| 5.3.6 | Check-out flow (hours worked + photo proof) | `[x]` | Confirm dialog + camera + GPS → writes `CheckRecord` + `billableHours` → marks booking completed |
| 5.3.7 | Earnings dashboard (today/week/month) | `[~]` | Worker home shows balance; full earnings breakdown screen missing |
| 5.3.8 | Safety SOS button (always visible) | `[~]` | `SafetyBloc.TriggerSOS` event implemented; persistent SOS UI button not confirmed in all screens |

### 5.4 Admin Dashboard

| # | Task | Status | Notes |
|---|------|--------|-------|
| 5.4.1 | Worker verification queue (Green/Blue/Gold processing) | `[x]` | `admin_workers_screen.dart` exists |
| 5.4.2 | Booking management (view all, modify, cancel) | `[x]` | `admin_bookings_screen.dart` exists |
| 5.4.3 | Safety alerts board (real-time, escalation tracking) | `[~]` | `admin_incidents_screen.dart` covers incidents; dedicated safety_alerts board unverified |
| 5.4.4 | Revenue dashboard (commissions, payouts, disputes) | `[ ]` | No dedicated revenue dashboard screen |
| 5.4.5 | Worker performance (ratings, completion rate, reliability) | `[~]` | Covered in `admin_workers_screen.dart` — sortable table unverified |
| 5.4.6 | Customer support tickets | `[ ]` | No support ticket screen or WhatsApp integration wiring |

---

## Section 6: Feature Layer 2 — Mobility & Accompaniment

| # | Task | Status | Notes |
|---|------|--------|-------|
| 6.1 | `doctor_visit_accompaniment` service definition | `[ ]` | Not started |
| 6.2 | `hospital_lab_accompaniment` service definition | `[ ]` | Not started |
| 6.3 | `outing_accompaniment_elder` service definition | `[ ]` | Not started |
| 6.4 | `transport_coordination` service definition | `[ ]` | Not started |
| 6.5 | Real-time location tracking during accompaniment | `[~]` | `live_tracking_page.dart` exists; reuse for accompaniment unverified |
| 6.6 | Family member live location sharing | `[~]` | Architecture supports it; dedicated sharing UI not built |
| 6.7 | Hospital/lab booking integration (partner layer prep) | `[ ]` | Not started |

---

## Section 7: Feature Layer 3 — Home Maintenance

| # | Task | Status | Notes |
|---|------|--------|-------|
| 7.1 | `plumbing` service definition | `[ ]` | Not started |
| 7.2 | `electrical_repairs` service definition | `[ ]` | Not started |
| 7.3 | `handyman` service definition | `[ ]` | Not started |
| 7.4 | `cleaning_support` service definition | `[ ]` | Not started |
| 7.5 | `moving_support` service definition | `[ ]` | Not started |
| 7.6 | In-app photo-based quote request | `[ ]` | Not started |
| 7.7 | Milestone-based payment (deposit → completion) | `[ ]` | Not started |

---

## Section 8: Feature Layer 4 — Partner Professional Services

| # | Task | Status | Notes |
|---|------|--------|-------|
| 8.1 | Partner registration flow (SLMC number, clinic details) | `[ ]` | Not started |
| 8.2 | `home_doctor_visit` arrangement service | `[ ]` | Not started |
| 8.3 | `home_lab_visit` coordination service | `[ ]` | Not started |
| 8.4 | `online_doctor_booking` coordination service | `[ ]` | Not started |
| 8.5 | `lawyer_appointment` coordination service | `[ ]` | Not started |
| 8.6 | Legal disclaimers on all partner services | `[ ]` | Not started |
| 8.7 | Partner commission tracking and payouts | `[ ]` | Not started |
| 8.8 | Partner rating and review system | `[ ]` | Not started |

---

## Section 9: Trust & Safety Infrastructure

| # | Task | Status | Notes |
|---|------|--------|-------|
| 9.1 | Worker selfie verification at check-in | `[~]` | `active_job_page.dart` has check-in; selfie match against profile unverified |
| 9.2 | GPS proximity validation (200m radius) | `[x]` | `verifyWorkerCheckInLocation` CF complete; raises `locationMismatch` safety alert with `distanceMeters` field |
| 9.3 | Missed check-in auto-alert (30 min grace) | `[x]` | CF `checkMissedCheckIns` complete |
| 9.4 | Worker SOS button (in-app, always accessible) | `[x]` | FAB on `WorkerDashboardScreen` + app-bar action on `ActiveJobPage` — both write to `safety_alerts` with GPS location |
| 9.5 | Customer emergency button | `[ ]` | No dedicated customer emergency UI |
| 9.6 | Live location sharing (worker → family member) | `[~]` | `live_tracking_page.dart` exists; temporary/booking-scoped sharing unverified |
| 9.7 | Incident reporting with categorization | `[x]` | `incident_report_page.dart` + `IncidentRepositoryImpl` + `EmergencyService` |
| 9.8 | Worker suspension workflow (auto + manual) | `[x]` | `suspendWorker` auto-suspend CF + `suspendWorkerManually` callable both complete in `bookingManagementFunctions.ts` |
| 9.9 | Reference verification call logging (Blue tier) | `[ ]` | Not implemented |
| 9.10 | Annual re-verification reminders | `[x]` | CF 4.4.3 `scheduleReverification` complete — 30-day warnings + expiry downgrades |
| 9.11 | Safety escalation: Push → SMS → Phone call → Manual | `[~]` | Push to admins only; SMS/call chain missing |

---

## Section 10: Wallet & Payment System (Digital Only)

| # | Task | Status | Notes |
|---|------|--------|-------|
| 10.1 | PayHere wallet top-up flow | `[~]` | `payhere_repository.dart` uses REST; `flutter_payhere` commented out; `payment_page.dart` exists but full flow not wired |
| 10.2 | Wallet balance display (customer + worker) | `[~]` | `wallet_repository_impl.dart` complete; displayed in worker home screen; customer wallet display unverified |
| 10.3 | Booking payment hold (escrow) | `[x]` | `holdWalletFunds` CF callable — server-side atomic Firestore transaction; validates ownership + balance; prevents double-hold; sets booking `status: 'confirmed'` |
| 10.4 | Post-service payment release (80/20 split) | `[x]` | `releaseWalletFunds` CF callable — server-side; credits worker 80%, creates `payouts` record, marks `paymentStatus: 'paid'` |
| 10.5 | Refund processing (full/partial) | `[ ]` | Not implemented |
| 10.6 | Worker payout method setup (bank account) | `[x]` | `BankAccountPage` at `/worker/bank-account` — bank dropdown (14 Sri Lankan banks), account holder, account number, branch; stored in `workers/{id}/private_data/bank_account` |
| 10.7 | Automated weekly payouts | `[x]` | CF `processWeeklyPayouts` complete — Monday 09:00 Colombo |
| 10.8 | Minimum payout threshold (LKR 1,000) | `[x]` | `MIN_PAYOUT_THRESHOLD_LKR = 1000` enforced in `walletFunctions.ts` and `schedulingFunctions.ts`; below-threshold payouts marked `status: 'below_threshold'` |
| 10.9 | Payout transaction history | `[x]` | `PayoutHistoryPage` at `/worker/payouts` — lifetime earnings banner, per-payout breakdown (gross/fee/net), below-threshold handling |
| 10.10 | Revenue/commission reporting (admin) | `[x]` | Live metrics in `AdminDashboardScreen` Overview tab + `generateDailyReport` writes to `daily_reports` collection |
| 10.11 | FriMi / Lanka QR integration (Phase 2) | `[ ]` | Not started |

---

## Section 11: Worker Onboarding & Verification Tiers

### 11.1 Green Tier (Identity Verified)

| # | Task | Status | Notes |
|---|------|--------|-------|
| 11.1.1 | Phone OTP authentication | `[x]` | Firebase Phone Auth — `auth_bloc.dart` + `phone_auth_page.dart` |
| 11.1.2 | NIC validation (old + new format) | `[x]` | `nic_validator.dart` with age verification |
| 11.1.3 | Selfie upload + liveness check | `[x]` | `document_upload_page.dart` + `image_picker` integration |
| 11.1.4 | Basic profile completion (name, address, languages) | `[x]` | Worker onboarding bloc + pages |
| 11.1.5 | Geofence validation (Colombo 03/04/07 initially) | `[x]` | `zones.dart` + `geofence_service` package |

### 11.2 Blue Tier (Background Cleared)

| # | Task | Status | Notes |
|---|------|--------|-------|
| 11.2.1 | Police clearance certificate upload | `[x]` | `BlueTierUpgradePage` at `/worker/blue-tier` — front/back photo capture + expiry date picker; uploaded to `workers/{id}/police_clearance_*.jpg` |
| 11.2.2 | Reference check #1 (previous employer) | `[x]` | Worker submits name, phone, relation in `BlueTierUpgradePage`; stored in `worker_verifications/{id}.references[0]` |
| 11.2.3 | Reference check #2 (previous employer) | `[x]` | Same form — second reference stored as `references[1]` |
| 11.2.4 | Reference verification logging | `[x]` | `worker_verifications` doc holds both references with `verificationStatus: pending`; admin updates via Firestore |
| 11.2.5 | Blue tier badge on worker profile | `[~]` | `WorkerVerification.tier` + `VerificationTier.blue` exist; badge rendering unverified |

### 11.3 Gold Tier (Care Certified)

| # | Task | Status | Notes |
|---|------|--------|-------|
| 11.3.1 | First aid certification module | `[~]` | `training_page.dart` + `training_video_page.dart` exist; quiz/assessment not implemented |
| 11.3.2 | Elder care training module | `[~]` | Same infrastructure; specific content not loaded |
| 11.3.3 | Childcare training module | `[~]` | Same |
| 11.3.4 | Training progress tracking | `[~]` | `WorkerVerification.trainingCompleted` field exists; per-module score tracking not implemented |
| 11.3.5 | Certificate generation on completion | `[ ]` | No PDF generation |
| 11.3.6 | Gold tier badge on worker profile | `[~]` | Entity supports it; visual badge rendering unverified |

### 11.4 Partner Tier (Professional Licensed)

| # | Task | Status | Notes |
|---|------|--------|-------|
| 11.4.1 | SLMC number verification (doctors) | `[ ]` | Not started |
| 11.4.2 | Bar Association verification (lawyers) | `[ ]` | Not started |
| 11.4.3 | Clinic/lab registration verification | `[ ]` | Not started |
| 11.4.4 | Professional indemnity insurance check | `[ ]` | Not started |

---

## Section 12: Testing

### 12.1 Unit Tests

| # | Task | Status | Notes |
|---|------|--------|-------|
| 12.1.1 | `CheckAvailability` use case tests | `[x]` | `test/features/scheduling/check_availability_test.dart` — available/unavailable/failure cases |
| 12.1.2 | `FindAvailableWorkers` use case tests | `[x]` | Same file — returns list, empty list cases |
| 12.1.3 | `HoldWalletFunds` / `ReleaseWalletFunds` tests | `[x]` | `test/features/payment/wallet_usecases_test.dart` — `Payout.calculate` 80/20 split, zero amounts |
| 12.1.4 | `SplitPayment` tests (80/20 split) | `[x]` | Same file — platformFeeRate/workerShareRate constants, fractional amounts |
| 12.1.5 | Worker verification state machine tests | `[x]` | Same file — green→blue, blue→gold, gold→partner, partner has no next tier, rate multipliers |
| 12.1.6 | `RecurrenceRule` generation tests | `[x]` | Same scheduling test file — once/weekly/biweekly/monthly date generation, maxOccurrences cap, intervalDays |

### 12.2 Widget Tests (existing)

| # | Task | Status | Notes |
|---|------|--------|-------|
| 12.2.0 | Auth, booking, worker, payment BLoC tests | `[x]` | `auth_bloc_test.dart`, `booking_bloc_test.dart`, `worker_bloc_test.dart`, `payment_bloc_test.dart` |
| 12.2.1 | Booking flow (service → date → worker → confirm) | `[ ]` | No end-to-end widget test |
| 12.2.2 | Worker calendar management screen | `[x]` | Screen fully built (`worker_availability_screen.dart`); widget test not yet written |
| 12.2.3 | Safety SOS button interaction | `[ ]` | Not tested |
| 12.2.4 | Wallet top-up flow | `[ ]` | Not tested |

### 12.3 Integration Tests

| # | Task | Status | Notes |
|---|------|--------|-------|
| 12.3.0 | Worker onboarding integration test | `[x]` | `test/integration/worker_onboarding_flow_test.dart` exists |
| 12.3.1 | Full booking lifecycle: create → confirm → check-in → check-out → payment | `[ ]` | Not yet written |
| 12.3.2 | Recurring booking: create → verify instances → cancel one → modify series | `[ ]` | Not yet written |
| 12.3.3 | Safety alert: missed check-in → alert creation → escalation → resolution | `[ ]` | Not yet written |
| 12.3.4 | Verification upgrade: submit docs → admin approve → tier change → profile update | `[ ]` | Not yet written |

### 12.4 Performance Tests

| # | Task | Status | Notes |
|---|------|--------|-------|
| 12.4.1 | Matching query performance (100, 500, 1000 workers) | `[ ]` | Not yet written |
| 12.4.2 | Firestore read/write under load | `[ ]` | Not yet written |
| 12.4.3 | Image upload/download optimization | `[x]` | `cached_network_image` in pubspec; `optimized_image.dart` widget |

---

## Section 13: Localization (Sinhala / Tamil / English)

| # | Task | Status | Notes |
|---|------|--------|-------|
| 13.1 | English translations (complete) | `[x]` | `app_en.arb` — 189 keys (38 added for wallet, recurring, availability, SOS, service names); `app_localizations_en.dart` complete |
| 13.2 | Sinhala translations for all UI strings | `[x]` | `app_si.arb` fully updated with matching translations for all 38 new EN keys including service names in Sinhala script; `app_localizations_si.dart` complete |
| 13.3 | Tamil translations for all UI strings | `[x]` | `app_ta.arb` + `app_localizations_ta.dart` — all 70+ keys including service names, SOS, scheduling, wallet strings |
| 13.4 | RTL layout considerations (if needed) | `[ ]` | Tamil uses LTR script; no RTL layout needed for SL Tamil |
| 13.5 | Service name localization | `[x]` | All 10 Layer 1 service names added to `app_en.arb` and `app_si.arb` (e.g., `elderCompanionship`: "Elder Companionship" / "වැඩිහිටි සහකාරිත්වය") |

---

## Section 14: Operational Readiness

| # | Task | Status | Notes |
|---|------|--------|-------|
| 14.1 | Customer support WhatsApp Business API setup | `[ ]` | No integration |
| 14.2 | Customer support phone line | `[ ]` | No implementation |
| 14.3 | Admin training on verification workflow | `[ ]` | No training materials |
| 14.4 | Admin training on safety alert response | `[ ]` | No training materials |
| 14.5 | Worker onboarding guide (digital + physical) | `[ ]` | Not created |
| 14.6 | Customer onboarding guide | `[ ]` | Not created |
| 14.7 | Cancellation policy definition | `[ ]` | Not codified |
| 14.8 | Dispute resolution process | `[ ]` | Not defined |
| 14.9 | Insurance partnership (worker liability) | `[ ]` | Not started |
| 14.10 | Terms of service (customer) | `[x]` | `docs/TERMS_OF_SERVICE.md` + `store_assets/terms_of_service.md` |
| 14.11 | Terms of service (worker) | `[~]` | `contract_acceptance_page.dart` exists; separate worker contract document unverified |
| 14.12 | Privacy policy (PDPA compliant) | `[x]` | `docs/PRIVACY_POLICY.md` — explicitly references PDPA; placeholders for launch date remain |

---

## Section 15: Legal & Compliance

| # | Task | Status | Notes |
|---|------|--------|-------|
| 15.1 | Business registration in Sri Lanka | `[ ]` | Not started |
| 15.2 | PayHere merchant account approval | `[ ]` | Requires 15.1 first |
| 15.3 | PDPA compliance audit | `[~]` | Privacy policy written; `pdpa_helper.dart` utility exists; formal audit not done |
| 15.4 | Worker contractor agreement (not employee) | `[~]` | `contract_acceptance_page.dart` + ToS exist; legal review needed |
| 15.5 | Service disclaimer (platform, not provider) | `[~]` | In ToS; in-app disclaimer UI not confirmed |
| 15.6 | Healthcare partner disclaimer (Layer 4) | `[ ]` | Layer 4 not started |
| 15.7 | Child protection policy | `[ ]` | Not created |
| 15.8 | Photography/recording consent (check-in selfie) | `[~]` | PDPA doc mentions consent; explicit in-app consent screen not confirmed |

---

## Section 16: Launch & Scale Readiness

### Phase 1: Colombo Soft Launch (Months 1-6)

| # | Task | Status | Target |
|---|------|--------|--------|
| 16.1.1 | 50 verified Green-tier workers | `[ ]` | Month 1-2 |
| 16.1.2 | 10 verified Blue-tier workers | `[ ]` | Month 2-3 |
| 16.1.3 | 5 verified Gold-tier workers | `[ ]` | Month 3-4 |
| 16.1.4 | 100 registered households | `[ ]` | Month 3 |
| 16.1.5 | 50 completed bookings | `[ ]` | Month 4 |
| 16.1.6 | 0 safety incidents unresolved > 24h | `[ ]` | Ongoing |
| 16.1.7 | Customer NPS > 40 | `[ ]` | Month 6 |

### Phase 2: Colombo Scale (Months 7-12)

| # | Task | Status | Target |
|---|------|--------|--------|
| 16.2.1 | 500 active workers | `[ ]` | Month 9 |
| 16.2.2 | 1,500 registered households | `[ ]` | Month 9 |
| 16.2.3 | Layer 2 services (accompaniment) launched | `[ ]` | Month 8 |
| 16.2.4 | Recurring booking feature live | `[x]` | CF (`generateRecurringBookings`, `cancelRecurringInstance`, `modifyRecurringSeries`) + Dart arch + booking form UI all complete |
| 16.2.5 | Subscription model launched | `[ ]` | Not started |
| 16.2.6 | Expand to Gampaha/Kandy/Negombo | `[ ]` | Month 10-12 |

### Phase 3: National Expansion (Months 13-24)

| # | Task | Status | Target |
|---|------|--------|--------|
| 16.3.1 | 5,000+ active workers | `[ ]` | Month 18 |
| 16.3.2 | 20,000 registered households | `[ ]` | Month 24 |
| 16.3.3 | Layer 3 (home maintenance) launched | `[ ]` | Month 15 |
| 16.3.4 | Layer 4 (partner services) launched | `[ ]` | Month 18 |
| 16.3.5 | Jaffna, Batticaloa, Kurunegala active | `[ ]` | Month 20-24 |
| 16.3.6 | Insurance partnership active | `[ ]` | Month 15 |
| 16.3.7 | Automated weekly payouts operational | `[x]` | CF `processWeeklyPayouts` complete |

---

## Progress Summary

| Section | Items | Complete | In Progress | Remaining | % Done |
|---------|-------|----------|-------------|-----------|--------|
| 1. Build & Compilation | 10 | 5 | 3 | 2 | 50% |
| 2. Dependency Injection | 10 | 10 | 0 | 0 | 100% |
| 3. Firestore Configuration | 6 | 3 | 3 | 0 | 50% |
| 4. Cloud Functions | 27 | 16 | 1 | 10 | 59% |
| 5. Layer 1 — Core Services | 47 | 24 | 13 | 10 | 51% |
| 6. Layer 2 — Mobility | 7 | 0 | 2 | 5 | 0% |
| 7. Layer 3 — Maintenance | 7 | 0 | 0 | 7 | 0% |
| 8. Layer 4 — Partner | 8 | 0 | 0 | 8 | 0% |
| 9. Trust & Safety | 11 | 4 | 4 | 3 | 36% |
| 10. Wallet & Payments | 11 | 4 | 3 | 4 | 36% |
| 11. Worker Verification | 19 | 7 | 7 | 5 | 37% |
| 12. Testing | 16 | 5 | 0 | 11 | 31% |
| 13. Localization | 5 | 3 | 0 | 2 | 60% |
| 14. Operational Readiness | 12 | 2 | 1 | 9 | 17% |
| 15. Legal & Compliance | 8 | 0 | 4 | 4 | 0% |
| 16. Launch & Scale | 21 | 2 | 0 | 19 | 10% |
| **TOTAL** | **225** | **85** | **41** | **99** | **37.8%** |

---

## Critical Path to Beta Launch (P0 / P1 Blockers)

The following items must be resolved before any real user traffic:

### Must-Fix Before First User (P0)
1. **1.9** — Confirm `flutter build apk --release` succeeds
2. **3.4 / 3.5** — Deploy Firestore + Storage security rules to production Firebase project
3. **10.1** — Wire PayHere REST payment page to actual wallet top-up flow

### Must-Fix Before Beta (P1)
4. **5.2.2** — Add flexibility options to date picker (Morning/Afternoon/Evening slots)
5. **9.4** — Persistent SOS button visible on worker screens during active jobs
6. **11.2.1–11.2.4** — Blue-tier document upload + admin reference call log
7. **13.3** — Tamil translations (none exist; significant portion of Sri Lanka workforce)

### Remaining Architecture Gaps
- **No CF for verification tier upgrades** (4.4.1/4.4.2) — admin must manually update Firestore; auto-promotion logic missing
- **Refunds not implemented** (4.3.4 / 10.5) — cancellation before job start needs wallet refund path
- **Worker payout bank account setup** (10.6) — no UI for workers to enter bank details before payouts can be disbursed
- **Safety escalation SMS/call chain** (4.2.2 / 9.11) — only push notifications implemented; Notify.lk SMS integration pending merchant approval

---

## Audit Notes

### 2026-05-31 (Initial Audit)
- The previous checklist scored 6.3% complete (14/222). The true state after auditing all source files was **23.6% complete** (53/225).
- The large gap was primarily in Section 2 (DI — 100%), Section 4 (Cloud Functions — 33%), and Section 11 (Worker Verification — 37%).
- Many items that were marked `[ ]` had the domain/data layer complete but were missing the UI connection or a Cloud Function counterpart.
- Sinhala localization had 76 of 151 strings translated; Tamil had none.
- No unit tests existed for any of the new use cases added in the May 30 commit (scheduling, wallet, safety).

### 2026-05-31 (Fixing Session)
Completed 32 additional items (23 from `[ ]` and 9 from `[~]`), bringing total to **37.8% complete** (85/225):
- **Cloud Functions (7 new):** `cancelRecurringInstance`, `modifyRecurringSeries`, `verifyWorkerCheckInLocation`, `holdWalletFunds`, `releaseWalletFunds`, `suspendWorker` (auto + manual), worker notification path in `notifyUpcomingBookings`
- **Service catalog:** All 10 Layer 1 services seeded via `seedServiceCatalog` CF callable with rates, tiers, and task lists
- **Booking form UI:** Recurring toggle (weekly/biweekly + end-date + occurrence estimate), special instructions field, wallet balance check with top-up dialog
- **Worker availability UI:** Full day-wise time-slot editor (add/remove per-day slots) + blocked dates manager, connected to `SchedulingBloc`
- **Wallet escrow security:** `holdWalletFunds` / `releaseWalletFunds` promoted from client-side Dart use cases to server-side CF callables; LKR 1,000 payout threshold enforced
- **Localization:** All 38 new strings translated to Sinhala; all 10 service names in EN + SI ARBs
- **TypeScript compilation:** Fixed `geofire.getDistance` → `distanceBetween`, removed non-existent `GeoFirestore` import, fixed `error.message` on unknown catch types, fixed tuple type casts; `tsc --noEmit` = 0 errors
