# Decisions against Hela Service App / SEVANA Home Specification v1.0

Tracks resolutions to the open-decisions register (§20) in
`Hela_Service_App_Full_System_Specification_v1.0.docx`, plus any other
material scope calls made against that spec. New entries only — never edit a
resolved decision's rationale in place; if a decision is revisited, add a new
entry that supersedes it and says so.

## OD-015 — Repository technology direction

**Decision:** Retain and extend the existing Flutter + Firebase
(Firestore/Auth/Storage/Functions) architecture. Do not migrate to the
spec's reference stack (NestJS modular monolith, PostgreSQL/PostGIS, Redis,
React Native, Next.js admin).

**Rationale:** The current app is a working, feature-rich product with a
real customer/worker/admin surface already built and, as of this decision,
a materially hardened booking/payout/wallet/Firestore-rules layer. A full
rebuild on the spec's target stack would take months and effectively
produce a second product. The spec's own architecture section explicitly
frames its stack as "a recommended target, not a claim about the current
GitHub repository" and defers the real choice to this decision (OD-015).

**Consequence:** Sections 10–12 of the spec (system architecture, data
model/governance, API/events/integration contract) are treated as
aspirational reference material, not binding requirements. Functional and
governance requirements from the rest of the spec (roles, verification,
booking lifecycle, safety, accessibility, etc.) remain in scope and are
pursued within the Flutter/Firebase architecture.

**Date:** 2026-08-30

## OD-013 — Payment and wallet scope

**Decision:** Keep in-app payments and the wallet system. Do not gate them
off to match the spec's launch exclusion.

**Rationale:** Spec §2.2 lists "in-app card, wallet, bank-transfer
processing, provider payouts or stored payment credentials" as a
non-negotiable exclusion from launch. The app already has a real PayHere
integration, a wallet ledger, and an 80/20 provider payout system — not
placeholder code. Session work immediately preceding this decision fixed a
production-blocking payout query bug and migrated the wallet ledger to a
canonical, integer-cents-safe schema across four Cloud Functions and the
Dart client specifically because this system is intended to keep running.

**Consequence:** This is a deliberate, recorded deviation from the spec's
§2.2 exclusion list, not an oversight. If the spec is later treated as
binding for a compliance, legal or investor purpose, this line item needs
explicit sign-off alongside it rather than silent removal.

**Date:** 2026-08-30
