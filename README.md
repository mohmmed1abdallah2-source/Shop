# Shop — Supermarket ERP

Monorepo لنظام إدارة متجر وسوبرماركت متعدد الفروع، بواجهة Flutter وخادم Dart وقاعدة PostgreSQL.

## Iteration 1
- Layered Dart Shelf API with PostgreSQL catalog persistence and Firebase ID-token verification.
- Shared API contracts and HTTP client with request IDs, bearer authentication, idempotency and ETag support.
- Flutter RTL responsive client for Android, Windows and Web.
- Local-first product catalog, multiple selling units, weighted PLU/EAN-13 parsing and durable sync queue.

## Repository map
- `app/` — Flutter client.
- `server/` — Dart HTTP API and PostgreSQL migrations.
- `packages/core_contracts/` — shared API DTOs.
- `packages/api_client/` — authenticated HTTP client.
- `docs/ITERATION_01_ARCHITECTURE_AND_DIAGRAMS.md` — architecture and diagrams.
- `docs/openapi_v1.yaml` — OpenAPI v1 contract.
- `docs/ITERATION_01_DEPLOYMENT.md` — setup, environment and hosting.
- `docs/ITERATION_01_STATUS.md` — verified state and outstanding acceptance work.

## Build requirements
Flutter stable / Dart 3.12+, PostgreSQL and a Firebase project with Email/Password authentication enabled. Follow `docs/ITERATION_01_DEPLOYMENT.md` before running the client or server.

Development branch: `feature/iteration-1-fullstack-erp`. PR #1 is open for review; implementation changes are not merged into `main` without explicit approval.
