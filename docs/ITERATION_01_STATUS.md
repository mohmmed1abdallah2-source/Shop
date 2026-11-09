# Iteration 01 — Execution Status

**Branch:** `feature/iteration-1-fullstack-erp`  
**Pull request:** [#1 — Iteration 1 foundation](https://github.com/mohmmed1abdallah2-source/Shop/pull/1)  
**Main branch:** contains repository bootstrap and PR CI workflow only; application work remains isolated on the feature branch.

## Implemented in source
- Repository bootstrap and isolated feature branch.
- Layered architecture diagrams, PostgreSQL ERD, client/server sequence and hosting plan.
- OpenAPI v1 contract for health, app config, session, product CRUD foundation, barcode/scale lookup and standard envelopes.
- Shared DTOs for API response/error metadata, products, units, sessions and app config.
- HTTP client with bearer token, request correlation, idempotency key propagation and bounded transient retries.
- PostgreSQL migration for branches, roles, permissions, users, devices, idempotency, audit logs, categories, products and unit barcodes.
- Catalog domain port, validation use cases, in-memory adapter and PostgreSQL transactional adapter.
- Idempotency key reservation under transaction lock; repeated identical payload replays stored response; a different payload returns conflict.
- Firebase email/password REST sign-in and refresh-token exchange; refresh token stored using platform secure storage.
- Server Firebase ID-token verification using Google Secure Token certificates, RS256, project issuer/audience and time claims; verifier fails closed.
- Session exchange maps verified Firebase UID to provisioned user, branch, role and permissions in PostgreSQL.
- Flutter RTL dark theme, responsive shell, mobile expandable cards, desktop data table, keyboard-safe form sheet and approved balance vocabulary.
- Local-first product save, SQLite storage on Android/Windows, browser local storage, durable pending queue, idempotent retry after session restoration and cached catalog snapshots.
- Multiple selling units (piece/pack/carton/sack), retail/wholesale price fields and variable-measure EAN-13 scale barcode parser.
- CI workflows for Dart analysis/tests and Android APK, Web and Windows release builds; platform runner scaffolding is generated in CI.

## Evidence currently available
- GitHub confirms feature branch and PR #1 exist; PR is open and not merged.
- Source files and workflow definitions are present in the branch.
- Automated server and Flutter tests have been authored.
- No successful Actions run, APK, Web bundle, Windows executable, PostgreSQL migration run or Firebase emulator result has yet been retrieved. None of these are marked passed.

## Required deployment configuration
- Server: `DATABASE_URL`, `FIREBASE_PROJECT_ID`, `PORT`.
- Flutter build: `FIREBASE_API_KEY` and `API_BASE_URL` via `--dart-define`.
- PostgreSQL: apply `server/migrations/20261108_001_init_auth_and_catalog.sql`, then provision at least one branch, role, role permissions and user row with the Firebase UID.
- Firebase: enable Email/Password sign-in and use the same project ID/API key as the server/client configuration.

## Remaining acceptance work
1. Obtain a real CI run and fix every analyzer, test and platform build failure until all required jobs pass.
2. Apply migration to a clean PostgreSQL instance and run the transactional idempotency and branch-isolation integration tests against it.
3. Configure a Firebase project and verify sign-in, token refresh, revoked/expired tokens and server session exchange against Firebase Emulator or a test project.
4. Run two clients against the same server: product create, network interruption, same-key retry, duplicate-key/different-body conflict, and queue replay after restart.
5. Download and inspect APK, Web and Windows artifacts; confirm startup and login on target platforms.
6. Update this document and `CHANGELOG.md` with actual run IDs, test counts, artifact links and any residual limitations.
7. Keep PR #1 open for review; do not merge to `main` without explicit approval.
