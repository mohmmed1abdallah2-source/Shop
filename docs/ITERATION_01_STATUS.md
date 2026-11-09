# Iteration 01 — Execution Status

**Branch:** `feature/iteration-1-fullstack-erp`  
**Pull request:** #1 — open for review; not merged.  
**Main branch:** repository bootstrap and CI workflow only. Application implementation remains isolated on the feature branch.

## Implemented in source
- Layered architecture diagrams, PostgreSQL ERD, client/server sequence and deployment/hosting guide.
- OpenAPI v1 schemas and paths for health, app config, Firebase session exchange, branch-scoped product list/save and barcode/scale lookup.
- Shared Dart DTOs for API response/error metadata, products, units, sessions and app config.
- HTTP client with Firebase bearer token, request correlation, branch header, idempotency key and bounded retries.
- PostgreSQL migrations for branches, roles, role permissions, users, devices, idempotency keys, audit logs, categories, products and multiple unit barcodes; default owner/manager/viewer catalog permissions are seeded.
- Catalog domain ports, validation use cases, in-memory adapter and transactional PostgreSQL adapter.
- Idempotency reservation is serialized by a transaction lock; same-key/same-payload replays the stored response; same-key/different-payload conflicts.
- Branch isolation and `catalog.read` / `catalog.write` permission checks on every catalog route.
- Firebase email/password REST sign-in and refresh; refresh token stored through platform secure storage.
- Server Firebase ID-token verification against Google's rotating Secure Token certificates, RS256 signature, issuer/audience and time claims; fails closed if verification is unavailable.
- Session exchange maps Firebase UID to active branch, role and permissions in PostgreSQL.
- Flutter RTL enterprise dark theme, responsive shell, mobile expandable cards, desktop data table, keyboard-safe form sheet and approved balance vocabulary.
- Product entry supports piece/pack/carton/sack, multiple barcodes and retail/wholesale prices, weighted PLU and a checked variable-measure EAN-13 parser.
- Local-first product save; SQLite on Android/Windows; browser local storage on Web; cached catalog snapshots; pending queue replay with the original idempotency key; secure offline session cache limited to seven days.
- Per-product sync status (pending/synchronized) in the product list.
- CI workflows for Dart tests and Android APK, Web and Windows release builds; generated platform runners are created during CI.
- Tests authored for catalog validation/idempotency, HTTP auth/envelopes/permissions, API headers/retries, EAN-13 parsing and balance vocabulary.

## Evidence currently available
- GitHub confirms the feature branch and PR #1 exist; PR is open and not merged.
- All implementation and test files listed above are present in the PR diff.
- GitHub Actions lookup returned no workflow runs for the current head commit. No test or build is marked passed.
- No APK, Web bundle or Windows executable has been retrieved.
- PostgreSQL migrations have not been applied to a live database; Firebase sign-in and token verification have not been exercised against an actual project or emulator.

## Required deployment configuration
- Server: `DATABASE_URL`, `FIREBASE_PROJECT_ID`, `CORS_ALLOWED_ORIGINS`, optional `PORT`.
- Flutter build: `FIREBASE_API_KEY` and `API_BASE_URL` via `--dart-define`.
- PostgreSQL: apply `20261108_001_init_auth_and_catalog.sql`, then `20261108_002_seed_catalog_permissions.sql`; provision a branch and a user row with the Firebase UID and the `owner` role.
- Firebase: enable Email/Password sign-in and use the same project ID/API key for the server/client.

## Remaining acceptance work
1. Obtain actual GitHub Actions runs and fix every Dart analyzer, test and platform build failure until all required jobs pass.
2. Apply both migrations to a clean PostgreSQL instance and run transactional idempotency, duplicate barcode and branch-isolation integration tests against it.
3. Configure a Firebase project and verify sign-in, refresh, expired/disabled accounts and session exchange against Firebase Emulator or a dedicated test project.
4. Run two clients against the same server: product creation, network interruption, same-key replay, same-key/different-payload conflict, and queue replay after process restart.
5. Download and inspect Android APK, Web bundle and Windows executable; confirm app startup, login, product entry and synchronization on target platforms.
6. Record actual workflow run IDs, test counts, artifact links, migration evidence and residual limitations here and in `CHANGELOG.md`.
7. Keep PR #1 open for review; do not merge to `main` without explicit approval.
