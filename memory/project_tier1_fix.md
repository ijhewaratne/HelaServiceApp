---
name: project-tier1-fix
description: Tier 1 compilation fix — reduced 333 lib errors to 0 compile errors
metadata:
  type: project
---

Completed Tier 1 fix as of 2026-05-26. App went from 333 compile errors → 0 errors.

**Why:** App would not build at all before this work.

**How to apply:** Tier 2 (mock dispatch engine, stub repos) and Tier 3 (UI/UX polish, test coverage) are still TODO.

## What was fixed (key patterns):
1. `fromJson` factory methods lacked explicit casts — added `as String? ?? ''`, `(as num?)?.toDouble()`, `as bool? ?? false` across ~15 entity files
2. BLoC state classes used `Map<String, dynamic>` for typed entities — fixed `booking_bloc`, `customer_bloc`
3. Wrong repository interface method names — `worker_viewmodel` used non-existent methods; added legacy stubs to `WorkerRepository`
4. Firebase `User?` vs custom `User?` in `authStateChanges` stream — fixed repo to emit custom User entity
5. Flutter SDK API renames: `CardTheme→CardThemeData`, `DialogTheme→DialogThemeData`
6. `WidgetsFlutterBinding.ensureInitialization()` → `ensureInitialized()` in main_staging.dart
7. Missing `PromoRepositoryImpl` and `ReferralRepositoryImpl` — created stub files
8. `LoadingIndicatorType` → `Indicator` (package enum rename)
9. `NotFoundGenericFailure` → `NotFoundFailure` in feedback_repository_impl
10. `BlocObserver.onEvent` signature: `BlocBase<dynamic>` → `Bloc<dynamic, dynamic>`

## Remaining issues (not compilation blockers):
- 445 warnings/info lints (deprecated APIs, unused imports, style hints)
- Dispatch engine is entirely mocked (Tier 2)
- PayHere payment integration stubbed (Tier 2)
- Promo/Referral repositories stubbed (Tier 2)
