# Changelog

## Unreleased — Iteration 1 foundation
- Bootstrapped the empty repository and created `feature/iteration-1-fullstack-erp`.
- Added architecture diagrams, OpenAPI v1 contract, deployment guide and delivery status documentation.
- Added shared API contracts and an authenticated HTTP client with request IDs, idempotency, retries and ETag/304 handling.
- Added PostgreSQL auth/catalog schema, seeded roles, branch-scoped permissions, catalog validation and transactional idempotent persistence.
- Added duplicate barcode and scale PLU protection, branch-isolated listing and barcode/PLU lookup.
- Added Firebase REST sign-in/refresh, secure refresh-token storage, seven-day encrypted offline session cache and server-side Google Secure Token verification.
- Added Flutter RTL enterprise theme, responsive mobile cards/desktop table, F5 sync shortcut, multi-unit product entry, weighted EAN-13 parser and per-product sync status.
- Added SQLite local storage for Android/Windows with SQLite 3 native assets and persistent Windows app-data path; browser local storage for Web; durable pending queue replay and local catalog snapshots.
- Added CI workflows for Dart analysis/tests and Android/Web/Windows release builds.
- Automated test source has been added; execution and build success are not yet confirmed. See `ITERATION_01_STATUS.md` for evidence and remaining acceptance work.
